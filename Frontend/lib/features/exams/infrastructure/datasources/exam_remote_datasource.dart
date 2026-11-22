import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';

/// One method per exam-bound backend endpoint
/// (`contracts/exams.openapi.yaml`, base `/api/v1`).
/// Returns raw envelope contents; parsing lives in `../models/exam_models.dart`.
class ExamRemoteDataSource {
  ExamRemoteDataSource(this._client);

  final ApiClient _client;

  static String get _base => ApiConfig.apiPrefix;

  static List<dynamic> _dataList(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List).toList();
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  // Teacher authoring ------------------------------------------------------

  Future<List<dynamic>> listMyExams() async {
    final res = await _client.get<dynamic>('$_base/exams/mine');
    return _dataList(res);
  }

  Future<Map<String, dynamic>> getTeacherExam(String examId) async {
    final res = await _client.get<dynamic>('$_base/exams/$examId');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> createExam(Map<String, dynamic> body) async {
    final res = await _client.post<dynamic>('$_base/exams', data: body);
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> updateExam(
    String examId,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.patch<dynamic>(
      '$_base/exams/$examId',
      data: body,
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> publishExam(String examId) async {
    final res = await _client.patch<dynamic>('$_base/exams/$examId/publish');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> closeExam(String examId) async {
    final res = await _client.patch<dynamic>('$_base/exams/$examId/close');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> previewImport({
    required String filename,
    required List<int> bytes,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _client.post<dynamic>(
      '$_base/exams/import',
      data: form,
    );
    return apiEnvelope(res);
  }

  /// Published + validated courses of one class (AI source picker).
  Future<List<dynamic>> classCourses(String classGroupId) async {
    final res = await _client.get<dynamic>(
      '$_base/exams/classes/$classGroupId/courses',
    );
    return _dataList(res);
  }

  /// Authenticated teacher's indexed Knowledge Engine documents (e.g. recorded lectures).
  Future<List<dynamic>> listTeacherKnowledgeDocuments({int limit = 50}) async {
    final res = await _client.get<dynamic>(
      '$_base/knowledge/documents',
      queryParameters: <String, dynamic>{'page': 1, 'limit': limit},
    );
    return _dataList(res);
  }

  Future<Map<String, dynamic>> generateWithAi(Map<String, dynamic> body) async {
    final res = await _client.post<dynamic>(
      '$_base/exams/ai/generate',
      data: body,
      // Local model generation takes minutes; the default 3 min receive
      // timeout aborted the request and surfaced as a fake network error.
      receiveTimeout: ApiConfig.aiGenerationTimeout,
    );
    return apiEnvelope(res);
  }

  // Teacher results / monitoring -------------------------------------------

  Future<Map<String, dynamic>> getResults(String examId) async {
    final res = await _client.get<dynamic>('$_base/exams/$examId/results');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> getAttemptMonitoring({
    required String examId,
    required String attemptId,
  }) async {
    final res = await _client.get<dynamic>(
      '$_base/exams/$examId/attempts/$attemptId',
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> updateEventState({
    required String examId,
    required String eventId,
    required String state,
  }) async {
    final res = await _client.patch<dynamic>(
      '$_base/exams/$examId/events/$eventId',
      data: {'state': state},
    );
    return apiEnvelope(res);
  }

  Future<Uint8List> downloadRecording({
    required String examId,
    required String recordingId,
  }) async {
    final bytes = await _client.getBytes(
      '$_base/exams/$examId/recordings/$recordingId/stream',
    );
    return Uint8List.fromList(bytes);
  }

  Future<void> deleteRecording({
    required String examId,
    required String recordingId,
  }) async {
    await _client.delete<dynamic>(
      '$_base/exams/$examId/recordings/$recordingId',
    );
  }

  // Student attempt lifecycle -----------------------------------------------

  Future<List<dynamic>> listAvailableExams() async {
    final res = await _client.get<dynamic>('$_base/exams/available');
    return _dataList(res);
  }

  Future<Map<String, dynamic>> startAttempt(String examId) async {
    final res = await _client.post<dynamic>('$_base/exams/$examId/start');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> getAttempt(String examId) async {
    final res = await _client.get<dynamic>('$_base/exams/$examId/attempt');
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> saveAnswers(
    String examId,
    List<Map<String, dynamic>> answers,
  ) async {
    final res = await _client.put<dynamic>(
      '$_base/exams/$examId/attempt/answers',
      data: {'answers': answers},
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> submitAttempt(String examId) async {
    final res = await _client.post<dynamic>(
      '$_base/exams/$examId/attempt/submit',
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> getStudentResult(String examId) async {
    final res = await _client.get<dynamic>(
      '$_base/exams/$examId/attempt/result',
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> reportEvent(
    String examId,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.post<dynamic>(
      '$_base/exams/$examId/attempt/events',
      data: body,
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> uploadRecording({
    required String examId,
    required List<int> bytes,
    required String filename,
    required String mimeType,
    String? eventId,
    int? durationMs,
    String kind = 'event_clip',
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(mimeType),
      ),
      if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
      'durationMs': ?durationMs,
      'kind': kind,
    });
    final res = await _client.post<dynamic>(
      '$_base/exams/$examId/attempt/recordings',
      data: form,
    );
    return apiEnvelope(res);
  }
}
