/// Exam definition models (pure Dart).
///
/// Shapes mirror `contracts/exams.openapi.yaml` (`ExamSummary`,
/// `ExamDetail`, `TeacherQuestion`, `StudentQuestion`, `ImportedExamPreview`,
/// `GeneratedExamPreview`). Correct answers only exist on teacher projections:
/// [StudentQuestion] deliberately has no `correctOptionIds` or `explanation`.
enum ExamStatus {
  draft('DRAFT'),
  published('PUBLISHED'),
  closed('CLOSED');

  const ExamStatus(this.wire);

  final String wire;

  static ExamStatus fromWire(String? value) {
    return ExamStatus.values.firstWhere(
      (status) => status.wire == value,
      orElse: () => ExamStatus.draft,
    );
  }
}

enum ExamSource {
  manual('MANUAL'),
  import('IMPORT'),
  ai('AI');

  const ExamSource(this.wire);

  final String wire;

  static ExamSource fromWire(String? value) {
    return ExamSource.values.firstWhere(
      (source) => source.wire == value,
      orElse: () => ExamSource.manual,
    );
  }
}

enum ExamQuestionType {
  singleChoice('SINGLE_CHOICE');

  const ExamQuestionType(this.wire);

  final String wire;

  static ExamQuestionType fromWire(String? value) {
    return ExamQuestionType.values.firstWhere(
      (type) => type.wire == value,
      orElse: () => ExamQuestionType.singleChoice,
    );
  }
}

/// Server-owned exam settings (`ExamSettings` + `ExamSettingsInput`).
class ExamSettings {
  const ExamSettings({
    this.shuffleQuestions = false,
    this.requireCamera = false,
    this.allowQuestionSkip = true,
    this.showResultsAfterClose = true,
    this.maxViolationCount = 3,
  });

  final bool shuffleQuestions;
  final bool requireCamera;
  final bool allowQuestionSkip;
  final bool showResultsAfterClose;
  final int maxViolationCount;

  ExamSettings copyWith({
    bool? shuffleQuestions,
    bool? requireCamera,
    bool? allowQuestionSkip,
    bool? showResultsAfterClose,
    int? maxViolationCount,
  }) {
    return ExamSettings(
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      requireCamera: requireCamera ?? this.requireCamera,
      allowQuestionSkip: allowQuestionSkip ?? this.allowQuestionSkip,
      showResultsAfterClose: showResultsAfterClose ?? this.showResultsAfterClose,
      maxViolationCount: maxViolationCount ?? this.maxViolationCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'shuffleQuestions': shuffleQuestions,
    'requireCamera': requireCamera,
    'allowQuestionSkip': allowQuestionSkip,
    'showResultsAfterClose': showResultsAfterClose,
    'maxViolationCount': maxViolationCount,
  };
}

/// One answer option. Ids are normalized server-side (A, B, C...).
class ExamOption {
  const ExamOption({required this.id, required this.text});

  final String id;
  final String text;
}

/// Teacher question: carries the correction (teacher-only endpoints).
class TeacherQuestion {
  const TeacherQuestion({
    required this.id,
    required this.examId,
    required this.order,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctOptionIds,
    required this.points,
    this.hint,
    this.explanation,
  });

  final String id;
  final String examId;
  final int order;
  final ExamQuestionType type;
  final String prompt;
  final String? hint;
  final List<ExamOption> options;
  final List<String> correctOptionIds;
  final String? explanation;
  final int points;
}

/// Student question: never carries correct ids or explanations.
class StudentQuestion {
  const StudentQuestion({
    required this.id,
    required this.order,
    required this.type,
    required this.prompt,
    required this.options,
    required this.points,
    this.hint,
  });

  final String id;
  final int order;
  final ExamQuestionType type;
  final String prompt;
  final String? hint;
  final List<ExamOption> options;
  final int points;
}

/// Exam list row (`ExamSummary`).
class ExamSummary {
  const ExamSummary({
    required this.id,
    required this.title,
    required this.classGroupId,
    required this.authorId,
    required this.durationMinutes,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.source,
    required this.settings,
    required this.questionCount,
    required this.totalPoints,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.className,
  });

  final String id;
  final String title;
  final String? description;
  final String classGroupId;
  final String? className;
  final String authorId;
  final int durationMinutes;
  final DateTime startsAt;
  final DateTime endsAt;
  final ExamStatus status;
  final ExamSource source;
  final ExamSettings settings;
  final int questionCount;
  final int totalPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDraft => status == ExamStatus.draft;
  bool get isPublished => status == ExamStatus.published;
  bool get isClosed => status == ExamStatus.closed;
}

/// Teacher exam detail (`ExamDetail` = summary + questions).
class ExamDetail extends ExamSummary {
  const ExamDetail({
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
    required this.questions,
    super.description,
    super.className,
  });

  final List<TeacherQuestion> questions;
}

/// Editable question draft, shared by manual authoring, import and AI previews.
class QuestionDraft {
  const QuestionDraft({
    required this.prompt,
    required this.options,
    required this.correctOptionIds,
    this.hint,
    this.explanation,
    this.points = 1,
  });

  final String prompt;
  final String? hint;
  final List<ExamOption> options;
  final List<String> correctOptionIds;
  final String? explanation;
  final int points;

  factory QuestionDraft.fromTeacherQuestion(TeacherQuestion question) {
    return QuestionDraft(
      prompt: question.prompt,
      hint: question.hint,
      options: question.options,
      correctOptionIds: question.correctOptionIds,
      explanation: question.explanation,
      points: question.points,
    );
  }

  QuestionDraft copyWith({
    String? prompt,
    String? Function()? hint,
    List<ExamOption>? options,
    List<String>? correctOptionIds,
    String? Function()? explanation,
    int? points,
  }) {
    return QuestionDraft(
      prompt: prompt ?? this.prompt,
      hint: hint != null ? hint() : this.hint,
      options: options ?? this.options,
      correctOptionIds: correctOptionIds ?? this.correctOptionIds,
      explanation: explanation != null ? explanation() : this.explanation,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    if (hint != null && hint!.trim().isNotEmpty) 'hint': hint!.trim(),
    'options': options
        .map((option) => {'id': option.id, 'text': option.text})
        .toList(),
    'correctOptionIds': correctOptionIds,
    if (explanation != null && explanation!.trim().isNotEmpty)
      'explanation': explanation!.trim(),
    'points': points,
  };
}

/// Result of `POST /exams/import` (preview only, never persisted).
class ImportedExamPreview {
  const ImportedExamPreview({
    required this.title,
    required this.sourceFormat,
    required this.questions,
    this.description,
  });

  final String title;
  final String? description;
  final String sourceFormat;
  final List<QuestionDraft> questions;
}

/// Result of `POST /exams/ai/generate` (preview only, never published).
class GeneratedExamPreview {
  const GeneratedExamPreview({
    required this.title,
    required this.questions,
    required this.model,
    this.description,
  });

  final String title;
  final String? description;
  final List<QuestionDraft> questions;

  /// Exact local model that produced the preview.
  final String model;
}
