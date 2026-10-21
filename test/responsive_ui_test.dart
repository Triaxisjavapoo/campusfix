import 'package:campusfix/domain/dashboard_metrics.dart';
import 'package:campusfix/domain/models.dart';
import 'package:campusfix/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const incident = Incident(
  id: 'case-one',
  number: 'CF-2026-TEST0001',
  title: 'Fuga de agua en el laboratorio de ciencias',
  description: 'Hay una fuga que necesita revisión.',
  categoryId: 'infra',
  categoryName: 'Infraestructura y accesibilidad',
  location: 'Edificio principal, laboratorio de ciencias, segundo piso',
  priority: IncidentPriority.high,
  status: IncidentStatus.inProgress,
  reporterId: 'student-one',
  reporterName: 'María Estudiante',
);

void main() {
  testWidgets('La tabla permite abrir el caso en escritorio y tablet', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final width in [1280.0, 768.0]) {
      tester.view.physicalSize = Size(width, 900);
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: campusTheme(Brightness.light),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: IncidentTable(
                items: const [incident],
                open: (id) => opened = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(incident.title));
      expect(opened, incident.id);
    }
  });

  testWidgets('Indicadores y categorías se adaptan a tablet y tema oscuro', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final width in [1280.0, 768.0]) {
      tester.view.physicalSize = Size(width, 1000);
      final metrics = DashboardMetrics.fromIncidents(const [incident]);
      await tester.pumpWidget(
        MaterialApp(
          theme: campusTheme(Brightness.dark),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    MetricsGrid(metrics: metrics),
                    const SizedBox(height: 20),
                    CategoryChart(metrics: metrics),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('En atención'), findsOneWidget);
      expect(find.text('Infraestructura y accesibilidad'), findsOneWidget);
    }
  });
}
