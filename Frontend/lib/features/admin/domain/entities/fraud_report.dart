/// Fraud / discipline reports (pure Dart).
///
/// Backend endpoints: none yet (exams module planned).
enum FraudSeverity { critical, medium, closed }

enum FraudStatus { untreated, ongoing, closed }

/// Aggregate counters returned alongside the report list by the future API.
class FraudSummary {
  final int unresolved;
  final int resolvedThisMonth;
  final double integrityPct;

  const FraudSummary({
    required this.unresolved,
    required this.resolvedThisMonth,
    required this.integrityPct,
  });
}

class FraudReport {
  final String id;
  final FraudSeverity severity;
  final FraudStatus status;
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
  });
}
