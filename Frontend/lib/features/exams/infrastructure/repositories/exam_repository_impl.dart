import 'dart:typed_data';

import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_course_option.dart';
import '../../domain/entities/exam_definition.dart';
import '../../domain/entities/exam_monitoring.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_remote_datasource.dart';
import '../models/exam_models.dart';

/// [ExamRepository] backed by the real API. Never fabricates an attempt,
/// a score or a recording: missing data stays missing.
class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl({required this.remote});

  final ExamRemoteDataSource remote;

  @override
  Future<List<ExamSummary>> listMyExams() async {
    final items = await remote.listMyExams();
    return items.map(asMap).map(examSummaryFromJson).toList();
  }

  @override
  Future<ExamDetail> getTeacherExam(String examId) async {
    return examDetailFromJson(await remote.getTeacherExam(examId));
  }

  @override
  Future<ExamDetail> createExam(CreateExamInput input) async {
    return examDetailFromJson(await remote.createExam(input.toJson()));
  }

  @override
  Future<ExamDetail> updateExam(String examId, UpdateExamInput input) async {
    return examDetailFromJson(await remote.updateExam(examId, input.toJson()));
  }

  @override
  Future<ExamDetail> publishExam(String examId) async {
    return examDetailFromJson(await remote.publishExam(examId));
  }

  @override
  Future<CloseExamResult> closeExam(String examId) async {
    final data = await remote.closeExam(examId);
    return CloseExamResult(
      exam: examDetailFromJson(asMap(data['exam'])),
      finalizedAttempts: parseInt(data['finalizedAttempts']),
    );
  }

  @override
  Future<ImportedExamPreview> previewImport({
    required String filename,
    required List<int> bytes,
  }) async {
    return importedPreviewFromJson(
      await remote.previewImport(filename: filename, bytes: bytes),
    );
  }

  @override
  Future<List<ExamCourseOption>> listClassCourses(String classGroupId) async {
    final items = await remote.classCourses(classGroupId);
    return items
        .map(asMap)
        .map(
          (json) => ExamCourseOption(
            id: (json['id'] as String?) ?? '',
            title: (json['title'] as String?) ?? '',
            subject: (json['subject'] as String?)?.trim(),
          ),
        )
        .where((course) => course.id.isNotEmpty && course.title.isNotEmpty)
        .toList();
  }

  @override
  Future<GeneratedExamPreview> generateWithAi({
    required String classGroupId,
    required List<String> courseIds,
    String? title,
    required String difficulty,
    required int questionCount,
  }) async {
    final data = await remote.generateWithAi({
      'classGroupId': classGroupId,
      'courseIds': courseIds,
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      'difficulty': difficulty,
      'questionCount': questionCount,
    });
    return generatedPreviewFromJson(data);
  }

  @override
  Future<ExamResults> getResults(String examId) async {
    return examResultsFromJson(await remote.getResults(examId));
  }

  @override
  Future<AttemptMonitoring> getAttemptMonitoring({
    required String examId,
    required String attemptId,
  }) async {
    return attemptMonitoringFromJson(
      await remote.getAttemptMonitoring(examId: examId, attemptId: attemptId),
    );
  }

  @override
  Future<ExamEvent> updateEventState({
    required String examId,
    required String eventId,
    required ExamEventState state,
  }) async {
    return examEventFromJson(
      await remote.updateEventState(
        examId: examId,
        eventId: eventId,
        state: state.wire,
      ),
    );
  }

  @override
  Future<Uint8List> downloadRecording({
    required String examId,
    required String recordingId,
  }) {
    return remote.downloadRecording(
      examId: examId,
      recordingId: recordingId,
    );
  }

  @override
  Future<void> deleteRecording({
    required String examId,
    required String recordingId,
  }) {
    return remote.deleteRecording(examId: examId, recordingId: recordingId);
  }

  @override
  Future<List<AvailableExam>> listAvailableExams() async {
    final items = await remote.listAvailableExams();
    return items.map(asMap).map(availableExamFromJson).toList();
  }

  @override
  Future<AttemptSession> startAttempt(String examId) async {
    return attemptSessionFromJson(await remote.startAttempt(examId));
  }

  @override
  Future<AttemptSession> getAttempt(String examId) async {
    return attemptSessionFromJson(await remote.getAttempt(examId));
  }

  @override
  Future<SaveAnswersResult> saveAnswers(
    String examId,
    List<StudentAnswerInput> answers,
  ) async {
    return saveAnswersFromJson(
      await remote.saveAnswers(
        examId,
        answers.map((answer) => answer.toJson()).toList(),
      ),
    );
  }

  @override
  Future<SubmitAttemptResult> submitAttempt(String examId) async {
    return submitAttemptFromJson(await remote.submitAttempt(examId));
  }

  @override
  Future<StudentResult> getStudentResult(String examId) async {
    return studentResultFromJson(await remote.getStudentResult(examId));
  }

  @override
  Future<RecordEventResult> reportEvent(
    String examId,
    ExamSignalInput input,
  ) async {
    return recordEventFromJson(await remote.reportEvent(examId, input.toJson()));
  }

  @override
  Future<ExamRecording> uploadRecording({
    required String examId,
    required List<int> bytes,
    required String filename,
    required String mimeType,
    String? eventId,
    int? durationMs,
    String kind = 'event_clip',
  }) async {
    return examRecordingFromJson(
      await remote.uploadRecording(
        examId: examId,
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
        eventId: eventId,
        durationMs: durationMs,
        kind: kind,
      ),
    );
  }
}
