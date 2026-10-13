/// Course entry of the "Mes cours" page.
///
/// Source: `GET /api/v1/groups/mine` (the caller's class memberships,
/// backend `MyClassGroup` — see `contracts/groups.openapi.yaml`). This entry
/// is the class-scoped view; generated-course content lives in
/// [GeneratedCourse] (`contracts/courses.openapi.yaml`).
class CourseEntry {
  const CourseEntry({
    required this.id,
    required this.name,
    required this.level,
    required this.status,
    required this.memberCount,
    required this.teacherCount,
    required this.myRole,
    this.department,
    this.subjects = const [],
  });

  final String id;
  final String name;
  final String level;
  final String? department;

  /// Backend `ClassStatus` : `PUBLISHED` | `DRAFT`.
  final String status;
  final int memberCount;
  final int teacherCount;

  /// Caller's relation: `STUDENT` | `TEACHER` | `REFERENT`.
  final String myRole;

  /// Subjects the caller teaches (teachers only, empty for students).
  final List<String> subjects;

  bool get isPublished => status == 'PUBLISHED';
  bool get isDraft => status == 'DRAFT';
}
