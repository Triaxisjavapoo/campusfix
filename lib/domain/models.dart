/// Shared, Firebase-independent domain models used by the interface and tests.
enum UserRole {
  reporter('reporter', 'Reportante'),
  technician('technician', 'Técnico'),
  admin('admin', 'Administrador');

  const UserRole(this.value, this.label);
  final String value;
  final String label;
  static UserRole parse(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => UserRole.reporter,
  );
}

enum IncidentPriority {
  low('BAJA', 'Baja'),
  medium('MEDIA', 'Media'),
  high('ALTA', 'Alta'),
  critical('CRITICA', 'Crítica');

  const IncidentPriority(this.value, this.label);
  final String value;
  final String label;
  static IncidentPriority parse(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => IncidentPriority.medium,
  );
}

enum IncidentStatus {
  reported('REPORTADA', 'Reportada'),
  inReview('EN_REVISION', 'En revisión'),
  assigned('ASIGNADA', 'Asignada'),
  inProgress('EN_ATENCION', 'En atención'),
  resolved('RESUELTA', 'Resuelta'),
  closed('CERRADA', 'Cerrada'),
  rejected('RECHAZADA', 'Rechazada'),
  cancelled('CANCELADA', 'Cancelada'),
  reopened('REABIERTA', 'Reabierta');

  const IncidentStatus(this.value, this.label);
  final String value;
  final String label;
  bool get isOpen =>
      const {reported, inReview, assigned, inProgress, reopened}.contains(this);
  static IncidentStatus parse(Object? value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => IncidentStatus.reported,
  );
}

DateTime? _date(Object? value) => value is DateTime
    ? value
    : value is String
    ? DateTime.tryParse(value)
    : null;

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) =>
      UserProfile(
        uid: id,
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        role: UserRole.parse(map['role']),
        active: map['active'] == true,
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
      );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    this.description = '',
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String name;
  final String description;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  factory Category.fromMap(String id, Map<String, dynamic> map) => Category(
    id: id,
    name: map['name'] as String? ?? '',
    description: map['description'] as String? ?? '',
    active: map['active'] == true,
    createdAt: _date(map['createdAt']),
    updatedAt: _date(map['updatedAt']),
  );
}

class Incident {
  const Incident({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.location,
    required this.priority,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    this.assignedTo,
    this.assignedName,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.version = 1,
    this.lastEventId = '',
  });
  final String id;
  final String number;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String location;
  final IncidentPriority priority;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final String? assignedTo;
  final String? assignedName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final int version;
  final String lastEventId;

  factory Incident.fromMap(String id, Map<String, dynamic> map) => Incident(
    id: id,
    number: map['number'] as String? ?? id,
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    categoryId: map['categoryId'] as String? ?? '',
    categoryName: map['categoryName'] as String? ?? '',
    location: map['location'] as String? ?? '',
    priority: IncidentPriority.parse(map['priority']),
    status: IncidentStatus.parse(map['status']),
    reporterId: map['reporterId'] as String? ?? '',
    reporterName: map['reporterName'] as String? ?? '',
    assignedTo: map['assignedTo'] as String?,
    assignedName: map['assignedName'] as String?,
    createdAt: _date(map['createdAt']),
    updatedAt: _date(map['updatedAt']),
    resolvedAt: _date(map['resolvedAt']),
    closedAt: _date(map['closedAt']),
    version: (map['version'] as num?)?.toInt() ?? 1,
    lastEventId: map['lastEventId'] as String? ?? '',
  );
}

class IncidentEvent {
  const IncidentEvent({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.type,
    required this.message,
    required this.toStatus,
    this.fromStatus,
    this.createdAt,
    this.version = 1,
  });
  final String id;
  final String actorId;
  final String actorName;
  final String type;
  final String message;
  final IncidentStatus? fromStatus;
  final IncidentStatus toStatus;
  final DateTime? createdAt;
  final int version;
  String get label =>
      const {
        'CREATED': 'Incidencia registrada',
        'CLASSIFIED': 'Clasificación actualizada',
        'ASSIGNED': 'Técnico asignado',
        'STATUS_CHANGED': 'Estado actualizado',
      }[type] ??
      type;

  factory IncidentEvent.fromMap(String id, Map<String, dynamic> map) =>
      IncidentEvent(
        id: id,
        actorId: map['actorId'] as String? ?? '',
        actorName: map['actorName'] as String? ?? '',
        type: map['type'] as String? ?? '',
        message: map['message'] as String? ?? '',
        fromStatus: map['fromStatus'] == null
            ? null
            : IncidentStatus.parse(map['fromStatus']),
        toStatus: IncidentStatus.parse(map['toStatus']),
        createdAt: _date(map['createdAt']),
        version: (map['version'] as num?)?.toInt() ?? 1,
      );
}

class IncidentComment {
  const IncidentComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    this.createdAt,
  });
  final String id;
  final String authorId;
  final String authorName;
  final String text;
  final DateTime? createdAt;
  factory IncidentComment.fromMap(String id, Map<String, dynamic> map) =>
      IncidentComment(
        id: id,
        authorId: map['authorId'] as String? ?? '',
        authorName: map['authorName'] as String? ?? '',
        text: map['text'] as String? ?? '',
        createdAt: _date(map['createdAt']),
      );
}

class IncidentEvidence {
  const IncidentEvidence({
    required this.id,
    required this.uploaderId,
    required this.uploaderName,
    required this.name,
    required this.path,
    required this.contentType,
    required this.size,
    this.createdAt,
  });
  final String id;
  final String uploaderId;
  final String uploaderName;
  final String name;
  final String path;
  final String contentType;
  final int size;
  final DateTime? createdAt;
  factory IncidentEvidence.fromMap(String id, Map<String, dynamic> map) =>
      IncidentEvidence(
        id: id,
        uploaderId: map['uploaderId'] as String? ?? '',
        uploaderName: map['uploaderName'] as String? ?? '',
        name: map['name'] as String? ?? '',
        path: map['path'] as String? ?? '',
        contentType: map['contentType'] as String? ?? '',
        size: (map['size'] as num?)?.toInt() ?? 0,
        createdAt: _date(map['createdAt']),
      );
}
