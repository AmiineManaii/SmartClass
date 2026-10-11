/// Class/cohort under administration (pure Dart).
///
/// Backend endpoints: none yet (groups module planned).
/// Values come from the mock datasource until then.
enum ClassLevel { licence, master, doctorat }

class AdminClassSummary {
  final String id;
  final String promoTag;
  final String? statusKey;
  final bool statusActive;
  final String title;
  final String icon;
  final int students;
  final int teachers;
  final String referent;
  final int presencePct;
  final int coursesActive;
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
    required this.presencePct,
    required this.coursesActive,
    required this.level,
    this.extraChips = const [],
  });
}

class AdminClassDetail extends AdminClassSummary {
  final int capacity;
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
    required super.presencePct,
    required super.coursesActive,
    required super.level,
    super.extraChips,
    required this.capacity,
    required this.department,
  });
}
