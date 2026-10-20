import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/entities/course_section.dart';
import '../../infrastructure/datasources/course_section_remote_datasource.dart';
import 'ai_course_options_provider.dart';
import 'courses_provider.dart';

/// Plain-HTTP endpoints of the section build (build state, validate,
/// illustration). Generation streams go through
/// [aiCourseRemoteDataSourceProvider] (SSE).
final courseSectionRemoteDataSourceProvider =
    Provider<CourseSectionRemoteDataSource>(
  (ref) => CourseSectionRemoteDataSource(ref.watch(apiClientProvider)),
);

/// Snapshot of the by-section build of one course.
///
/// [error] (load failure) and [streamError] (generation failure) use
/// direct assignment (same style as `GenerationJobState`): any [copyWith]
/// call that omits them resets them to null — the page consumes them as
/// one-shot snackbars.
class CourseSectionBuildState {
  const CourseSectionBuildState({
    this.loading = false,
    this.error,
    this.course,
    this.sections = const [],
    this.streamingKey,
    this.streamingText = '',
    this.streamingPhase = '',
    this.streamError,
  });

  /// Initial fetch in flight.
  final bool loading;

  /// Build fetch failure (sections absent → retry view).
  final Object? error;

  final CourseBuildCourse? course;
  final List<CourseSectionEntry> sections;

  /// `sectionKey` currently streaming, null when idle.
  final String? streamingKey;

  /// Accumulated deltas of the live stream (preview while writing).
  final String streamingText;

  /// Backend narration: `memory` (vector recall) → `generating`.
  final String streamingPhase;

  /// Generation failure (SSE error event / transport error).
  final Object? streamError;

  bool get isStreaming => streamingKey != null;

  int get validatedCount => sections
      .where((section) => section.status == CourseSectionStatus.validated)
      .length;

  int get remainingToValidate => sections.length - validatedCount;

  CourseSectionEntry? section(String sectionKey) {
    for (final section in sections) {
      if (section.sectionKey == sectionKey) return section;
    }
    return null;
  }

  CourseSectionBuildState copyWith({
    bool? loading,
    Object? error,
    CourseBuildCourse? course,
    List<CourseSectionEntry>? sections,
    String? streamingKey,
    String? streamingText,
    String? streamingPhase,
    bool resetStreaming = false,
    Object? streamError,
  }) {
    return CourseSectionBuildState(
      loading: loading ?? this.loading,
      error: error,
      course: course ?? this.course,
      sections: sections ?? this.sections,
      streamingKey:
          resetStreaming ? null : (streamingKey ?? this.streamingKey),
      streamingText:
          resetStreaming ? '' : (streamingText ?? this.streamingText),
      streamingPhase:
          resetStreaming ? '' : (streamingPhase ?? this.streamingPhase),
      streamError: streamError,
    );
  }
}

/// Section-by-section build controller (RG4/RG27: nothing published before
/// every section is VALIDATED).
///
/// One notifier per course, **not** auto-disposed: a generation keeps
/// streaming when the teacher leaves the page (same policy as
/// `courseGenerationJobProvider`), and the state survives the back-and-forth
/// between reader and builder. Re-entering the page always reloads.
class CourseSectionBuild extends StateNotifier<CourseSectionBuildState> {
  CourseSectionBuild(this._ref, this.courseId)
      : super(const CourseSectionBuildState());

  final Ref _ref;
  final String courseId;

  CancelToken? _cancel;
  int _loadRun = 0;
  int _streamRun = 0;

  /// Fetches the build state (materializes the sections from the outline
  /// on first call). No-op while a stream is live — it would clobber the
  /// section being written.
  Future<void> load() async {
    if (state.isStreaming) return;
    final run = ++_loadRun;
    state = state.copyWith(loading: true);
    try {
      final data = await _ref
          .read(courseSectionRemoteDataSourceProvider)
          .getBuild(courseId);
      if (!mounted || run != _loadRun) return;
      state = state.copyWith(
        loading: false,
        course: data.course,
        sections: data.sections,
      );
    } catch (e) {
      if (!mounted || run != _loadRun) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Streams one section (SSE): deltas accumulate into [streamingText],
  /// then the saved section replaces the row via the `done` metadata.
  /// A VALIDATED section can only move forward through [regenerate]
  /// (the plain endpoint would answer 409).
  Future<void> generate({
    required String sectionKey,
    required bool regenerate,
  }) async {
    if (state.isStreaming) return;
    final target = state.section(sectionKey);
    if (target == null) return;
    if (target.status == CourseSectionStatus.validated && !regenerate) {
      return;
    }

    final run = ++_streamRun;
    final cancel = CancelToken();
    _cancel = cancel;
    final buffer = StringBuffer();
    state = state.copyWith(
      streamingKey: sectionKey,
      streamingText: '',
      streamingPhase: 'memory',
    );

    await _ref.read(aiCourseRemoteDataSourceProvider).streamCourse(
          path:
              '${ApiConfig.apiPrefix}/ai/courses/sections/${regenerate ? 'regenerate' : 'generate'}',
          fields: {
            'courseId': courseId,
            'sectionKey': sectionKey,
            if (state.course != null) 'level': state.course!.level,
            if (state.course != null) 'difficulty': state.course!.difficulty,
          },
          cancelToken: cancel,
          onDelta: (delta) {
            buffer.write(delta);
            if (!mounted || run != _streamRun) return;
            state = state.copyWith(streamingText: buffer.toString());
          },
          onPhase: (phase) {
            if (!mounted || run != _streamRun) return;
            state = state.copyWith(streamingPhase: phase);
          },
          onDone: (meta) {
            if (!mounted || run != _streamRun) return;
            _cancel = null;
            final sectionJson = meta['section'];
            if (sectionJson is Map<String, dynamic>) {
              final updated = CourseSectionEntry.fromJson(sectionJson);
              state = state.copyWith(
                sections: [
                  for (final item in state.sections)
                    if (item.sectionKey == sectionKey) updated else item,
                ],
                resetStreaming: true,
              );
            } else {
              // Defensive: metadata without the saved section → resync.
              state = state.copyWith(resetStreaming: true);
              unawaited(load());
            }
          },
          onError: (err) {
            if (!mounted || run != _streamRun) return;
            _cancel = null;
            final cancelled = err.code == 'REQUEST_CANCELLED';
            state = state.copyWith(
              resetStreaming: true,
              streamError: cancelled ? null : err,
            );
          },
        );
  }

  /// Cancels the live generation (SSE `REQUEST_CANCELLED` settles state).
  void cancel() {
    _cancel?.cancel();
  }

  /// Teacher approves a generated section: it becomes VALIDATED, enters
  /// the vector memory and the draft body is reassembled server-side.
  /// Throws [ApiException] to the caller (page shows the snackbar).
  Future<void> validate(String sectionKey) async {
    if (state.isStreaming) return;
    final updated = await _ref
        .read(courseSectionRemoteDataSourceProvider)
        .validateSection(courseId: courseId, sectionKey: sectionKey);
    if (!mounted) return;
    state = state.copyWith(
      sections: [
        for (final item in state.sections)
          if (item.sectionKey == sectionKey) updated else item,
      ],
    );
    _ref.invalidate(myGeneratedCoursesProvider);
  }

  /// Illustration of one section — returns `{imageUrl, prompt, provider}`.
  /// Throws [ApiException]: 503 `IMAGE_SERVICE_UNAVAILABLE` while the
  /// ComfyUI nodes are being wired (page shows "coming soon").
  Future<Map<String, dynamic>> generateSectionImage(
    String sectionKey, {
    String kind = 'FIGURE',
  }) {
    return _ref.read(courseSectionRemoteDataSourceProvider).generateSectionImage(
          courseId: courseId,
          sectionKey: sectionKey,
          kind: kind,
        );
  }

  /// Consumes [CourseSectionBuildState.streamError] after the snackbar.
  void acknowledgeStreamError() {
    if (!mounted) return;
    state = state.copyWith();
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }
}

final courseSectionBuildProvider = StateNotifierProvider.family<
    CourseSectionBuild, CourseSectionBuildState, String>(
  (ref, courseId) => CourseSectionBuild(ref, courseId),
);
