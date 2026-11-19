import 'exam_definition.dart';

/// Availability computed server-side for `GET /exams/available`.
enum ExamAvailability {
  upcoming('UPCOMING'),
  active('ACTIVE'),
  ended('ENDED'),
  closed('CLOSED');

  const ExamAvailability(this.wire);

  final String wire;

  static ExamAvailability fromWire(String? value) {
    return ExamAvailability.values.firstWhere(
      (availability) => availability.wire == value,
      orElse: () => ExamAvailability.ended,
    );
  }
}

/// Attempt lifecycle state. The backend is the only writer.
enum AttemptStatus {
  inProgress('IN_PROGRESS'),
  submitted('SUBMITTED'),
  autoSubmitted('AUTO_SUBMITTED'),
  terminated('TERMINATED');

  const AttemptStatus(this.wire);

  final String wire;

  bool get isCompleted => this != AttemptStatus.inProgress;

  static AttemptStatus? fromWire(String? value) {
    if (value == null) return null;
    return AttemptStatus.values.firstWhere(
      (status) => status.wire == value,
      orElse: () => AttemptStatus.terminated,
    );
  }
}

/// Published exam addressed to the student's class, with attempt state.
class AvailableExam extends ExamSummary {
  const AvailableExam({
    required super.id,
    required super.title,
    required super.classGroupId,
    required super.authorId,
    required super.durationMinutes,
    required super.startsAt,
    required super.endsAt,
    required super.status,
    required super.source,
    required super.settings,
    required super.questionCount,
    required super.totalPoints,
    required super.createdAt,
    required super.updatedAt,
    required this.availability,
    required this.canStart,
    required this.canResume,
    this.attemptStatus,
    this.remainingMs,
    super.description,
    super.className,
  });

  final ExamAvailability availability;
  final AttemptStatus? attemptStatus;
  final bool canStart;
  final bool canResume;
  final int? remainingMs;
}

/// Server-owned attempt state (`StudentAttempt`).
class StudentAttempt {
  const StudentAttempt({
    required this.id,
    required this.examId,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.remainingMs,
    required this.violationCount,
    this.submittedAt,
    this.terminatedReason,
  });

  final String id;
  final String examId;
  final AttemptStatus status;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? submittedAt;

  /// Authoritative remaining time at the moment the response was produced.
  final int remainingMs;
  final int violationCount;
  final String? terminatedReason;

  bool get isActive => status == AttemptStatus.inProgress;
}

/// Saved answer (`StudentAnswer`).
class StudentAnswer {
  const StudentAnswer({
    required this.questionId,
    required this.selectedOptionIds,
    required this.savedAt,
  });

  final String questionId;
  final List<String> selectedOptionIds;
  final DateTime savedAt;
}

/// Student-safe exam projection (`StudentExam`).
class StudentExam {
  const StudentExam({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.settings,
    required this.questionCount,
    required this.totalPoints,
    required this.questions,
    required this.serverNow,
    this.description,
    this.className,
  });

  final String id;
  final String title;
  final String? description;
  final String? className;
  final int durationMinutes;
  final DateTime startsAt;
  final DateTime endsAt;
  final ExamStatus status;
  final ExamSettings settings;
  final int questionCount;
  final int totalPoints;
  final List<StudentQuestion> questions;

  /// Server clock sample; the exam page derives the countdown from it.
  final DateTime serverNow;
}

/// `AttemptSession` returned by start/resume.
class AttemptSession {
  const AttemptSession({
    required this.exam,
    required this.attempt,
    required this.answers,
    required this.resumed,
    required this.canResume,
    required this.serverNow,
  });

  final StudentExam exam;
  final StudentAttempt attempt;
  final List<StudentAnswer> answers;
  final bool resumed;
  final bool canResume;
  final DateTime serverNow;
}

/// `SaveAnswersResponse`.
class SaveAnswersResult {
  const SaveAnswersResult({
    required this.savedAt,
    required this.answers,
    required this.remainingMs,
    required this.serverNow,
  });

  final DateTime savedAt;
  final List<StudentAnswer> answers;
  final int remainingMs;
  final DateTime serverNow;
}

/// `SubmitAttemptResponse`.
class SubmitAttemptResult {
  const SubmitAttemptResult({
    required this.attempt,
    required this.autoSubmitted,
    required this.serverNow,
  });

  final StudentAttempt attempt;
  final bool autoSubmitted;
  final DateTime serverNow;
}

/// Per-question correctness in the released student result.
class StudentResultItem {
  const StudentResultItem({
    required this.questionId,
    required this.selectedOptionIds,
    required this.correct,
    required this.pointsAwarded,
    required this.pointsMax,
  });

  final String questionId;
  final List<String> selectedOptionIds;
  final bool correct;
  final num pointsAwarded;
  final int pointsMax;
}

/// `StudentResult` — never contains correct option ids or explanations.
class StudentResult {
  const StudentResult({
    required this.examId,
    required this.examTitle,
    required this.status,
    required this.score,
    required this.maxScore,
    required this.correctCount,
    required this.questionCount,
    required this.items,
    this.submittedAt,
    this.terminatedReason,
  });

  final String examId;
  final String examTitle;
  final AttemptStatus status;
  final num score;
  final num maxScore;
  final int correctCount;
  final int questionCount;
  final DateTime? submittedAt;
  final String? terminatedReason;
  final List<StudentResultItem> items;
}

/// One row of the teacher results table (`ExamResultEntry`).
class ExamResultEntry {
  const ExamResultEntry({
    required this.attemptId,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.maxScore,
    required this.correctCount,
    required this.questionCount,
    required this.violationCount,
    this.score,
    this.submittedAt,
  });

  final String attemptId;
  final String studentId;
  final String studentName;
  final AttemptStatus status;
  final num? score;
  final num maxScore;
  final int correctCount;
  final int questionCount;
  final DateTime? submittedAt;
  final int violationCount;
}

/// `ExamResults` aggregate for one exam.
class ExamResults {
  const ExamResults({
    required this.examId,
    required this.examTitle,
    required this.status,
    required this.attemptCount,
    required this.results,
    this.averageScore,
  });

  final String examId;
  final String examTitle;
  final ExamStatus status;
  final int attemptCount;
  final num? averageScore;
  final List<ExamResultEntry> results;
}
