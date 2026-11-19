/// One course the teacher may use as an AI exam source.
///
/// Source: `GET /api/v1/exams/classes/:classGroupId/courses`. Only courses
/// already PUBLISHED are returned; publication requires every generated
/// section to be VALIDATED, so the list is exactly "generated and validated".
class ExamCourseOption {
  const ExamCourseOption({required this.id, required this.title, this.subject});

  final String id;
  final String title;
  final String? subject;
}
