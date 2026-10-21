import 'dart:async';

import 'package:campusfix/data/firebase_repository.dart';
import 'package:campusfix/domain/models.dart';
import 'package:campusfix/state/auth_state.dart';
import 'package:campusfix/state/incident_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

const _reporter = UserProfile(
  uid: 'reporter',
  name: 'María Reportante',
  email: 'reporter@example.test',
  role: UserRole.reporter,
);
const _technician = UserProfile(
  uid: 'technician',
  name: 'Carlos Técnico',
  email: 'technician@example.test',
  role: UserRole.technician,
);
const _admin = UserProfile(
  uid: 'admin',
  name: 'Ana Administradora',
  email: 'admin@example.test',
  role: UserRole.admin,
);
const _incident = Incident(
  id: 'incident-private',
  number: 'CF-2026-TEST0001',
  title: 'Una incidencia privada',
  description: 'Información de la sesión anterior.',
  categoryId: 'electricidad',
  categoryName: 'Electricidad',
  location: 'Edificio A, aula 202',
  priority: IncidentPriority.medium,
  status: IncidentStatus.reported,
  reporterId: 'admin',
  reporterName: 'Ana Administradora',
);

void main() {
  late _SessionHarness session;

  setUp(() {
    session = _SessionHarness();
  });
  tearDown(() async {
    await session.dispose();
  });

  test(
    'registro espera la confirmación antes de abrir las consultas privadas',
    () async {
      final pending = Completer<void>();
      session.repository.registerResult = pending.future;
      final registering = session.auth.register(
        _reporter.name,
        _reporter.email,
        'a-private-test-password',
      );

      // Auth notifica el usuario antes de que termine la escritura del perfil.
      // Una instantánea optimista no debe abrir consultas protegidas todavía.
      session.establish(_reporter);
      expect(session.auth.isLoading, isTrue);
      expect(session.auth.isAuthenticated, isFalse);
      expect(session.repository.incidentWatches, isEmpty);
      expect(session.repository.categoryWatches, isEmpty);
      expect(session.repository.userWatches, isEmpty);

      pending.complete();
      expect(await registering, isTrue);
      expect(session.auth.isAuthenticated, isTrue);
      expect(session.repository.incidentWatches, hasLength(1));
      expect(
        session.repository.incidentWatches.single.actor.uid,
        _reporter.uid,
      );
      expect(session.repository.categoryWatches, hasLength(1));
      expect(session.repository.userWatches, isEmpty);
      session.deliverEmptyWorkspace();
      expect(session.incidents.isLoading, isFalse);
      expect(session.incidents.error, isNull);
    },
  );

  test(
    'login espera validar el perfil antes de abrir las consultas privadas',
    () async {
      final pending = Completer<void>();
      session.repository.loginResult = pending.future;
      final loggingIn = session.auth.login(
        _reporter.email,
        'a-private-test-password',
      );

      session.establish(_reporter);
      expect(session.auth.isLoading, isTrue);
      expect(session.auth.isAuthenticated, isFalse);
      expect(session.repository.incidentWatches, isEmpty);
      expect(session.repository.categoryWatches, isEmpty);

      pending.complete();
      expect(await loggingIn, isTrue);
      expect(session.auth.isAuthenticated, isTrue);
      expect(session.repository.incidentWatches, hasLength(1));
      expect(session.repository.userWatches, isEmpty);
      session.deliverEmptyWorkspace();
      expect(session.incidents.error, isNull);
    },
  );

  for (final profile in [_reporter, _technician, _admin]) {
    test(
      'una sesión ${profile.role.value} usa únicamente sus suscripciones',
      () {
        session.establish(profile);
        expect(session.auth.isAuthenticated, isTrue);
        expect(session.repository.incidentWatches, hasLength(1));
        expect(session.repository.incidentWatches.single.actor, profile);
        expect(session.repository.categoryWatches, hasLength(1));
        expect(
          session.repository.userWatches,
          hasLength(profile.role == UserRole.admin ? 1 : 0),
        );
        session.deliverEmptyWorkspace();
        expect(session.incidents.incidents, isEmpty);
        expect(session.incidents.error, isNull);
        expect(session.incidents.isLoading, isFalse);
      },
    );
  }

  for (final action in ['editar perfil', 'recuperar contraseña']) {
    test('$action conserva las consultas de una sesión ya validada', () async {
      session.establish(_reporter);
      session.deliverEmptyWorkspace();
      session.incidents.setQuery('aula');
      final pending = Completer<void>();
      session.repository.accountActionResult = pending.future;
      final result = action == 'editar perfil'
          ? session.auth.updateProfile('Nombre actualizado')
          : session.auth.resetPassword(_reporter.email);

      expect(session.auth.isLoading, isTrue);
      expect(session.auth.isAuthenticated, isTrue);
      expect(session.repository.incidentWatches, hasLength(1));
      expect(session.repository.categoryWatches, hasLength(1));
      expect(session.incidents.query, 'aula');
      expect(
        session.repository.incidentWatches.single.values.hasListener,
        isTrue,
      );

      pending.complete();
      expect(await result, isTrue);
      expect(session.repository.incidentWatches, hasLength(1));
      expect(session.incidents.query, 'aula');
    });
  }

  test(
    'un error de una operación anterior no aparece en la sesión nueva',
    () async {
      session.establish(_admin);
      session.deliverEmptyWorkspace();
      final pending = Completer<void>();
      session.repository.saveCategoryResult = pending.future;
      final saving = session.incidents.saveCategory(
        name: 'Nueva categoría',
        description: '',
      );
      expect(session.incidents.isSaving, isTrue);

      session.repository.fakeAuth.emit(null);
      session.establish(_reporter);
      session.deliverEmptyWorkspace();
      expect(session.incidents.isSaving, isFalse);

      pending.completeError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(await saving, isFalse);
      expect(session.auth.profile, _reporter);
      expect(session.incidents.error, isNull);
      expect(session.incidents.isSaving, isFalse);
    },
  );

  test('la sesión nueva conserva sus datos si llega el perfil anterior', () {
    session.establish(_admin);
    final oldProfile = session.repository.profilesFor(_admin.uid);
    session.repository.fakeAuth.emit(null);
    session.establish(_reporter);

    oldProfile.add(_admin);
    oldProfile.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );

    expect(session.auth.profile, _reporter);
    expect(session.auth.error, isNull);
    expect(session.repository.incidentWatches.last.actor, _reporter);
    expect(session.incidents.error, isNull);
  });

  test('salir del administrador borra datos y cancela sus consultas', () {
    session.establish(_admin);
    final oldIncidents = session.repository.incidentWatches.single.values;
    final oldUsers = session.repository.userWatches.single;
    oldIncidents.add([_incident]);
    oldUsers.add([_admin, _reporter]);
    expect(session.incidents.incidents, hasLength(1));
    expect(session.incidents.users, hasLength(2));

    session.repository.fakeAuth.emit(null);
    expect(session.incidents.incidents, isEmpty);
    expect(session.incidents.users, isEmpty);
    expect(oldIncidents.hasListener, isFalse);
    expect(oldUsers.hasListener, isFalse);

    session.establish(_reporter);
    oldIncidents.add([_incident]);
    oldUsers.add([_admin]);
    oldIncidents.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    session.deliverEmptyWorkspace();
    expect(session.incidents.incidents, isEmpty);
    expect(session.incidents.users, isEmpty);
    expect(session.incidents.error, isNull);
  });
}

class _SessionHarness {
  _SessionHarness() {
    auth = AuthState(repository);
    incidents = IncidentState(repository, auth);
    repository.fakeAuth.emit(null);
  }

  final repository = _ControlledRepository();
  late final AuthState auth;
  late final IncidentState incidents;

  void establish(UserProfile profile) {
    repository.fakeAuth.emit(_TestUser(profile.uid));
    repository.profilesFor(profile.uid).add(profile);
  }

  void deliverEmptyWorkspace() {
    repository.incidentWatches.last.values.add(const []);
    repository.categoryWatches.last.add(const []);
    if (auth.profile?.role == UserRole.admin) {
      repository.userWatches.last.add(const []);
    }
  }

  Future<void> dispose() async {
    incidents.dispose();
    auth.dispose();
    await repository.dispose();
  }
}

class _TestUser extends Fake implements User {
  _TestUser(this.uid);

  @override
  final String uid;
}

class _ControlledAuth extends Fake implements FirebaseAuth {
  final changes = StreamController<User?>.broadcast(sync: true);

  @override
  User? currentUser;

  @override
  Stream<User?> userChanges() => changes.stream;

  void emit(User? user) {
    currentUser = user;
    changes.add(user);
  }
}

class _IncidentWatch {
  _IncidentWatch(this.actor);

  final UserProfile actor;
  final values = StreamController<List<Incident>>.broadcast(sync: true);
}

class _ControlledRepository extends Fake implements FirebaseRepository {
  final fakeAuth = _ControlledAuth();
  final _profiles = <String, StreamController<UserProfile?>>{};
  final incidentWatches = <_IncidentWatch>[];
  final categoryWatches = <StreamController<List<Category>>>[];
  final userWatches = <StreamController<List<UserProfile>>>[];
  Future<void> registerResult = Future<void>.value();
  Future<void> loginResult = Future<void>.value();
  Future<void> saveCategoryResult = Future<void>.value();
  Future<void> accountActionResult = Future<void>.value();

  @override
  FirebaseAuth get auth => fakeAuth;

  StreamController<UserProfile?> profilesFor(String uid) =>
      _profiles.putIfAbsent(
        uid,
        () => StreamController<UserProfile?>.broadcast(sync: true),
      );

  @override
  Stream<UserProfile?> watchProfile(String uid) => profilesFor(uid).stream;

  @override
  Stream<List<Incident>> watchIncidents(UserProfile actor) {
    final watch = _IncidentWatch(actor);
    incidentWatches.add(watch);
    return watch.values.stream;
  }

  @override
  Stream<List<Category>> watchCategories() {
    final values = StreamController<List<Category>>.broadcast(sync: true);
    categoryWatches.add(values);
    return values.stream;
  }

  @override
  Stream<List<UserProfile>> watchUsers() {
    final values = StreamController<List<UserProfile>>.broadcast(sync: true);
    userWatches.add(values);
    return values.stream;
  }

  @override
  Future<void> register(String name, String email, String password) =>
      registerResult;

  @override
  Future<void> login(String email, String password) => loginResult;

  @override
  Future<void> updateProfile(String name) => accountActionResult;

  @override
  Future<void> resetPassword(String email) => accountActionResult;

  @override
  Future<void> saveCategory({
    String? id,
    required String name,
    String description = '',
    bool active = true,
  }) => saveCategoryResult;

  Future<void> dispose() async {
    await Future.wait([
      fakeAuth.changes.close(),
      ..._profiles.values.map((values) => values.close()),
      ...incidentWatches.map((watch) => watch.values.close()),
      ...categoryWatches.map((values) => values.close()),
      ...userWatches.map((values) => values.close()),
    ]);
  }
}
