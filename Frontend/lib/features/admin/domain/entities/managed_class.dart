/// Class/cohort under administration (pure Dart).
///
/// Shapes mirror `contracts/groups.openapi.yaml` (ClassGroupSummary/Detail).
/// Only backend-provided values: no attendance or course-engine figures
/// exist server-side, so none are modelled here.
enum ClassLevel { licence, master, doctorat }

class AdminClassSummary {
  final String id;

  /// Filière (department) + promo years, e.g. "Informatique • 2024–2025".
  final String promoTag;
  final String? statusKey;
  final bool statusActive;
  final String title;
  final String icon;
  final int students;
  final int teachers;

  /// Referent full name, or '' when the class has none.
  final String referent;
  final ClassLevel level;
  final List<String> extraChips;

  const AdminClassSummary({
    required this.id,
    required this.promoTag,
    this.statusKey,
    this.statusActive = true,
    required this.title,
    required this.icon,
    required this.students,
    required this.teachers,
    required this.referent,
    required this.level,
    this.extraChips = const [],
  });
}

class AdminClassDetail extends AdminClassSummary {
  final int capacity;

  /// Department (filière), or '' when unset.
  final String department;

  const AdminClassDetail({
    required super.id,
    required super.promoTag,
    super.statusKey,
    super.statusActive,
    required super.title,
    required super.icon,
    required super.students,
    required super.teachers,
    required super.referent,
    required super.level,
    super.extraChips,
    required this.capacity,
    required this.department,
  });
}
