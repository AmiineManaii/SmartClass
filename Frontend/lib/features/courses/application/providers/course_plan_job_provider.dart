import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/course_outline.dart';
import 'ai_course_options_provider.dart';
import 'courses_provider.dart';

enum CoursePlanJobStatus { idle, running, completed, error }

/// Holds the active outline generation state across the entire app.
///
/// If the teacher starts "Proposer le plan" and navigates to other screens,
/// this state keeps running with a live second timer, auto-saves the draft,
/// and lets the teacher open the finished plan from any screen.
class CoursePlanJobState {
  final CoursePlanJobStatus status;
  final int elapsedSec;
  final String subject;
  final String mode;
  final String level;
  final String difficulty;
  final String format;
  final String? url;
  final String? pdfName;
  final List<int>? pdfBytes;
  final bool examples;
  final bool mermaid;
  final CourseOutline? outline;
  final String? draftCourseId;
  final bool outlineSaved;
  final Object? error;
  final bool dismissed;

  const CoursePlanJobState({
    this.status = CoursePlanJobStatus.idle,
    this.elapsedSec = 0,
    this.subject = '',
    this.mode = 'topic',
    this.level = 'equilibre',
    this.difficulty = 'moyen',
    this.format = 'resume',
    this.url,
    this.pdfName,
    this.pdfBytes,
    this.examples = true,
    this.mermaid = true,
    this.outline,
    this.draftCourseId,
    this.outlineSaved = false,
    this.error,
    this.dismissed = false,
  });

  CoursePlanJobState copyWith({
    CoursePlanJobStatus? status,
    int? elapsedSec,
    String? subject,
    String? mode,
    String? level,
    String? difficulty,
    String? format,
    String? url,
    String? pdfName,
    List<int>? pdfBytes,
    bool? examples,
    bool? mermaid,
    CourseOutline? outline,
    String? draftCourseId,
    bool? outlineSaved,
    Object? error,
    bool? dismissed,
  }) {
    return CoursePlanJobState(
      status: status ?? this.status,
      elapsedSec: elapsedSec ?? this.elapsedSec,
      subject: subject ?? this.subject,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      difficulty: difficulty ?? this.difficulty,
      format: format ?? this.format,
      url: url ?? this.url,
      pdfName: pdfName ?? this.pdfName,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      examples: examples ?? this.examples,
      mermaid: mermaid ?? this.mermaid,
      outline: outline ?? this.outline,
      draftCourseId: draftCourseId ?? this.draftCourseId,
      outlineSaved: outlineSaved ?? this.outlineSaved,
      error: error,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}

class CoursePlanJobNotifier extends StateNotifier<CoursePlanJobState> {
  CoursePlanJobNotifier(this._ref) : super(const CoursePlanJobState());

  final Ref _ref;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Starts background outline generation with second-by-second timer.
  Future<void> start({
    required String mode,
    required String level,
    required String difficulty,
    required String format,
    required String subject,
    String? url,
    List<int>? pdfBytes,
    String? pdfName,
    bool examples = true,
    bool mermaid = true,
  }) async {
    _timer?.cancel();
    state = CoursePlanJobState(
      status: CoursePlanJobStatus.running,
      elapsedSec: 0,
      subject: subject,
      mode: mode,
      level: level,
      difficulty: difficulty,
      format: format,
      url: url,
      pdfBytes: pdfBytes,
      pdfName: pdfName,
      examples: examples,
      mermaid: mermaid,
      dismissed: false,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      state = state.copyWith(elapsedSec: state.elapsedSec + 1);
    });

    try {
      final remote = _ref.read(aiCourseRemoteDataSourceProvider);
      final outline = await remote.generateOutline(
        mode: mode,
        level: level,
        difficulty: difficulty,
        format: format,
        subject: subject,
        url: url,
        pdfBytes: pdfBytes,
        pdfName: pdfName,
        examples: examples,
        mermaid: mermaid,
        webImages: false,
        webSearch: false,
        thinking: false,
        generateImages: false,
      );

      _timer?.cancel();
      if (!mounted) return;

      // Auto-save draft so user never loses it even if navigating away
      String? savedId;
      var saved = false;
      try {
        final draftTitle = outline.title.isEmpty ? subject : outline.title;
        final res =
            await _ref.read(generatedCoursesDataSourceProvider).saveDraft(
                  title: draftTitle,
                  subject: subject.isEmpty ? null : subject,
                  content:
                      '# $draftTitle\n\n> Plan validé : les chapitres sont rédigés un par un dans le constructeur de sections.',
                  level: level,
                  difficulty: difficulty,
                  format: format,
                  outline: outline,
                );
        savedId = res.id;
        saved = true;
        _ref.invalidate(myGeneratedCoursesProvider);
      } catch (_) {
        // Ignored; user can still see outline and retry saving from the UI
      }

      state = state.copyWith(
        status: CoursePlanJobStatus.completed,
        outline: outline,
        draftCourseId: savedId,
        outlineSaved: saved,
      );
    } catch (e) {
      _timer?.cancel();
      if (!mounted) return;
      state = state.copyWith(
        status: CoursePlanJobStatus.error,
        error: e,
      );
    }
  }

  void updateOutline(CourseOutline outline) {
    state = state.copyWith(outline: outline);
  }

  void markOutlineSaved(String courseId) {
    state = state.copyWith(outlineSaved: true, draftCourseId: courseId);
  }

  void dismiss() {
    state = state.copyWith(dismissed: true);
  }

  void reset() {
    _timer?.cancel();
    state = const CoursePlanJobState();
  }
}

final coursePlanJobProvider =
    StateNotifierProvider<CoursePlanJobNotifier, CoursePlanJobState>(
  (ref) => CoursePlanJobNotifier(ref),
);
