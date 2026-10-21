import 'package:flutter/foundation.dart';

import '../domain/dashboard_metrics.dart';
import 'incident_state.dart';

class DashboardState extends ChangeNotifier {
  DashboardState(this.incidentState) {
    incidentState.addListener(_changed);
  }
  final IncidentState incidentState;
  DashboardMetrics get metrics =>
      DashboardMetrics.fromIncidents(incidentState.incidents);
  void _changed() => notifyListeners();
  @override
  void dispose() {
    incidentState.removeListener(_changed);
    super.dispose();
  }
}
