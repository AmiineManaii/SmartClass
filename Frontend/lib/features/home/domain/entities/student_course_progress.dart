/// Progress of the student in a teacher-authored course.
///
/// Pure Dart — no Flutter dependency.
///
/// Source of truth (planned): courses module (`GET /api/v1/courses/...`,
/// contract not yet written). Courses are created by the teacher and only
/// then displayed here. Until then the provider resolves to an empty list
/// and the section renders its empty state — no invented courses.
class StudentCourseProgress {
  final String id;
  final String title;
  final String lastLesson;
  final int progressPercent;
  final String badgeText;
  final String badgeTone; // 'tertiary' (green), 'neutral' (surface-container)
  final String iconName; // 'terminal', 'database', 'memory'
  final String progressColorTone; // 'primary', 'secondary', 'surfaceTint'

  const StudentCourseProgress({
    required this.id,
    required this.title,
    required this.lastLesson,
    required this.progressPercent,
    required this.badgeText,
    required this.badgeTone,
    required this.iconName,
    required this.progressColorTone,
  });
}
