import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/course_section.dart';

/// Section-by-section build API
/// (`contracts/ai-assistant.openapi.yaml`, TEACHER or ADMIN).
///
/// Generation/regenerate streams reuse `AiCourseRemoteDataSource.streamCourse`
/// (SSE) from the provider layer; this class covers the plain HTTP
/// endpoints: build state, validation, illustration.
class CourseSectionRemoteDataSource {
  CourseSectionRemoteDataSource(this._client);

  final ApiClient _client;

  static String get _base => ApiConfig.apiPrefix;

  /// GET /ai/courses/:id/build — course metadata + ordered sections
  /// (sections are materialized from the outline on first call).
  Future<CourseBuildData> getBuild(String courseId) async {
    final res = await _client.get<dynamic>('$_base/ai/courses/$courseId/build');
    final env = apiEnvelope(res);
    final course = env['course'];
    final sections = env['sections'];
    if (course is! Map<String, dynamic> || sections is! List) {
      throw const ApiException(message: 'Invalid build response');
    }
    return CourseBuildData(
      course: CourseBuildCourse.fromJson(course),
      sections: sections
          .whereType<Map<String, dynamic>>()
          .map(CourseSectionEntry.fromJson)
          .toList(),
      initializedFromOutline: env['initializedFromOutline'] == true,
    );
  }

  /// POST /ai/courses/sections/validate — teacher approves one section:
  /// it becomes VALIDATED, enters the author's vector memory and the draft
  /// body is reassembled server-side.
  Future<CourseSectionEntry> validateSection({
    required String courseId,
    required String sectionKey,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/sections/validate',
      data: {'courseId': courseId, 'sectionKey': sectionKey},
    );
    final env = apiEnvelope(res);
    final section = env['section'];
    if (section is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid validation response');
    }
    return CourseSectionEntry.fromJson(section);
  }

  /// POST /ai/courses/sections/image — illustration for one section via the
  /// local ComfyUI SDXL workflow. A generation takes 4-5 min on a GTX 1650,
  /// so the client waits up to 7 min (the backend gives up at 6 min and
  /// answers 503 `IMAGE_SERVICE_UNAVAILABLE`, surfaced as "coming soon").
  Future<Map<String, dynamic>> generateSectionImage({
    required String courseId,
    required String sectionKey,
    String kind = 'FIGURE',
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/sections/image',
      receiveTimeout: const Duration(minutes: 7),
      data: {'courseId': courseId, 'sectionKey': sectionKey, 'kind': kind},
    );
    return apiEnvelope(res);
  }
}
