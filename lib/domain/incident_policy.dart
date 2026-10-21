import 'models.dart';

/// Mirrors the server-enforced workflow. UI visibility is not authorization:
/// Firestore and Storage rules independently enforce the same permissions.
abstract final class IncidentPolicy {
  static bool canRead(Incident incident, UserProfile actor) =>
      actor.active &&
      (actor.role == UserRole.admin ||
          (actor.role == UserRole.reporter &&
              incident.reporterId == actor.uid) ||
          (actor.role == UserRole.technician &&
              incident.assignedTo == actor.uid));

  static bool canClassify(Incident incident, UserProfile actor) =>
      actor.active &&
      actor.role == UserRole.admin &&
      const {
        IncidentStatus.reported,
        IncidentStatus.inReview,
        IncidentStatus.assigned,
        IncidentStatus.reopened,
      }.contains(incident.status);

  static bool canAssign(Incident incident, UserProfile actor) =>
      actor.active &&
      actor.role == UserRole.admin &&
      const {
        IncidentStatus.reported,
        IncidentStatus.inReview,
        IncidentStatus.assigned,
        IncidentStatus.reopened,
      }.contains(incident.status);

  static bool canComment(Incident incident, UserProfile actor) =>
      canRead(incident, actor);

  static List<IncidentStatus> allowedTransitions(
    Incident incident,
    UserProfile actor,
  ) {
    if (!canRead(incident, actor)) return const [];
    final status = incident.status;
    final result = <IncidentStatus>{};
    if (actor.role == UserRole.admin) {
      switch (status) {
        case IncidentStatus.reported:
          result.addAll([IncidentStatus.inReview, IncidentStatus.rejected]);
          break;
        case IncidentStatus.inReview:
          result.add(IncidentStatus.rejected);
          break;
        case IncidentStatus.assigned:
        case IncidentStatus.inProgress:
          break;
        case IncidentStatus.resolved:
          result.addAll([IncidentStatus.closed, IncidentStatus.reopened]);
          break;
        case IncidentStatus.closed:
        case IncidentStatus.rejected:
          result.add(IncidentStatus.reopened);
          break;
        case IncidentStatus.reopened:
          result.add(IncidentStatus.inReview);
          break;
        case IncidentStatus.cancelled:
          break;
      }
    }
    if (actor.role == UserRole.technician && incident.assignedTo == actor.uid) {
      if (status == IncidentStatus.assigned) {
        result.add(IncidentStatus.inProgress);
      }
      if (status == IncidentStatus.inProgress) {
        result.add(IncidentStatus.resolved);
      }
    }
    if (actor.role == UserRole.reporter && incident.reporterId == actor.uid) {
      if ({IncidentStatus.reported, IncidentStatus.inReview}.contains(status)) {
        result.add(IncidentStatus.cancelled);
      }
      if ({
        IncidentStatus.resolved,
        IncidentStatus.closed,
        IncidentStatus.rejected,
      }.contains(status)) {
        result.add(IncidentStatus.reopened);
      }
    }
    return List.unmodifiable(result);
  }
}

class IncidentFilter {
  const IncidentFilter({
    this.query = '',
    this.status,
    this.categoryId,
    this.priority,
    this.assignedTo,
  });
  final String query;
  final IncidentStatus? status;
  final String? categoryId;
  final IncidentPriority? priority;

  /// Empty string selects incidents without a responsible technician.
  final String? assignedTo;

  List<Incident> apply(Iterable<Incident> incidents) {
    final term = query.trim().toLowerCase();
    return incidents
        .where((incident) {
          if (status != null && incident.status != status) return false;
          if (categoryId != null && incident.categoryId != categoryId) {
            return false;
          }
          if (priority != null && incident.priority != priority) return false;
          if (assignedTo != null && (incident.assignedTo ?? '') != assignedTo) {
            return false;
          }
          return term.isEmpty ||
              [
                incident.number,
                incident.title,
                incident.description,
                incident.location,
                incident.categoryName,
                incident.reporterName,
                incident.assignedName ?? '',
              ].any((value) => value.toLowerCase().contains(term));
        })
        .toList(growable: false);
  }
}
