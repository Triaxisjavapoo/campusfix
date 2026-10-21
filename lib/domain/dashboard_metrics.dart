import 'models.dart';

class DashboardMetrics {
  const DashboardMetrics({
    required this.total,
    required this.open,
    required this.resolved,
    required this.closed,
    required this.critical,
    required this.byStatus,
    required this.byCategory,
    required this.byPriority,
    required this.averageResolutionHours,
  });
  final int total;
  final int open;
  final int resolved;
  final int closed;
  final int critical;
  final Map<IncidentStatus, int> byStatus;
  final Map<String, int> byCategory;
  final Map<IncidentPriority, int> byPriority;
  final double? averageResolutionHours;

  factory DashboardMetrics.fromIncidents(Iterable<Incident> incidents) {
    final items = incidents.toList(growable: false);
    final statuses = {for (final status in IncidentStatus.values) status: 0};
    final priorities = {
      for (final priority in IncidentPriority.values) priority: 0,
    };
    final categories = <String, int>{};
    final durations = <double>[];
    for (final item in items) {
      statuses[item.status] = statuses[item.status]! + 1;
      priorities[item.priority] = priorities[item.priority]! + 1;
      categories.update(
        item.categoryName,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      if (item.resolvedAt != null && item.createdAt != null) {
        final elapsed =
            item.resolvedAt!.difference(item.createdAt!).inMinutes / 60;
        if (elapsed >= 0) durations.add(elapsed);
      }
    }
    return DashboardMetrics(
      total: items.length,
      open: items.where((item) => item.status.isOpen).length,
      resolved: statuses[IncidentStatus.resolved]!,
      closed: statuses[IncidentStatus.closed]!,
      critical: items
          .where(
            (item) =>
                item.priority == IncidentPriority.critical &&
                item.status.isOpen,
          )
          .length,
      byStatus: Map.unmodifiable(statuses),
      byCategory: Map.unmodifiable(categories),
      byPriority: Map.unmodifiable(priorities),
      averageResolutionHours: durations.isEmpty
          ? null
          : durations.reduce((a, b) => a + b) / durations.length,
    );
  }
}
