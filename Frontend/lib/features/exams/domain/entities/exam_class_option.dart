/// One class the caller belongs to, used by exam authoring selectors.
///
/// Source: `GET /api/v1/groups/mine` (same `MyClassGroup` shape as the
/// courses feature). Only classes where the caller is a teacher/referent are
/// offered for exam authoring; the backend still enforces access.
class ExamClassOption {
  const ExamClassOption({
    required this.id,
    required this.name,
    required this.myRole,
    this.department,
  });

  final String id;
  final String name;
  final String myRole;
  final String? department;

  bool get isTeacher => myRole == 'TEACHER' || myRole == 'REFERENT';
}
