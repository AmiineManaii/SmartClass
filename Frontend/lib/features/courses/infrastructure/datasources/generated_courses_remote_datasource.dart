import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/course_outline.dart';
import '../../domain/entities/course_study.dart';
import '../../domain/entities/generated_course.dart';

/// Teacher-generated course library (`contracts/courses.openapi.yaml`).
///
/// Generations are saved as DRAFT (author + admins only); validating them
/// (PUBLISHED) exposes them to every authenticated user, students included.
/// Returns raw envelope contents; pages map failures via `failureL10n`.
class GeneratedCoursesRemoteDataSource {
  GeneratedCoursesRemoteDataSource(this._client);

  final ApiClient _client;

  static String get _base => ApiConfig.apiPrefix;

  List<GeneratedCourse> _toList(dynamic body) {
    if (body is Map<String, dynamic> && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(GeneratedCourse.fromJson)
          .toList();
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  GeneratedCourse _toOne(dynamic body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return GeneratedCourse.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  /// Saves a generation as DRAFT (TEACHER or ADMIN).
  ///
  /// [outline] attaches the teacher-validated plan (strict schema: the key
  /// is omitted entirely when null) — the section-by-section builder
  /// materializes its chapters from it on first open.
  Future<GeneratedCourse> saveDraft({
    required String title,
    String? subject,
    required String content,
    required String level,
    required String difficulty,
    required String format,
    CourseOutline? outline,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/courses',
      data: {
        'title': title,
        if (subject != null && subject.trim().isNotEmpty)
          'subject': subject.trim(),
        'content': content,
        'level': level,
        'difficulty': difficulty,
        'format': format,
        if (outline != null) 'outline': outline.toJson(),
      },
    );
    return _toOne(res.data);
  }

  /// Own courses, drafts + published mixed (TEACHER or ADMIN).
  Future<List<GeneratedCourse>> myCourses() async {
    final res = await _client.get<dynamic>('$_base/courses/mine');
    return _toList(res.data);
  }

  /// Validated courses (any authenticated role, students included).
  Future<List<GeneratedCourse>> publishedCourses() async {
    final res = await _client.get<dynamic>('$_base/courses/published');
    return _toList(res.data);
  }

  /// Full course with Markdown body (published: everyone; draft: author/admin).
  Future<GeneratedCourse> getCourse(String id) async {
    final res = await _client.get<dynamic>('$_base/courses/$id');
    return _toOne(res.data);
  }

  /// Validates a draft so every user can read it (author or ADMIN).
  Future<GeneratedCourse> publish(String id) async {
    final res = await _client.patch<dynamic>('$_base/courses/$id/publish');
    return _toOne(res.data);
  }

  /// Returns a course to DRAFT (author or ADMIN).
  Future<GeneratedCourse> unpublish(String id) async {
    final res = await _client.patch<dynamic>('$_base/courses/$id/unpublish');
    return _toOne(res.data);
  }

  /// Updates an existing course draft (author or ADMIN).
  Future<GeneratedCourse> updateCourse({
    required String id,
    String? title,
    String? subject,
    String? content,
    String? level,
    String? difficulty,
    String? format,
  }) async {
    final res = await _client.patch<dynamic>(
      '$_base/courses/$id',
      data: {
        // ignore: use_null_aware_elements
        if (title != null) 'title': title,
        // ignore: use_null_aware_elements
        if (subject != null) 'subject': subject,
        // ignore: use_null_aware_elements
        if (content != null) 'content': content,
        // ignore: use_null_aware_elements
        if (level != null) 'level': level,
        // ignore: use_null_aware_elements
        if (difficulty != null) 'difficulty': difficulty,
        // ignore: use_null_aware_elements
        if (format != null) 'format': format,
      },
    );
    return _toOne(res.data);
  }

  /// Deletes a course (author or ADMIN).
  Future<void> deleteCourse(String id) async {
    await _client.delete<dynamic>('$_base/courses/$id');
  }

  // ── Student study workspace ──────────────────────────────────────────
  // Summaries, flashcards and the course-scoped tutor. All artifacts are
  // private to the caller; off-course tutor questions are refused by the
  // backend (`inScope: false`), never answered from outside knowledge.

  /// Chapters + caller artifacts + private tutor threads in one call.
  Future<CourseStudyWorkspace> getCourseStudyWorkspace(String id) async {
    final res = await _client.get<dynamic>('$_base/courses/$id/study');
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return CourseStudyWorkspace.fromJson(
        body['data'] as Map<String, dynamic>,
      );
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  /// Generates a summary or a flashcard deck grounded in the course.
  Future<CourseStudyArtifact> generateStudyArtifact({
    required String id,
    required String kind,
    String language = 'fr',
    String? summaryMode,
    int? flashcardCount,
    String? focus,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/courses/$id/study/artifacts',
      data: {
        'kind': kind,
        'language': language,
        'summaryMode': ?summaryMode,
        'flashcardCount': ?flashcardCount,
        if (focus != null && focus.trim().isNotEmpty) 'focus': focus.trim(),
      },
    );
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return CourseStudyArtifact.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw const ApiException(message: 'Unexpected response format');
  }

  /// Deletes one of the caller's artifacts (idempotent 204).
  Future<void> deleteStudyArtifact({
    required String id,
    required String artifactId,
  }) async {
    await _client.delete<dynamic>(
      '$_base/courses/$id/study/artifacts/$artifactId',
    );
  }

  /// Sends one course-scoped tutor question.
  ///
  /// Pass [conversationId] to continue an existing thread; omit it to start
  /// a new one. An off-course question returns `assistantMessage.inScope ==
  /// false` and a refusal message.
  Future<CourseTutorExchange> askCourseTutor({
    required String id,
    required String question,
    String? conversationId,
    String language = 'fr',
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/courses/$id/tutor/ask',
      data: {
        'question': question,
        'language': language,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
      },
    );
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return CourseTutorExchange.fromJson(body['data'] as Map<String, dynamic>);
    }
    throw const ApiException(message: 'Unexpected response format');
  }
}
