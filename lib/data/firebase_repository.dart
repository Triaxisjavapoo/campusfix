import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../domain/incident_policy.dart';
import '../domain/models.dart';
import 'campusfix_exception.dart';
import 'evidence_config.dart';
import 'supabase_evidence_client.dart';
export 'campusfix_exception.dart';

/// Production Firebase access. No fake database, hardcoded accounts, or public
/// download URLs: emulator and production use the same authenticated operations.
class FirebaseRepository {
  FirebaseRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : auth = auth ?? FirebaseAuth.instance,
       firestore = firestore ?? FirebaseFirestore.instance,
       storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  late final _supabaseEvidence = SupabaseEvidenceClient(auth);
  static const maxEvidenceBytes = 5 * 1024 * 1024;
  static const allowedEvidenceTypes = {'image/jpeg', 'image/png', 'image/webp'};
  final _uuid = const Uuid();

  Map<String, dynamic> _map(Map<String, dynamic> map) => map.map(
    (key, value) => MapEntry(key, value is Timestamp ? value.toDate() : value),
  );

  Stream<UserProfile?> watchProfile(String uid) => firestore
      .collection('users')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      // A local registration write is visible before Security Rules can read
      // that profile. Wait for server confirmation before opening its session.
      .where(
        (doc) => !doc.metadata.hasPendingWrites && !doc.metadata.isFromCache,
      )
      .map(
        (doc) =>
            doc.exists ? UserProfile.fromMap(doc.id, _map(doc.data()!)) : null,
      );

  Future<UserProfile> _actor() async {
    final user = auth.currentUser;
    if (user == null) {
      throw const CampusFixException('Inicia sesión para continuar.');
    }
    final doc = await firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      throw const CampusFixException(
        'Tu perfil todavía no está disponible. Contacta al administrador.',
      );
    }
    final profile = UserProfile.fromMap(doc.id, _map(doc.data()!));
    if (!profile.active) {
      throw const CampusFixException(
        'Tu cuenta está desactivada. Contacta al administrador.',
      );
    }
    return profile;
  }

  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      await _actor();
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    _length(name, 'El nombre', 2, 100);
    if (password.length < 8) {
      throw const CampusFixException(
        'La contraseña debe tener al menos 8 caracteres.',
      );
    }
    final result = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user!;
    try {
      await firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': user.email!,
        'role': UserRole.reporter.value,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Avoid leaving a permanently incomplete account when registration fails.
      try {
        await user.delete();
      } catch (_) {
        await auth.signOut();
      }
      rethrow;
    }
  }

  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
  Future<void> sendVerificationEmail() async {
    final user = auth.currentUser;
    if (user == null) {
      throw const CampusFixException('Inicia sesión para continuar.');
    }
    if (!user.emailVerified) await user.sendEmailVerification();
  }

  Future<void> reloadUser() async => auth.currentUser?.reload();
  Future<void> logout() => auth.signOut();

  Future<void> updateProfile(String name) async {
    _length(name, 'El nombre', 2, 100);
    final actor = await _actor();
    await firestore.collection('users').doc(actor.uid).update({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Category>> watchCategories() => firestore
      .collection('categories')
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Category.fromMap(doc.id, _map(doc.data())))
            .toList(growable: false),
      );

  Stream<List<UserProfile>> watchUsers() => firestore
      .collection('users')
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.id, _map(doc.data())))
            .toList(growable: false),
      );

  Stream<List<Incident>> watchIncidents(UserProfile actor) {
    Query<Map<String, dynamic>> query = firestore.collection('incidents');
    if (actor.role == UserRole.reporter) {
      query = query.where('reporterId', isEqualTo: actor.uid);
    }
    if (actor.role == UserRole.technician) {
      query = query.where('assignedTo', isEqualTo: actor.uid);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Incident.fromMap(doc.id, _map(doc.data())))
              .toList(growable: false),
        );
  }

  Stream<List<IncidentEvent>> watchEvents(String incidentId) => firestore
      .collection('incidents')
      .doc(incidentId)
      .collection('events')
      .orderBy('version', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => IncidentEvent.fromMap(doc.id, _map(doc.data())))
            .toList(growable: false),
      );

  Stream<List<IncidentComment>> watchComments(String incidentId) => firestore
      .collection('incidents')
      .doc(incidentId)
      .collection('comments')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => IncidentComment.fromMap(doc.id, _map(doc.data())))
            .toList(growable: false),
      );

  Stream<List<IncidentEvidence>> watchEvidence(String incidentId) => firestore
      .collection('incidents')
      .doc(incidentId)
      .collection('evidence')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => IncidentEvidence.fromMap(doc.id, _map(doc.data())))
            .toList(growable: false),
      );

  Future<String> createIncident({
    required String title,
    required String description,
    required String categoryId,
    required String location,
    required IncidentPriority priority,
  }) async {
    _length(title, 'El título', 5, 160);
    _length(description, 'La descripción', 10, 5000);
    _length(location, 'La ubicación', 3, 300);
    final actor = await _actor();
    final incidentRef = firestore.collection('incidents').doc();
    final eventRef = incidentRef.collection('events').doc();
    await firestore.runTransaction((transaction) async {
      final categoryDoc = await transaction.get(
        firestore.collection('categories').doc(categoryId),
      );
      if (!categoryDoc.exists || categoryDoc.data()!['active'] != true) {
        throw const CampusFixException('Selecciona una categoría activa.');
      }
      final data = <String, dynamic>{
        'number':
            'CF-${DateTime.now().year}-${incidentRef.id.substring(0, 8).toUpperCase()}',
        'title': title.trim(),
        'description': description.trim(),
        'categoryId': categoryId,
        'categoryName': categoryDoc.data()!['name'],
        'location': location.trim(),
        'priority': priority.value,
        'status': IncidentStatus.reported.value,
        'reporterId': actor.uid,
        'reporterName': actor.name,
        'assignedTo': null,
        'assignedName': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'closedAt': null,
        'version': 1,
        'lastEventId': eventRef.id,
      };
      transaction.set(incidentRef, data);
      transaction.set(
        eventRef,
        _event(
          actor,
          'CREATED',
          null,
          IncidentStatus.reported,
          'Incidencia registrada.',
          1,
        ),
      );
    });
    return incidentRef.id;
  }

  Future<void> classifyIncident(
    Incident incident, {
    required String categoryId,
    required IncidentPriority priority,
    required String note,
  }) async {
    final actor = await _actor();
    await _changeIncident(incident, actor, 'CLASSIFIED', note, (
      transaction,
      current,
    ) async {
      if (!IncidentPolicy.canClassify(current, actor)) {
        throw const CampusFixException('No puedes clasificar esta incidencia.');
      }
      final categoryDoc = await transaction.get(
        firestore.collection('categories').doc(categoryId),
      );
      if (!categoryDoc.exists || categoryDoc.data()!['active'] != true) {
        throw const CampusFixException('Selecciona una categoría activa.');
      }
      if (categoryId == current.categoryId &&
          priority == current.priority &&
          categoryDoc.data()!['name'] == current.categoryName) {
        throw const CampusFixException('La clasificación no tiene cambios.');
      }
      return {
        'categoryId': categoryId,
        'categoryName': categoryDoc.data()!['name'],
        'priority': priority.value,
      };
    });
  }

  Future<void> assignIncident(
    Incident incident,
    UserProfile technician, {
    required String note,
  }) async {
    final actor = await _actor();
    await _changeIncident(incident, actor, 'ASSIGNED', note, (
      transaction,
      current,
    ) async {
      if (!IncidentPolicy.canAssign(current, actor)) {
        throw const CampusFixException(
          'No puedes asignar esta incidencia en su estado actual.',
        );
      }
      final techDoc = await transaction.get(
        firestore.collection('users').doc(technician.uid),
      );
      if (!techDoc.exists ||
          techDoc.data()!['active'] != true ||
          techDoc.data()!['role'] != UserRole.technician.value) {
        throw const CampusFixException(
          'El responsable debe ser un técnico activo.',
        );
      }
      return {
        'assignedTo': technician.uid,
        'assignedName': techDoc.data()!['name'],
        'status': IncidentStatus.assigned.value,
      };
    });
  }

  Future<void> transitionIncident(
    Incident incident,
    IncidentStatus next, {
    required String note,
  }) async {
    final actor = await _actor();
    await _changeIncident(incident, actor, 'STATUS_CHANGED', note, (
      transaction,
      current,
    ) async {
      if (!IncidentPolicy.allowedTransitions(current, actor).contains(next)) {
        throw const CampusFixException(
          'Ese cambio de estado no está permitido para tu rol.',
        );
      }
      return {
        'status': next.value,
        if (next == IncidentStatus.resolved)
          'resolvedAt': FieldValue.serverTimestamp(),
        if (next == IncidentStatus.closed)
          'closedAt': FieldValue.serverTimestamp(),
        if (next == IncidentStatus.reopened) ...{
          'resolvedAt': null,
          'closedAt': null,
          'assignedTo': null,
          'assignedName': null,
        },
      };
    });
  }

  Future<void> _changeIncident(
    Incident expected,
    UserProfile actor,
    String type,
    String note,
    Future<Map<String, dynamic>> Function(Transaction, Incident) changes,
  ) async {
    _length(note, 'La justificación', 3, 2000);
    final ref = firestore.collection('incidents').doc(expected.id);
    final eventRef = ref.collection('events').doc();
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw const CampusFixException('La incidencia ya no está disponible.');
      }
      final current = Incident.fromMap(snapshot.id, _map(snapshot.data()!));
      if (current.version != expected.version) {
        throw const CampusFixException(
          'La incidencia cambió mientras la editabas. Revisa los datos actuales e inténtalo de nuevo.',
        );
      }
      final update = await changes(transaction, current);
      final next = update['status'] == null
          ? current.status
          : IncidentStatus.parse(update['status']);
      final version = current.version + 1;
      transaction.update(ref, {
        ...update,
        'updatedAt': FieldValue.serverTimestamp(),
        'version': version,
        'lastEventId': eventRef.id,
      });
      transaction.set(
        eventRef,
        _event(actor, type, current.status, next, note.trim(), version),
      );
    });
  }

  Map<String, dynamic> _event(
    UserProfile actor,
    String type,
    IncidentStatus? from,
    IncidentStatus to,
    String message,
    int version,
  ) => {
    'actorId': actor.uid,
    'actorName': actor.name,
    'type': type,
    'fromStatus': from?.value,
    'toStatus': to.value,
    'message': message,
    'createdAt': FieldValue.serverTimestamp(),
    'version': version,
  };

  Future<void> addComment(Incident incident, String text) async {
    _length(text, 'El comentario', 1, 2000);
    final actor = await _actor();
    if (!IncidentPolicy.canComment(incident, actor)) {
      throw const CampusFixException('No tienes acceso a esta incidencia.');
    }
    await firestore
        .collection('incidents')
        .doc(incident.id)
        .collection('comments')
        .add({
          'authorId': actor.uid,
          'authorName': actor.name,
          'text': text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> uploadEvidence(
    Incident incident, {
    required String name,
    required Uint8List bytes,
    required String contentType,
  }) async {
    _length(name, 'El nombre de archivo', 1, 180);
    if (!EvidenceConfig.enabled) {
      throw const CampusFixException(
        'La carga de fotografías no está habilitada.',
      );
    }
    if (bytes.isEmpty || bytes.length > maxEvidenceBytes) {
      throw const CampusFixException(
        'Cada imagen debe pesar entre 1 byte y 5 MB.',
      );
    }
    if (!allowedEvidenceTypes.contains(contentType) ||
        !_validImageSignature(bytes, contentType)) {
      throw const CampusFixException(
        'Adjunta una imagen JPEG, PNG o WebP válida.',
      );
    }
    final actor = await _actor();
    if (!IncidentPolicy.canComment(incident, actor)) {
      throw const CampusFixException('No tienes acceso a esta incidencia.');
    }
    if (EvidenceConfig.provider == 'supabase') {
      await _supabaseEvidence.upload(
        incidentId: incident.id,
        name: name.trim(),
        bytes: bytes,
        contentType: contentType,
      );
      return;
    }
    final id = _uuid.v4();
    final path = 'incidents/${incident.id}/${actor.uid}/$id';
    final ref = storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    try {
      await firestore
          .collection('incidents')
          .doc(incident.id)
          .collection('evidence')
          .doc(id)
          .set({
            'uploaderId': actor.uid,
            'uploaderName': actor.name,
            'name': name.trim(),
            'path': path,
            'contentType': contentType,
            'size': bytes.length,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      // Best-effort compensation if the metadata write failed after upload.
      try {
        await ref.delete();
      } catch (_) {
        /* Retry through administrative cleanup if offline. */
      }
      rethrow;
    }
  }

  bool _validImageSignature(Uint8List data, String type) {
    if (type == 'image/jpeg') {
      return data.length >= 3 &&
          data[0] == 0xff &&
          data[1] == 0xd8 &&
          data[2] == 0xff;
    }
    if (type == 'image/png') {
      return data.length >= 8 &&
          [
            0x89,
            0x50,
            0x4e,
            0x47,
            0x0d,
            0x0a,
            0x1a,
            0x0a,
          ].asMap().entries.every((entry) => data[entry.key] == entry.value);
    }
    if (type == 'image/webp') {
      return data.length >= 12 &&
          String.fromCharCodes(data.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(data.sublist(8, 12)) == 'WEBP';
    }
    return false;
  }

  Future<Uint8List?> evidenceBytes(IncidentEvidence evidence) =>
      evidence.storageProvider == 'supabase'
      ? _supabaseEvidence.download(evidence)
      : storage.ref(evidence.path).getData(maxEvidenceBytes);

  Future<void> saveCategory({
    String? id,
    required String name,
    required String description,
    bool active = true,
  }) async {
    _length(name, 'El nombre de categoría', 2, 80);
    if (description.trim().length > 500) {
      throw const CampusFixException(
        'La descripción admite hasta 500 caracteres.',
      );
    }
    await _requireAdmin();
    final ref = id == null
        ? firestore.collection('categories').doc()
        : firestore.collection('categories').doc(id);
    if (id == null) {
      await ref.set({
        'name': name.trim(),
        'description': description.trim(),
        'active': active,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({
        'name': name.trim(),
        'description': description.trim(),
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> setCategoryActive(Category category, bool active) async {
    await _requireAdmin();
    await firestore.collection('categories').doc(category.id).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserRole(UserProfile user, UserRole role) async {
    final actor = await _requireAdmin();
    if (user.uid == actor.uid) {
      throw const CampusFixException('Otro administrador debe cambiar tu rol.');
    }
    await firestore.collection('users').doc(user.uid).update({
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setUserActive(UserProfile user, bool active) async {
    final actor = await _requireAdmin();
    if (user.uid == actor.uid) {
      throw const CampusFixException('No puedes desactivar tu propia cuenta.');
    }
    await firestore.collection('users').doc(user.uid).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserProfile> _requireAdmin() async {
    final actor = await _actor();
    if (actor.role != UserRole.admin) {
      throw const CampusFixException(
        'Esta acción requiere permisos de administrador.',
      );
    }
    return actor;
  }

  static void _length(String value, String field, int min, int max) {
    if (value.trim().length < min || value.trim().length > max) {
      throw CampusFixException(
        '$field debe tener entre $min y $max caracteres.',
      );
    }
  }
}

String friendlyError(Object error) {
  if (error is CampusFixException) return error.message;
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Revisa el formato del correo electrónico.',
      'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
      'weak-password' => 'Usa una contraseña de al menos 8 caracteres.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Correo o contraseña incorrectos.',
      'too-many-requests' =>
        'Se hicieron demasiados intentos. Espera un momento y vuelve a intentar.',
      'network-request-failed' =>
        'No se pudo conectar. Revisa tu conexión a internet.',
      'user-disabled' =>
        'Esta cuenta fue desactivada. Contacta al administrador.',
      'operation-not-allowed' =>
        'Activa el acceso por correo y contraseña en Firebase Authentication.',
      _ => 'No se pudo completar el acceso. Inténtalo de nuevo.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' || 'unauthorized' =>
        'No tienes permiso para esta operación. Revisa tu rol o contacta al administrador.',
      'unavailable' || 'retry-limit-exceeded' =>
        'El servicio no está disponible. Revisa tu conexión y vuelve a intentar.',
      'failed-precondition' =>
        'Falta un índice o una configuración de Firebase. Contacta al administrador.',
      'object-not-found' => 'El archivo ya no está disponible.',
      'quota-exceeded' || 'resource-exhausted' =>
        'Se alcanzó el límite del servicio. Contacta al administrador.',
      _ => 'No se pudo guardar la operación. Inténtalo de nuevo.',
    };
  }
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
