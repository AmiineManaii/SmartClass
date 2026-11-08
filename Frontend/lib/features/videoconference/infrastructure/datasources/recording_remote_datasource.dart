import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/recording_models.dart';

class RecordingRemoteDataSource {
  final ApiClient _client;

  RecordingRemoteDataSource(this._client);

  String buildAuthenticatedStreamUrl(String relativePath, String? accessToken) {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    if (accessToken != null && accessToken.isNotEmpty) {
      final sep = path.contains('?') ? '&' : '?';
      return '$base$path${sep}token=${Uri.encodeQueryComponent(accessToken)}';
    }
    return '$base$path';
  }

  String buildAuthenticatedFrameUrl(
    String sessionId,
    int frameIndex,
    String? accessToken,
  ) {
    return buildAuthenticatedStreamUrl(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/recording/frames/$frameIndex',
      accessToken,
    );
  }

  Future<SessionRecordingEntity> startRecording(String sessionId) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/recording/start',
    );
    return SessionRecordingEntity.fromJson(apiEnvelope(res));
  }

  Future<SessionRecordingEntity> stopRecording(
    String sessionId, {
    Map<String, dynamic>? capturePayload,
  }) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/recording/stop',
      data: capturePayload ?? const <String, dynamic>{},
    );
    return SessionRecordingEntity.fromJson(apiEnvelope(res));
  }

  Future<SessionRecordingEntity?> getRecording(String sessionId) async {
    try {
      final res = await _client.get<dynamic>(
        '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/recording',
      );
      return SessionRecordingEntity.fromJson(apiEnvelope(res));
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<SessionRecordingEntity>> listRecordings({
    String? classGroupId,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (classGroupId != null && classGroupId.isNotEmpty) {
      query['classGroupId'] = classGroupId;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/recordings',
      queryParameters: query,
    );
    final list = apiListEnvelope(res);
    return list
        .whereType<Map<String, dynamic>>()
        .map(SessionRecordingEntity.fromJson)
        .toList();
  }

  Future<SessionRecordingEntity> retryProcessing(String sessionId) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/recording/retry',
    );
    return SessionRecordingEntity.fromJson(apiEnvelope(res));
  }

  Future<SessionRecordingEntity> uploadSourceDocument({
    required String sessionId,
    required String title,
    String? contentText,
    String? fileBase64,
  }) async {
    final data = <String, dynamic>{'title': title};
    if (contentText != null && contentText.isNotEmpty) {
      data['contentText'] = contentText;
    }
    if (fileBase64 != null && fileBase64.isNotEmpty) {
      data['fileBase64'] = fileBase64;
    }
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/recording/source-document',
      data: data,
    );
    return SessionRecordingEntity.fromJson(apiEnvelope(res));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Teacher Review & Publishing Studio
  // ───────────────────────────────────────────────────────────────────────────

  Future<TeacherReviewWorkspaceEntity> getTeacherReviewWorkspace(
    String sessionId,
  ) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/review',
    );
    return TeacherReviewWorkspaceEntity.fromJson(apiEnvelope(res));
  }

  Future<TeacherReviewWorkspaceEntity> updateTeacherReview({
    required String sessionId,
    required Map<String, dynamic> payload,
  }) async {
    final body = Map<String, dynamic>.from(payload);
    if (body['detailedSummary'] != null && body['generalSummary'] == null) {
      body['generalSummary'] = body['detailedSummary'];
    }
    if (body['structuredMarkdown'] != null && body['structuredNotes'] == null) {
      body['structuredNotes'] = body['structuredMarkdown'];
    }
    body.remove('detailedSummary');
    body.remove('structuredMarkdown');
    final res = await _client.patch<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/review',
      data: body,
    );
    return TeacherReviewWorkspaceEntity.fromJson(apiEnvelope(res));
  }

  Future<TeacherReviewWorkspaceEntity> regenerateLessonSection({
    required String sessionId,
    required String section,
    String? instructions,
  }) async {
    final data = <String, dynamic>{'section': section};
    if (instructions != null && instructions.trim().isNotEmpty) {
      data['instructions'] = instructions.trim();
    }
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/review/regenerate',
      data: data,
    );
    return TeacherReviewWorkspaceEntity.fromJson(apiEnvelope(res));
  }

  Future<SessionRecordingEntity> approveLessonPackage(String sessionId) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/review/approve',
    );
    return SessionRecordingEntity.fromJson(apiEnvelope(res));
  }

  Future<SessionRecordingEntity> publishLessonPackage(String sessionId) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/review/publish',
    );
    return SessionRecordingEntity.fromJson(apiEnvelope(res));
  }

  Future<SessionRecordingEntity> unpublishLessonPackage(
    String sessionId,
  ) async {
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/review/unpublish',
    );
    return SessionRecordingEntity.fromJson(apiEnvelope(res));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Student Lecture Learning Workspace, Study Lab & AI Tutor
  // ───────────────────────────────────────────────────────────────────────────

  Future<StudentLessonWorkspaceEntity> getStudentWorkspace(
    String sessionId,
  ) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace',
    );
    return StudentLessonWorkspaceEntity.fromJson(apiEnvelope(res));
  }

  Future<List<LessonSearchHitEntity>> searchLessonContent(
    String sessionId,
    String query,
  ) async {
    final res = await _client.get<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/search',
      queryParameters: {'q': query},
    );
    final list = apiListEnvelope(res);
    return list
        .whereType<Map<String, dynamic>>()
        .map(LessonSearchHitEntity.fromJson)
        .toList();
  }

  Future<void> updateStudentProgress({
    required String sessionId,
    int? lastPositionSeconds,
    int? watchedSeconds,
    List<String>? completedChapters,
    List<String>? flashcardKnownIds,
    List<String>? flashcardReviewIds,
  }) async {
    final data = <String, dynamic>{};
    if (lastPositionSeconds != null) {
      data['lastPositionSeconds'] = lastPositionSeconds;
    }
    if (watchedSeconds != null) data['watchedSeconds'] = watchedSeconds;
    if (completedChapters != null) {
      data['completedChapters'] = completedChapters;
    }
    if (flashcardKnownIds != null) {
      data['flashcardKnownIds'] = flashcardKnownIds;
    }
    if (flashcardReviewIds != null) {
      data['flashcardReviewIds'] = flashcardReviewIds;
    }
    await _client.put<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/progress',
      data: data,
    );
  }

  Future<StudentBookmarkEntity> createBookmark({
    required String sessionId,
    double? timestampSec,
    int? timestampSeconds,
    required String label,
    String? chapterTitle,
  }) async {
    final ts = timestampSeconds ?? (timestampSec?.round() ?? 0);
    final data = <String, dynamic>{
      'timestampSeconds': ts,
      'label': label,
    };
    if (chapterTitle != null) data['chapterTitle'] = chapterTitle;
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/bookmarks',
      data: data,
    );
    return StudentBookmarkEntity.fromJson(apiEnvelope(res));
  }

  Future<void> deleteBookmark({
    required String sessionId,
    required String bookmarkId,
  }) async {
    await _client.delete<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/bookmarks/$bookmarkId',
    );
  }

  Future<StudentNoteEntity> upsertPersonalNote({
    required String sessionId,
    double? timestampSec,
    int? timestampSeconds,
    required String content,
    String? highlightText,
    String? chapterTitle,
  }) async {
    final ts = timestampSeconds ?? timestampSec?.round();
    final data = <String, dynamic>{'content': content};
    if (ts != null) data['timestampSeconds'] = ts;
    if (highlightText != null) data['highlightText'] = highlightText;
    if (chapterTitle != null) data['chapterTitle'] = chapterTitle;
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/notes',
      data: data,
    );
    return StudentNoteEntity.fromJson(apiEnvelope(res));
  }

  Future<void> deleteNote({
    required String sessionId,
    required String noteId,
  }) async {
    await _client.delete<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/notes/$noteId',
    );
  }

  Future<StudentStudyArtifactEntity> generateStudyArtifact({
    required String sessionId,
    String? artifactType,
    String? kind,
    String? style,
    String? summaryMode,
    String? chapterTitle,
    String? difficulty,
    String? language,
    int? count,
  }) async {
    final resolvedKind = artifactType ?? kind ?? 'SUMMARY';
    final data = <String, dynamic>{'kind': resolvedKind};
    final mode = style ?? summaryMode;
    if (mode != null) data['summaryMode'] = mode;
    if (difficulty != null) {
      final normalizedDiff = switch (difficulty.toLowerCase()) {
        'easy' => 'facile',
        'medium' => 'moyen',
        'hard' => 'difficile',
        _ => difficulty.toLowerCase(),
      };
      data['difficulty'] = normalizedDiff;
    }
    if (chapterTitle != null && chapterTitle.isNotEmpty) {
      data['chapterTitle'] = chapterTitle;
    }
    if (language != null && language.isNotEmpty) {
      data['language'] = language;
    }
    if (count != null) {
      if (resolvedKind == 'FLASHCARDS') {
        data['flashcardCount'] = count;
      } else if (resolvedKind == 'QUIZ') {
        data['questionCount'] = count;
      }
    }
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/study-artifacts',
      data: data,
    );
    return StudentStudyArtifactEntity.fromJson(apiEnvelope(res));
  }

  Future<StudentQuizAttemptEntity> submitQuizAttempt({
    required String sessionId,
    String? artifactId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final data = <String, dynamic>{'answers': answers};
    if (artifactId != null) data['artifactId'] = artifactId;
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/quiz-attempts',
      data: data,
    );
    return StudentQuizAttemptEntity.fromJson(apiEnvelope(res));
  }

  Future<LessonTutorMessageEntity> askLessonTutor({
    required String sessionId,
    required String question,
    double? currentTimestampSec,
    String? style,
    String? conversationId,
  }) async {
    final data = <String, dynamic>{'question': question};
    if (conversationId != null) data['conversationId'] = conversationId;
    if (currentTimestampSec != null) {
      data['currentTimestampSeconds'] = currentTimestampSec.round();
    }
    if (style != null) data['responseStyle'] = style;
    final res = await _client.post<dynamic>(
      '${ApiConfig.apiPrefix}/videoconference/sessions/$sessionId/workspace/tutor/ask',
      data: data,
    );
    final env = apiEnvelope(res);
    if (env['assistantMessage'] is Map<String, dynamic>) {
      return LessonTutorMessageEntity.fromJson(
        env['assistantMessage'] as Map<String, dynamic>,
      );
    }
    return LessonTutorMessageEntity.fromJson(env);
  }
}
