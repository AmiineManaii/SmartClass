/// Homework assigned by the teacher, displayed on the student side.
///
/// Pure Dart — no Flutter dependency.
///
/// Source of truth (planned): exams/assignments endpoints (contracts not
/// yet written). Until they land the provider resolves to an empty list
/// and the section renders its empty state — no invented homework.
class StudentAssignment {
  final String id;
  final String title;
  final int? questionsCount;
  final int? estDurationMinutes;
  final String deadlineText;
  final bool isUrgent;
  final String? weightNote;
  final String actionType; // 'start', 'deposit', 'none'
  final String iconName; // 'assignment_late', 'code_blocks', 'functions'
  final bool hasAutoAiValidation;
  final String? submissionType;
  final String? extraDetails;

  const StudentAssignment({
    required this.id,
    required this.title,
    this.questionsCount,
    this.estDurationMinutes,
    required this.deadlineText,
    this.isUrgent = false,
    this.weightNote,
    required this.actionType,
    required this.iconName,
    this.hasAutoAiValidation = false,
    this.submissionType,
    this.extraDetails,
  });
}
