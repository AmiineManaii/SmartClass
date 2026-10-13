/// Fraud / discipline reports (pure Dart).
///
/// Shapes mirror `contracts/exams.openapi.yaml` (FraudReportView +
/// fraud summary). No integrity percentage exists server-side (it needs
/// the exams denominator), so none is modelled here.
enum FraudSeverity { critical, medium, closed }

enum FraudStatus { untreated, ongoing, closed }

/// Aggregate counters from GET /api/v1/exams/fraud-reports/summary.
class FraudSummary {
  final int unresolved;
  final int inProgress;
  final int resolvedThisMonth;

  const FraudSummary({
    required this.unresolved,
    required this.inProgress,
    required this.resolvedThisMonth,
  });
}

class FraudReport {
  final String id;
  final FraudSeverity severity;
  final FraudStatus status;

  /// Local "HH:mm" rendering of [occurredAt] for compact display.
  final String time;
  final String title;
  final String subtitle;
  final String studentName;
  final String studentId;
  final String studentClass;
  final List<String> findings;
  final String? reason;
  final String? resolution;
  final String? closedDate;

  /// Raw occurrence timestamp (relative dates, sorting).
  final DateTime occurredAt;

  const FraudReport({
    required this.id,
    required this.severity,
    required this.status,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.studentName,
    required this.studentId,
    required this.studentClass,
    this.findings = const [],
    this.reason,
    this.resolution,
    this.closedDate,
    required this.occurredAt,
  });
}
