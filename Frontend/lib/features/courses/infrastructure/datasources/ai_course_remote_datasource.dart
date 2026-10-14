import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/course_outline.dart';

/// Teacher side of the AI course generation API
/// (`contracts/ai-assistant.openapi.yaml`, TEACHER or ADMIN).
/// Returns raw envelope contents; the page maps failures via `failureL10n`.
class AiCourseRemoteDataSource {
  AiCourseRemoteDataSource(this._client);

  final ApiClient _client;

  static String get _base => ApiConfig.apiPrefix;

  /// Rapidly generates a structured course outline in ~3s.
  Future<CourseOutline> generateOutline({
    required String mode,
    required String level,
    required String difficulty,
    required String format,
    String? subject,
    String? sourceText,
    String? url,
    bool examples = true,
    bool mermaid = true,
    bool webImages = false,
    bool webSearch = false,
    bool thinking = false,
  }) async {
    final cleanSubject = subject?.trim();
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/generate-outline',
      receiveTimeout: const Duration(minutes: 3),
      data: {
        'mode': mode,
        'level': level,
        'difficulty': difficulty,
        'format': format,
        if (cleanSubject != null && cleanSubject.isNotEmpty) ...{
          'subject': cleanSubject,
          'topic': cleanSubject,
        },
        if (sourceText != null && sourceText.trim().isNotEmpty) ...{
          'sourceText': sourceText.trim(),
          'sourceContext': sourceText.trim(),
        },
        if (url != null && url.trim().isNotEmpty) 'url': url.trim(),
        'extras': {
          'examples': examples,
          'mermaid': mermaid,
          'webImages': webImages,
          'webSearch': webSearch,
          'thinking': thinking,
        },
      },
    );
    final env = apiEnvelope(res);
    final outlineData = env['outline'];
    if (outlineData is Map<String, dynamic>) {
      return CourseOutline.fromJson(outlineData);
    }
    throw const ApiException(message: 'Invalid outline response');
  }

  /// Selectively refines, expands, simplifies or edits a course section.
  Future<Map<String, dynamic>> refineSection({
    required String courseContent,
    required String selectedText,
    required String instruction,
    String? level,
    String? difficulty,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/refine-section',
      receiveTimeout: const Duration(minutes: 3),
      data: {
        'courseContent': courseContent,
        'fullContext': courseContent,
        'selectedText': selectedText,
        'instruction': instruction,
        // ignore: use_null_aware_elements
        if (level != null) 'level': level,
        // ignore: use_null_aware_elements
        if (difficulty != null) 'difficulty': difficulty,
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> generate({
    required String mode,
    required String level,
    required String format,
    String? subject,
    String? sourceText,
    String? url,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/generate',
      data: {
        'mode': mode,
        'level': level,
        'format': format,
        if (subject != null && subject.trim().isNotEmpty)
          'subject': subject.trim(),
        if (sourceText != null && sourceText.trim().isNotEmpty)
          'sourceText': sourceText,
        if (url != null && url.trim().isNotEmpty) 'url': url.trim(),
      },
    );
    return apiEnvelope(res);
  }

  Map<String, dynamic> _options(
    String level,
    String difficulty,
    String format,
    bool exExamples,
    bool exMermaid,
    bool exWebImages,
    bool exWebSearch,
    bool exThinking,
  ) {
    return {
      'level': level,
      'difficulty': difficulty,
      'format': format,
      'extras': {
        'examples': exExamples,
        'mermaid': exMermaid,
        'webImages': exWebImages,
        'webSearch': exWebSearch,
        'thinking': exThinking,
      },
    };
  }

  /// Dedicated per-method endpoints (simpler payloads, no `mode`).
  Future<Map<String, dynamic>> fromTopic({
    required String subject,
    required String level,
    required String difficulty,
    required String format,
    required bool exExamples,
    required bool exMermaid,
    required bool exWebImages,
    required bool exWebSearch,
    required bool exThinking,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/from-topic',
      data: {
        'subject': subject.trim(),
        ..._options(level, difficulty, format, exExamples, exMermaid,
            exWebImages, exWebSearch, exThinking),
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> fromUrl({
    required String url,
    required String level,
    required String difficulty,
    required String format,
    required bool exExamples,
    required bool exMermaid,
    required bool exWebImages,
    required bool exWebSearch,
    required bool exThinking,
  }) async {
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/from-url',
      data: {
        'url': url.trim(),
        ..._options(level, difficulty, format, exExamples, exMermaid,
            exWebImages, exWebSearch, exThinking),
      },
    );
    return apiEnvelope(res);
  }

  Future<Map<String, dynamic>> status() async {
    final res = await _client.get<dynamic>('$_base/ai/status');
    return apiEnvelope(res);
  }

  /// Uploads the teacher's old course PDF for improvement
  /// (POST /ai/courses/improve-pdf, multipart, max 25 MB server-side).
  Future<Map<String, dynamic>> improvePdf({
    required List<int> bytes,
    required String fileName,
    required String level,
    required String difficulty,
    required String format,
    required bool exExamples,
    required bool exMermaid,
    required bool exWebImages,
    required bool exWebSearch,
    required bool exThinking,
  }) async {
    final form = FormData.fromMap({
      'level': level,
      'difficulty': difficulty,
      'format': format,
      // Multipart has no nesting: the server parses this JSON string.
      'extras': jsonEncode({
        'examples': exExamples,
        'mermaid': exMermaid,
        'webImages': exWebImages,
        'webSearch': exWebSearch,
        'thinking': exThinking,
      }),
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    // Dio sets the multipart content-type itself: pass the form as body.
    final res = await _client.post<dynamic>(
      '$_base/ai/courses/improve-pdf',
      data: form,
    );
    return apiEnvelope(res);
  }

  /// Live-progress streaming variant.
  ///
  /// Forwards every text `delta` to [onDelta] as it arrives, pipeline
  /// progress (`extracting` → `generating` on PDF runs) to [onPhase], then
  /// [onDone] with the final metadata (no `content` key — the caller
  /// accumulated it). Server-side failures arrive as SSE error events and
  /// surface as [ApiException] via [onError].
  Future<void> streamCourse({
    required String path,
    required Map<String, dynamic> fields,
    MultipartFile? file,
    required void Function(String delta) onDelta,
    void Function(String phase)? onPhase,
    required void Function(Map<String, dynamic> meta) onDone,
    required void Function(ApiException error) onError,
    CancelToken? cancelToken,
  }) async {
    Object body = fields;
    if (file != null) {
      body = FormData.fromMap({...fields, 'file': file});
    }
    var done = false;
    try {
      await _client.postStream(
        path,
        data: body,
        cancelToken: cancelToken,
        onLine: (line) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) return;
          final payload = trimmed.substring('data:'.length).trim();
          if (payload.isEmpty || payload == '[DONE]') return;
          Map<String, dynamic>? frame;
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map<String, dynamic>) frame = decoded;
          } catch (_) {
            return;
          }
          if (frame == null) return;
          final delta = frame['delta'];
          if (delta is String && delta.isNotEmpty) {
            onDelta(delta);
            return;
          }
          final phase = frame['phase'];
          if (phase is String && phase.isNotEmpty) {
            onPhase?.call(phase);
            return;
          }
          if (frame['done'] == true) {
            done = true;
            frame.remove('done');
            onDone(frame);
            return;
          }
          final error = frame['error'];
          if (error is Map<String, dynamic>) {
            onError(ApiException(
              code: error['code']?.toString(),
              message: error['message']?.toString() ?? 'Request failed',
            ));
          }
        },
      );
    } on ApiException catch (e) {
      if (!done) onError(e);
    }
  }

  /// Subjects the teacher really teaches (their class assignments).
  Future<List<String>> myTeachingSubjects() async {
    final res = await _client.get<dynamic>('$_base/groups/mine');
    final body = res.data;
    if (body is Map<String, dynamic> && body['data'] is List) {
      final subjects = <String>{};
      for (final item in (body['data'] as List)) {
        if (item is! Map<String, dynamic>) continue;
        final list = item['mySubjects'];
        if (list is List) subjects.addAll(list.whereType<String>());
      }
      return subjects.toList()..sort();
    }
    throw const ApiException(message: 'Unexpected response format');
  }
}
