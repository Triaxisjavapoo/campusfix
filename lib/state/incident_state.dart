import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../data/firebase_repository.dart';
import '../domain/incident_policy.dart';
import '../domain/models.dart';
import 'auth_state.dart';

class IncidentState extends ChangeNotifier {
  IncidentState(this.repository, this.auth) {
    auth.addListener(_bind);
    _bind();
  }
  final FirebaseRepository repository;
  final AuthState auth;
  StreamSubscription<List<Incident>>? _incidentSubscription;
  StreamSubscription<List<Category>>? _categorySubscription;
  StreamSubscription<List<UserProfile>>? _userSubscription;
  List<Incident> incidents = const [];
  List<Category> categories = const [];
  List<UserProfile> users = const [];
  List<UserProfile> get technicians => users
      .where((user) => user.active && user.role == UserRole.technician)
      .toList(growable: false);
  List<Category> get activeCategories =>
      categories.where((category) => category.active).toList(growable: false);
  String? error;
  String query = '';
  IncidentStatus? statusFilter;
  String? categoryFilter;
  IncidentPriority? priorityFilter;
  String? assigneeFilter;
  bool _waitingForIncidents = false;
  bool _busy = false;
  bool _disposed = false;
  String? _identity;
  int _generation = 0;
  bool get isLoading => _waitingForIncidents || _busy;
  bool get isSaving => _busy;
  List<Incident> get filteredIncidents => IncidentFilter(
    query: query,
    status: statusFilter,
    categoryId: categoryFilter,
    priority: priorityFilter,
    assignedTo: assigneeFilter,
  ).apply(incidents);

  void _bind() {
    final actor = auth.isAuthenticated ? auth.profile : null;
    final identity = actor?.active == true
        ? '${actor!.uid}:${actor.role.value}'
        : null;
    if (_identity == identity) return;
    _identity = identity;
    final generation = ++_generation;
    _busy = false;
    unawaited(_incidentSubscription?.cancel());
    unawaited(_categorySubscription?.cancel());
    unawaited(_userSubscription?.cancel());
    _incidentSubscription = null;
    _categorySubscription = null;
    _userSubscription = null;
    incidents = const [];
    categories = const [];
    users = const [];
    error = null;
    query = '';
    statusFilter = null;
    categoryFilter = null;
    priorityFilter = null;
    assigneeFilter = null;
    _waitingForIncidents = identity != null;
    if (identity != null && actor != null) {
      _incidentSubscription = repository.watchIncidents(actor).listen(
        (value) {
          if (_generation != generation) return;
          incidents = List.unmodifiable(value);
          _waitingForIncidents = false;
          _notify();
        },
        onError: (Object exception) =>
            _streamError(exception, generation, 'las incidencias'),
      );
      _categorySubscription = repository.watchCategories().listen(
        (value) {
          if (_generation != generation) return;
          categories = List.unmodifiable(value);
          _notify();
        },
        onError: (Object exception) =>
            _streamError(exception, generation, 'las categorías'),
      );
      if (actor.role == UserRole.admin) {
        _userSubscription = repository.watchUsers().listen(
          (value) {
            if (_generation != generation) return;
            users = List.unmodifiable(value);
            _notify();
          },
          onError: (Object exception) =>
              _streamError(exception, generation, 'los usuarios'),
        );
      }
    }
    _notify();
  }

  void _streamError(Object exception, int generation, String source) {
    if (_disposed || _generation != generation) return;
    error = 'No se pudieron cargar $source. ${friendlyError(exception)}';
    _waitingForIncidents = false;
    _notify();
  }

  void setQuery(String value) {
    query = value;
    _notify();
  }

  void setStatusFilter(IncidentStatus? value) {
    statusFilter = value;
    _notify();
  }

  void setCategoryFilter(String? value) {
    categoryFilter = value;
    _notify();
  }

  void setPriorityFilter(IncidentPriority? value) {
    priorityFilter = value;
    _notify();
  }

  void setAssigneeFilter(String? value) {
    assigneeFilter = value;
    _notify();
  }

  void clearFilters() {
    query = '';
    statusFilter = null;
    categoryFilter = null;
    priorityFilter = null;
    assigneeFilter = null;
    _notify();
  }

  void clearError() {
    error = null;
    _notify();
  }

  Future<String?> createIncident({
    required String title,
    required String description,
    required String categoryId,
    required String location,
    required IncidentPriority priority,
  }) async {
    String? id;
    final saved = await _run(() async {
      id = await repository.createIncident(
        title: title,
        description: description,
        categoryId: categoryId,
        location: location,
        priority: priority,
      );
    });
    return saved ? id : null;
  }

  Future<bool> classifyIncident(
    Incident incident, {
    required String categoryId,
    required IncidentPriority priority,
    required String note,
  }) => _run(
    () => repository.classifyIncident(
      incident,
      categoryId: categoryId,
      priority: priority,
      note: note,
    ),
  );
  Future<bool> assignIncident(
    Incident incident,
    UserProfile technician, {
    required String note,
  }) => _run(() => repository.assignIncident(incident, technician, note: note));
  Future<bool> transitionIncident(
    Incident incident,
    IncidentStatus next, {
    required String note,
  }) => _run(() => repository.transitionIncident(incident, next, note: note));
  Future<bool> addComment(Incident incident, String text) =>
      _run(() => repository.addComment(incident, text));
  Future<bool> uploadEvidence(
    Incident incident, {
    required String name,
    required Uint8List bytes,
    required String contentType,
  }) => _run(
    () => repository.uploadEvidence(
      incident,
      name: name,
      bytes: bytes,
      contentType: contentType,
    ),
  );
  Future<Uint8List?> evidenceBytes(IncidentEvidence evidence) =>
      repository.evidenceBytes(evidence);
  Stream<List<IncidentEvent>> eventsFor(String id) =>
      repository.watchEvents(id);
  Stream<List<IncidentComment>> commentsFor(String id) =>
      repository.watchComments(id);
  Stream<List<IncidentEvidence>> evidenceFor(String id) =>
      repository.watchEvidence(id);

  Future<bool> saveCategory({
    String? id,
    required String name,
    required String description,
    bool active = true,
  }) => _run(
    () => repository.saveCategory(
      id: id,
      name: name,
      description: description,
      active: active,
    ),
  );
  Future<bool> setCategoryActive(Category category, bool active) =>
      _run(() => repository.setCategoryActive(category, active));
  Future<bool> setUserRole(UserProfile user, UserRole role) =>
      _run(() => repository.setUserRole(user, role));
  Future<bool> setUserActive(UserProfile user, bool active) =>
      _run(() => repository.setUserActive(user, active));

  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    final generation = _generation;
    _busy = true;
    error = null;
    _notify();
    try {
      await action();
      return !_disposed && _generation == generation;
    } catch (exception) {
      if (!_disposed && _generation == generation) {
        error = friendlyError(exception);
      }
      return false;
    } finally {
      if (!_disposed && _generation == generation) {
        _busy = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    auth.removeListener(_bind);
    unawaited(_incidentSubscription?.cancel());
    unawaited(_categorySubscription?.cancel());
    unawaited(_userSubscription?.cancel());
    super.dispose();
  }
}
