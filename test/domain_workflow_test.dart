import 'package:campusfix/domain/dashboard_metrics.dart';
import 'package:campusfix/domain/incident_policy.dart';
import 'package:campusfix/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

const reporter = UserProfile(
  uid: 'reporter',
  name: 'Ana Reportante',
  email: 'ana@example.test',
  role: UserRole.reporter,
);
const otherReporter = UserProfile(
  uid: 'other',
  name: 'Otra Persona',
  email: 'otra@example.test',
  role: UserRole.reporter,
);
const technician = UserProfile(
  uid: 'tech',
  name: 'Luis Técnico',
  email: 'luis@example.test',
  role: UserRole.technician,
);
const otherTechnician = UserProfile(
  uid: 'other-tech',
  name: 'Otro Técnico',
  email: 'otro@example.test',
  role: UserRole.technician,
);
const admin = UserProfile(
  uid: 'admin',
  name: 'Eva Administradora',
  email: 'eva@example.test',
  role: UserRole.admin,
);

Incident incident({
  String id = 'incident-1',
  IncidentStatus status = IncidentStatus.reported,
  IncidentPriority priority = IncidentPriority.medium,
  String? assignedTo,
  String categoryId = 'water',
  String categoryName = 'Agua',
  DateTime? createdAt,
  DateTime? resolvedAt,
}) => Incident(
  id: id,
  number: 'CF-2026-ABCDEFGH',
  title: 'Fuga en biblioteca',
  description: 'Una tubería tiene una fuga junto a la entrada.',
  categoryId: categoryId,
  categoryName: categoryName,
  location: 'Biblioteca, planta baja',
  priority: priority,
  status: status,
  reporterId: reporter.uid,
  reporterName: reporter.name,
  assignedTo: assignedTo,
  createdAt: createdAt,
  resolvedAt: resolvedAt,
);

void main() {
  group('Permisos y ciclo de vida', () {
    test(
      'reportante solo consulta incidencias propias y cancela antes de atención',
      () {
        expect(IncidentPolicy.canRead(incident(), reporter), isTrue);
        expect(IncidentPolicy.canRead(incident(), otherReporter), isFalse);
        expect(IncidentPolicy.allowedTransitions(incident(), reporter), [
          IncidentStatus.cancelled,
        ]);
        expect(
          IncidentPolicy.allowedTransitions(
            incident(status: IncidentStatus.inReview),
            reporter,
          ),
          [IncidentStatus.cancelled],
        );
        expect(
          IncidentPolicy.allowedTransitions(
            incident(status: IncidentStatus.inProgress),
            reporter,
          ),
          isEmpty,
        );
      },
    );

    test('solo el técnico asignado inicia y resuelve', () {
      final assigned = incident(
        status: IncidentStatus.assigned,
        assignedTo: technician.uid,
      );
      expect(IncidentPolicy.allowedTransitions(assigned, technician), [
        IncidentStatus.inProgress,
      ]);
      expect(
        IncidentPolicy.allowedTransitions(assigned, otherTechnician),
        isEmpty,
      );
      expect(IncidentPolicy.allowedTransitions(assigned, admin), isEmpty);
      final working = incident(
        status: IncidentStatus.inProgress,
        assignedTo: technician.uid,
      );
      expect(IncidentPolicy.allowedTransitions(working, technician), [
        IncidentStatus.resolved,
      ]);
      expect(IncidentPolicy.allowedTransitions(working, admin), isEmpty);
    });

    test('cierre administrativo y reapertura del reportante', () {
      final resolved = incident(status: IncidentStatus.resolved);
      expect(IncidentPolicy.allowedTransitions(resolved, reporter), [
        IncidentStatus.reopened,
      ]);
      expect(
        IncidentPolicy.allowedTransitions(resolved, admin),
        contains(IncidentStatus.closed),
      );
      expect(
        IncidentPolicy.allowedTransitions(
          incident(status: IncidentStatus.closed),
          reporter,
        ),
        [IncidentStatus.reopened],
      );
      expect(
        IncidentPolicy.allowedTransitions(
          incident(status: IncidentStatus.cancelled),
          admin,
        ),
        isEmpty,
      );
    });

    test('administrador clasifica y asigna solo durante la gestión previa', () {
      for (final status in [
        IncidentStatus.reported,
        IncidentStatus.inReview,
        IncidentStatus.assigned,
        IncidentStatus.reopened,
      ]) {
        expect(
          IncidentPolicy.canAssign(incident(status: status), admin),
          isTrue,
        );
        expect(
          IncidentPolicy.canClassify(incident(status: status), admin),
          isTrue,
        );
      }
      for (final status in [
        IncidentStatus.inProgress,
        IncidentStatus.resolved,
        IncidentStatus.closed,
        IncidentStatus.rejected,
        IncidentStatus.cancelled,
      ]) {
        expect(
          IncidentPolicy.canAssign(incident(status: status), admin),
          isFalse,
        );
        expect(
          IncidentPolicy.canClassify(incident(status: status), admin),
          isFalse,
        );
      }
      expect(IncidentPolicy.canAssign(incident(), reporter), isFalse);
    });

    test('una cuenta inactiva no puede leer ni operar', () {
      const inactive = UserProfile(
        uid: 'admin',
        name: 'Eva Administradora',
        email: 'eva@example.test',
        role: UserRole.admin,
        active: false,
      );
      expect(IncidentPolicy.canRead(incident(), inactive), isFalse);
      expect(IncidentPolicy.canClassify(incident(), inactive), isFalse);
      expect(IncidentPolicy.allowedTransitions(incident(), inactive), isEmpty);
    });
  });

  group('Búsqueda y filtros combinados', () {
    final items = [
      incident(id: '1', priority: IncidentPriority.critical),
      incident(
        id: '2',
        status: IncidentStatus.assigned,
        assignedTo: technician.uid,
        categoryId: 'electricity',
        categoryName: 'Electricidad',
      ),
      incident(
        id: '3',
        status: IncidentStatus.closed,
        priority: IncidentPriority.low,
      ),
    ];

    test('combina estado, categoría, prioridad y responsable', () {
      final filter = IncidentFilter(
        status: IncidentStatus.assigned,
        categoryId: 'electricity',
        priority: IncidentPriority.medium,
        assignedTo: technician.uid,
      );
      expect(filter.apply(items).map((item) => item.id), ['2']);
      expect(
        const IncidentFilter(
          assignedTo: '',
        ).apply(items).map((item) => item.id),
        ['1', '3'],
      );
    });

    test('busca sin distinguir mayúsculas en número, ubicación y texto', () {
      expect(
        const IncidentFilter(query: '  BIBLIOTECA ').apply(items),
        hasLength(3),
      );
      expect(const IncidentFilter(query: 'CF-2026').apply(items), hasLength(3));
      expect(const IncidentFilter(query: 'no-existe').apply(items), isEmpty);
    });
  });

  group('Indicadores con datos reales', () {
    test('cuenta estados abiertos y críticos sin confundir cerradas', () {
      final metrics = DashboardMetrics.fromIncidents([
        incident(priority: IncidentPriority.critical),
        incident(
          status: IncidentStatus.closed,
          priority: IncidentPriority.critical,
        ),
        incident(status: IncidentStatus.resolved),
        incident(status: IncidentStatus.reopened),
        incident(status: IncidentStatus.cancelled),
      ]);
      expect(metrics.total, 5);
      expect(metrics.open, 2);
      expect(metrics.critical, 1);
      expect(metrics.resolved, 1);
      expect(metrics.closed, 1);
      expect(metrics.byStatus[IncidentStatus.cancelled], 1);
      expect(metrics.byCategory['Agua'], 5);
    });

    test(
      'promedia solo resoluciones con fechas válidas y maneja lista vacía',
      () {
        final start = DateTime.utc(2026, 10, 21);
        final metrics = DashboardMetrics.fromIncidents([
          incident(
            createdAt: start,
            resolvedAt: start.add(const Duration(hours: 4)),
          ),
          incident(
            createdAt: start,
            resolvedAt: start.add(const Duration(hours: 8)),
          ),
          incident(createdAt: start),
          incident(
            createdAt: start,
            resolvedAt: start.subtract(const Duration(hours: 1)),
          ),
        ]);
        expect(metrics.averageResolutionHours, 6);
        final empty = DashboardMetrics.fromIncidents([]);
        expect(empty.total, 0);
        expect(empty.averageResolutionHours, isNull);
      },
    );
  });

  test('deserializa sin fecha del servidor pendiente sin inventar datos', () {
    final value = Incident.fromMap('abc', {
      'number': 'CF-2026-ABCDEFGH',
      'title': 'Luz dañada',
      'description': 'No enciende la luz.',
      'categoryId': 'light',
      'categoryName': 'Electricidad',
      'location': 'Aula 1',
      'priority': 'ALTA',
      'status': 'EN_ATENCION',
      'reporterId': reporter.uid,
      'reporterName': reporter.name,
      'version': 4,
      'lastEventId': 'event-4',
    });
    expect(value.status, IncidentStatus.inProgress);
    expect(value.priority, IncidentPriority.high);
    expect(value.createdAt, isNull);
    expect(value.version, 4);
  });
}
