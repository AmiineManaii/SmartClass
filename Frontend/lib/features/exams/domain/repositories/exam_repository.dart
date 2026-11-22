import 'dart:typed_data';

import '../entities/exam_attempt.dart';
import '../entities/exam_course_option.dart';
import '../entities/exam_definition.dart';
import '../entities/exam_monitoring.dart';

/// Input accepted by `POST /exams` (manual, import or AI reviewed).
class CreateExamInput {
  const CreateExamInput({
    required this.title,
    required this.classGroupId,
    required this.durationMinutes,
    required this.startsAt,
    required this.endsAt,
    required this.questions,
    required this.source,
    this.description,
    this.settings = const ExamSettings(),
  });

  final String title;
  final String? description;
  final String classGroupId;
  final int durationMinutes;
  final DateTime startsAt;
  final DateTime endsAt;
  final ExamSource source;
  final ExamSettings settings;
  final List<QuestionDraft> questions;

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
    'classGroupId': classGroupId,
    'durationMinutes': durationMinutes,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'source': source.wire,
    'settings': settings.toJson(),
    'questions': questions.map((question) => question.toJson()).toList(),
  };
}

/// Input accepted by `PATCH /exams/:id` (DRAFT only).
class UpdateExamInput {
  const UpdateExamInput({
    required this.title,
    required this.durationMinutes,
    required this.startsAt,
    required this.endsAt,
    required this.questions,
    this.description,
    this.settings = const ExamSettings(),
  });

  final String title;
  final String? description;
  final int durationMinutes;
  final DateTime startsAt;
  final DateTime endsAt;
  final ExamSettings settings;
  final List<QuestionDraft> questions;

  Map<String, dynamic> toJson() => {
    'title': title,
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
    'durationMinutes': durationMinutes,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'settings': settings.toJson(),
    'questions': questions.map((question) => question.toJson()).toList(),
  };
}

/// One answer to autosave.
class StudentAnswerInput {
  const StudentAnswerInput({
    required this.questionId,
    required this.selectedOptionIds,
  });

  final String questionId;
  final List<String> selectedOptionIds;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'selectedOptionIds': selectedOptionIds,
  };
}

/// One anti-fraud signal reported by a client.
class ExamSignalInput {
  const ExamSignalInput({
    required this.type,
    this.durationMs,
    this.source = 'client',
    this.clientOccurredAt,
    this.metadata = const {},
  });

  final ExamEventType type;
  final int? durationMs;
  final String source;
  final DateTime? clientOccurredAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
    'type': type.wire,
    if (durationMs != null) 'durationMs': durationMs,
    'source': source,
    if (clientOccurredAt != null)
      'clientOccurredAt': clientOccurredAt!.toUtc().toIso8601String(),
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

/// Close result (`{ exam, finalizedAttempts }`).
class CloseExamResult {
  const CloseExamResult({required this.exam, required this.finalizedAttempts});

  final ExamDetail exam;
  final int finalizedAttempts;
}

/// Exam bounded-context contract, backed by the real API.
///
/// Correct answers are only ever returned by teacher methods; student methods
/// return [StudentExam] which cannot carry them.
abstract class ExamRepository {
  // Teacher authoring ------------------------------------------------------
  Future<List<ExamSummary>> listMyExams();
  Future<ExamDetail> getTeacherExam(String examId);
  Future<ExamDetail> createExam(CreateExamInput input);
  Future<ExamDetail> updateExam(String examId, UpdateExamInput input);
  Future<ExamDetail> publishExam(String examId);
  Future<CloseExamResult> closeExam(String examId);
  Future<ImportedExamPreview> previewImport({
    required String filename,
    required List<int> bytes,
  });
  /// Published + validated courses the teacher may pick as AI sources.
  Future<List<ExamCourseOption>> listClassCourses(String classGroupId);

  /// Teacher-owned indexed Knowledge Engine documents usable as AI exam sources.
  Future<List<ExamKnowledgeDocumentOption>> listKnowledgeDocuments();

  Future<GeneratedExamPreview> generateWithAi({
    required String classGroupId,
    required List<String> courseIds,
    List<String> chapters = const <String>[],
    List<String> focusTopics = const <String>[],
    List<String> knowledgeDocumentIds = const <String>[],
    bool includeDrafts = false,
    bool balancedCoverage = true,
    String? title,
    required String difficulty,
    required int questionCount,
  });

  // Teacher results / monitoring ------------------------------------------
  Future<ExamResults> getResults(String examId);
  Future<AttemptMonitoring> getAttemptMonitoring({
    required String examId,
    required String attemptId,
  });
  Future<ExamEvent> updateEventState({
    required String examId,
    required String eventId,
    required ExamEventState state,
  });
  Future<Uint8List> downloadRecording({
    required String examId,
    required String recordingId,
  });
  Future<void> deleteRecording({
    required String examId,
    required String recordingId,
  });

  // Student attempt lifecycle ---------------------------------------------
  Future<List<AvailableExam>> listAvailableExams();
  Future<AttemptSession> startAttempt(String examId);
  Future<AttemptSession> getAttempt(String examId);
  Future<SaveAnswersResult> saveAnswers(
    String examId,
    List<StudentAnswerInput> answers,
  );
  Future<SubmitAttemptResult> submitAttempt(String examId);
  Future<StudentResult> getStudentResult(String examId);
  Future<RecordEventResult> reportEvent(String examId, ExamSignalInput input);
  Future<ExamRecording> uploadRecording({
    required String examId,
    required List<int> bytes,
    required String filename,
    required String mimeType,
    String? eventId,
    int? durationMs,
    String kind = 'event_clip',
  });
}
