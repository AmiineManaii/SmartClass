import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/course_outline.dart';
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
}

