import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/course_outline.dart';
import '../derive_course_title.dart';
import 'ai_course_options_provider.dart';
import 'courses_provider.dart';

/// Parameters of one course generation (snapshot of the creator form).
class GenerationJobParams {
  /// `topic` | `pdf` | `url`.
  final String mode;

  /// Title fallback + saved `subject`: topic text, PDF name or URL.
  final String subject;
  final List<int>? pdfBytes;
  final String? pdfName;
  final String? url;

  final String level;
  final String difficulty;
  final String format;
  final bool examples;
  final bool mermaid;
  final bool webImages;
  final bool webSearch;
  final bool thinking;
  final bool generateImages;
  final CourseOutline? outline;

  const GenerationJobParams({
    required this.mode,
    required this.subject,
    this.pdfBytes,
    this.pdfName,
    this.url,
    required this.level,
    required this.difficulty,
    required this.format,
    required this.examples,
    required this.mermaid,
    required this.webImages,
    required this.webSearch,
    required this.thinking,
    this.generateImages = false,
    this.outline,
  });
}

enum GenerationJobStatus { idle, running, done, error }

/// Snapshot of the background generation job.
///
/// The job outlives the creator page: leaving the screen never cancels it,
/// and completion auto-saves the course as DRAFT so the teacher finds it
/// in "Mes cours" (brouillons) even when the page is gone.
class GenerationJobState {
  final GenerationJobStatus status;

  /// Monotonic run id (lets pages reset local editing on a new run).
  final int seq;
  final int elapsedSec;

  /// Accumulated output length (notified on a throttle, not per token).
  final int chars;

  /// Tail of the live output for the progress preview.
  final String preview;

  /// Silent pipeline step narrated by the backend (`extracting` while the
  /// PDF is parsed, `generating` once the model takes over). Empty when
  /// unknown — the progress card then shows its default text.
  final String phase;

  /// Full content once done (kept for re-display after navigation).
  final String content;
  final Map<String, dynamic> meta;

  /// Auto-saved (or manually saved) draft id, null until saved.
  final String? courseId;

  /// Exact text of the saved snapshot: the save button reappears only
  /// when the displayed text differs from it (or nothing is saved yet).
  final String? savedContent;

  /// Manual-save spinner (`Enregistrer` after an edit or a save failure).
  final bool saving;
  final Object? saveError;

  /// Stream failure (`REQUEST_CANCELLED` goes back to idle instead).
  final Object? error;

  const GenerationJobState({
    this.status = GenerationJobStatus.idle,
    this.seq = 0,
    this.elapsedSec = 0,
    this.chars = 0,
    this.preview = '',
    this.phase = '',
    this.content = '',
    this.meta = const {},
    this.courseId,
    this.savedContent,
    this.saving = false,
    this.saveError,
    this.error,
  });

  GenerationJobState copyWith({
    GenerationJobStatus? status,
    int? seq,
    int? elapsedSec,
    int? chars,
    String? preview,
    String? phase,
    String? content,
    Map<String, dynamic>? meta,
    String? courseId,
    String? savedContent,
    bool? saving,
    Object? saveError,
    Object? error,
  }) {
    return GenerationJobState(
      status: status ?? this.status,
      seq: seq ?? this.seq,
      elapsedSec: elapsedSec ?? this.elapsedSec,
      chars: chars ?? this.chars,
      preview: preview ?? this.preview,
      phase: phase ?? this.phase,
      content: content ?? this.content,
      meta: meta ?? this.meta,
      courseId: courseId ?? this.courseId,
      savedContent: savedContent ?? this.savedContent,
      saving: saving ?? this.saving,
      saveError: saveError,
      error: error,
    );
  }
}

/// Background course generation (survives page navigation).
///
/// Never auto-disposed: started from the creator page, it keeps streaming
/// while the teacher browses "Mes cours", then auto-saves the DRAFT.
class CourseGenerationJob extends StateNotifier<GenerationJobState> {
  CourseGenerationJob(this._ref) : super(const GenerationJobState());

  final Ref _ref;
  final StringBuffer _buffer = StringBuffer();
  Timer? _timer;
  CancelToken? _cancel;
  GenerationJobParams? _params;
  int _lastNotifyChars = 0;
  DateTime _lastNotifyAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const _previewMax = 600;

  String _tail(String full) {
    if (full.length <= _previewMax) return full;
    return '…${full.substring(full.length - _previewMax)}';
  }

  void _notifyProgress() {
    final full = _buffer.toString();
    _lastNotifyChars = full.length;
    _lastNotifyAt = DateTime.now();
    if (!mounted) return;
    state = state.copyWith(chars: full.length, preview: _tail(full));
  }

  /// Starts a generation (no-op while one already runs).
  Future<void> start(GenerationJobParams params) async {
    if (state.status == GenerationJobStatus.running) return;
    _cancel?.cancel();
    _timer?.cancel();
    _buffer.clear();
    _params = params;
    _lastNotifyChars = 0;
    _lastNotifyAt = DateTime.now();
    state = GenerationJobState(
      status: GenerationJobStatus.running,
      seq: state.seq + 1,
    );

    final cancelToken = CancelToken();
    _cancel = cancelToken;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // 1s repaint (elapsed + throttled chars), no rebuild per token.
      state = state.copyWith(elapsedSec: state.elapsedSec + 1);
    });

    void onDelta(String delta) {
      _buffer.write(delta);
      final now = DateTime.now();
      if (_buffer.length - _lastNotifyChars >= 100 ||
          now.difference(_lastNotifyAt).inMilliseconds >= 800) {
        _notifyProgress();
      }
    }

    void onPhase(String phase) {
      if (!mounted) return;
      state = state.copyWith(phase: phase);
    }

    // ignore: avoid_void_async
    void onDone(Map<String, dynamic> meta) async {
      final content = _buffer.toString();
      _timer?.cancel();
      if (!mounted) return;
      state = state.copyWith(
        status: GenerationJobStatus.done,
        content: content,
        meta: meta,
        chars: content.length,
        preview: _tail(content),
      );
      _ref.invalidate(aiModelStatusProvider);
      // Auto-save so the course lands in drafts even if the teacher
      // already left the page. Failure keeps `courseId` null: the page
      // then offers a manual "Enregistrer" retry on the same content.
      try {
        final saved = await _ref
            .read(generatedCoursesDataSourceProvider)
            .saveDraft(
              title: deriveCourseTitle(content, fallback: params.subject),
              subject:
                  params.subject.isEmpty ? null : params.subject,
              content: content,
              level: params.level,
              difficulty: params.difficulty,
              format: params.format,
              outline: params.outline,
            );
        _ref.invalidate(myGeneratedCoursesProvider);
        if (!mounted) return;
        state = state.copyWith(courseId: saved.id, savedContent: content);
      } catch (e) {
        if (!mounted) return;
        state = state.copyWith(saveError: e);
      }
    }

    void onError(Object error) {
      _timer?.cancel();
      if (!mounted) return;
      if (error is ApiException && error.code == 'REQUEST_CANCELLED') {
        state = GenerationJobState(seq: state.seq);
        return;
      }
      state = state.copyWith(status: GenerationJobStatus.error, error: error);
    }

    try {
      final remote = _ref.read(aiCourseRemoteDataSourceProvider);
      // JSON body must match the strict Zod schema
      // (`contracts/ai-assistant.openapi.yaml`): extras nested as an object.
      final options = {
        'level': params.level,
        'difficulty': params.difficulty,
        'format': params.format,
        if (params.outline != null) 'outline': params.outline!.toJson(),
        'extras': {
          'examples': params.examples,
          'mermaid': params.mermaid,
          'webImages': params.webImages,
          'webSearch': params.webSearch,
          'thinking': params.thinking,
          'generateImages': params.generateImages,
        },
      };
      switch (params.mode) {
        case 'pdf':
          await remote.streamCourse(
            path: '/api/v1/ai/courses/improve-pdf-stream',
            fields: {
              'level': params.level,
              'difficulty': params.difficulty,
              'format': params.format,
              if (params.outline != null)
                'outline': jsonEncode(params.outline!.toJson()),
              // Multipart has no nesting: the server parses this JSON string.
              'extras': jsonEncode({
                'examples': params.examples,
                'mermaid': params.mermaid,
                'webImages': params.webImages,
                'webSearch': params.webSearch,
                'thinking': params.thinking,
                'generateImages': params.generateImages,
              }),
            },
            file: MultipartFile.fromBytes(
                params.pdfBytes!, filename: params.pdfName!),
            onDelta: onDelta,
            onPhase: onPhase,
            onDone: onDone,
            onError: onError,
            cancelToken: cancelToken,
          );
        case 'url':
          await remote.streamCourse(
            path: '/api/v1/ai/courses/stream',
            fields: {
              'mode': 'url',
              'url': params.url,
              ...options,
            },
            onDelta: onDelta,
            onPhase: onPhase,
            onDone: onDone,
            onError: onError,
            cancelToken: cancelToken,
          );
        default:
          await remote.streamCourse(
            path: '/api/v1/ai/courses/stream',
            fields: {
              'mode': 'topic',
              'subject': params.subject,
              ...options,
            },
            onDelta: onDelta,
            onPhase: onPhase,
            onDone: onDone,
            onError: onError,
            cancelToken: cancelToken,
          );
      }
    } catch (e) {
      onError(e);
    }
  }

  /// Cancels a running generation (explicit user action only — leaving
  /// the page never cancels).
  void cancel() {
    _cancel?.cancel();
  }

  /// Back to idle after a finished run (page's "Nouvelle génération").
  /// Ignored while running so the progress card can't be wiped mid-stream.
  void reset() {
    if (state.status == GenerationJobStatus.running) return;
    _timer?.cancel();
    _buffer.clear();
    _params = null;
    state = GenerationJobState(seq: state.seq + 1);
  }

  /// Directly applies refined/edited content and auto-updates the backend draft if saved.
  Future<void> applyRefinedContent(String newContent) async {
    if (!mounted) return;
    state = state.copyWith(
      content: newContent,
      chars: newContent.length,
      preview: _tail(newContent),
      savedContent: state.courseId != null ? newContent : state.savedContent,
    );

    final courseId = state.courseId;
    if (courseId != null) {
      try {
        await _ref
            .read(generatedCoursesDataSourceProvider)
            .updateCourse(id: courseId, content: newContent);
        _ref.invalidate(myGeneratedCoursesProvider);
      } catch (_) {
        // Soft fail; teacher can still manually click Enregistrer
      }
    }
  }

  /// Manually saves [content] as a draft (edited text, or retry after an
  /// auto-save failure). Replaces the previous auto-saved draft when the
  /// text differs, so drafts never silently duplicate.
  Future<void> saveCurrentEdits(String content) async {
    final params = _params;
    if (params == null || content.trim().isEmpty || state.saving) return;
    state = state.copyWith(saving: true, saveError: null);
    try {
      final saved = await _ref
          .read(generatedCoursesDataSourceProvider)
          .saveDraft(
            title: deriveCourseTitle(content, fallback: params.subject),
            subject: params.subject.isEmpty ? null : params.subject,
            content: content,
            level: params.level,
            difficulty: params.difficulty,
            format: params.format,
            outline: params.outline,
          );
      // Drop the replaced auto-saved draft (best effort: a failure here
      // only leaves one extra draft, never loses content).
      final previousId = state.courseId;
      if (previousId != null && previousId != saved.id) {
        try {
          await _ref
              .read(generatedCoursesDataSourceProvider)
              .deleteCourse(previousId);
        } catch (_) {
          // Keep both drafts rather than risk content loss.
        }
      }
      _ref.invalidate(myGeneratedCoursesProvider);
      if (!mounted) return;
      state = state.copyWith(
        saving: false,
        courseId: saved.id,
        savedContent: content,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(saving: false, saveError: e);
    }
  }
}

/// App-lifetime job (never auto-disposed on purpose).
final courseGenerationJobProvider =
    StateNotifierProvider<CourseGenerationJob, GenerationJobState>(
  (ref) => CourseGenerationJob(ref),
);
