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

  /// POST /ai/courses/sections/image/jobs — starts a background job.
  Future<SectionImageJob> startSectionImageJob({
    required String courseId,
    required String sectionKey,
    String kind = 'FIGURE',
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/sections/image/jobs',
      data: {'courseId': courseId, 'sectionKey': sectionKey, 'kind': kind},
    );
    return SectionImageJob.fromJson(apiEnvelope(res));
  }

  /// GET /ai/courses/sections/image/jobs/:jobId — polls one job.
  Future<SectionImageJob> getSectionImageJob(String jobId) async {
    final res = await _client.get<dynamic>(
      '$_base/ai/courses/sections/image/jobs/$jobId',
    );
    return SectionImageJob.fromJson(apiEnvelope(res));
  }

  /// POST /ai/courses/sections/image/search — up to five web candidates.
  Future<List<SectionImageCandidate>> searchSectionImages({
    required String courseId,
    required String sectionKey,
    String? query,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/sections/image/search',
      data: {
        'courseId': courseId,
        'sectionKey': sectionKey,
        if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      },
    );
    final env = apiEnvelope(res);
    final images = env['images'];
    if (images is! List) {
      throw const ApiException(message: 'Invalid image search response');
    }
    return images
        .whereType<Map<String, dynamic>>()
        .map(SectionImageCandidate.fromJson)
        .where((image) => image.url.isNotEmpty)
        .toList();
  }

  /// POST /ai/courses/sections/image/apply — inserts the chosen image and
  /// returns the updated section (a VALIDATED section is demoted).
  Future<CourseSectionEntry> applySectionImage({
    required String courseId,
    required String sectionKey,
    required String imageUrl,
    String? caption,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/sections/image/apply',
      data: {
        'courseId': courseId,
        'sectionKey': sectionKey,
        'imageUrl': imageUrl,
        if (caption != null && caption.trim().isNotEmpty)
          'caption': caption.trim(),
      },
    );
    final env = apiEnvelope(res);
    final section = env['section'];
    if (section is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid image apply response');
    }
    return CourseSectionEntry.fromJson(section);
  }
}
