import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/course_study.dart';
import 'courses_provider.dart';

/// Student study workspace of one course: chapters, caller artifacts and
/// private tutor threads (`GET /courses/{id}/study`).
///
/// A single family provider serves the three study tabs, so switching tabs
/// never refetches. Invalidated after every generation/deletion.
final courseStudyWorkspaceProvider =
    FutureProvider.family<CourseStudyWorkspace, String>((ref, courseId) async {
      final keepAlive = ref.keepAlive();
      try {
        return await ref
            .watch(generatedCoursesDataSourceProvider)
            .getCourseStudyWorkspace(courseId);
      } finally {
        keepAlive.close();
      }
    });

/// Progress of a summary/flashcard generation (or an artifact deletion).
class CourseStudyActionState {
  const CourseStudyActionState({this.busy = false, this.busyKind, this.error});

  final bool busy;

  /// `SUMMARY` | `FLASHCARDS` | `DELETE`.
  final String? busyKind;
  final Object? error;

  bool get isGeneratingSummary => busy && busyKind == 'SUMMARY';
  bool get isGeneratingFlashcards => busy && busyKind == 'FLASHCARDS';
}

/// Generates and deletes the caller's study artifacts for one course.
class CourseStudyController extends StateNotifier<CourseStudyActionState> {
  CourseStudyController(this._ref, this._courseId)
    : super(const CourseStudyActionState());

  final Ref _ref;
  final String _courseId;

  Future<void> generateSummary({
    String mode = 'medium',
    String? focus,
    String language = 'fr',
  }) async {
    await _generate(
      kind: 'SUMMARY',
      summaryMode: mode,
      focus: focus,
      language: language,
    );
  }

  Future<void> generateFlashcards({
    int count = 8,
    String? focus,
    String language = 'fr',
  }) async {
    await _generate(
      kind: 'FLASHCARDS',
      flashcardCount: count,
      focus: focus,
      language: language,
    );
  }

  Future<void> _generate({
    required String kind,
    String? summaryMode,
    int? flashcardCount,
    String? focus,
    required String language,
  }) async {
    if (state.busy) return;
    state = CourseStudyActionState(busy: true, busyKind: kind);
    try {
      await _ref
          .read(generatedCoursesDataSourceProvider)
          .generateStudyArtifact(
            id: _courseId,
            kind: kind,
            language: language,
            summaryMode: summaryMode,
            flashcardCount: flashcardCount,
            focus: focus,
          );
      _ref.invalidate(courseStudyWorkspaceProvider(_courseId));
      if (mounted) state = const CourseStudyActionState();
    } catch (error) {
      if (mounted) {
        state = CourseStudyActionState(
          busy: false,
          busyKind: kind,
          error: error,
        );
      }
    }
  }

  Future<void> deleteArtifact(String artifactId) async {
    if (state.busy) return;
    state = const CourseStudyActionState(busy: true, busyKind: 'DELETE');
    try {
      await _ref
          .read(generatedCoursesDataSourceProvider)
          .deleteStudyArtifact(id: _courseId, artifactId: artifactId);
      _ref.invalidate(courseStudyWorkspaceProvider(_courseId));
      if (mounted) state = const CourseStudyActionState();
    } catch (error) {
      if (mounted) {
        state = CourseStudyActionState(
          busy: false,
          busyKind: 'DELETE',
          error: error,
        );
      }
    }
  }
}

final courseStudyControllerProvider = StateNotifierProvider.autoDispose
    .family<CourseStudyController, CourseStudyActionState, String>(
      (ref, courseId) => CourseStudyController(ref, courseId),
    );

/// One course-scoped tutor thread. Messages come from the latest persisted
/// conversation (hydrated by the tutor tab) and grow as the student asks.
class CourseTutorState {
  const CourseTutorState({
    this.messages = const [],
    this.conversationId,
    this.sending = false,
    this.error,
    this.hydrated = false,
  });

  final List<CourseTutorMessage> messages;
  final String? conversationId;
  final bool sending;
  final Object? error;

  /// True once the persisted thread has been merged (once per tab life).
  final bool hydrated;
}

class CourseTutorController extends StateNotifier<CourseTutorState> {
  CourseTutorController(this._ref, this._courseId)
    : super(const CourseTutorState());

  final Ref _ref;
  final String _courseId;

  /// Merges the persisted thread the first time the tab opens.
  void hydrate(CourseTutorConversation? conversation) {
    if (state.hydrated) return;
    state = CourseTutorState(
      messages: conversation?.messages ?? const [],
      conversationId: conversation?.id,
      hydrated: true,
    );
  }

  Future<void> ask(String question, {String language = 'fr'}) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || state.sending) return;

    state = CourseTutorState(
      messages: [
        ...state.messages,
        CourseTutorMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          conversationId: state.conversationId ?? '',
          role: 'user',
          content: trimmed,
          createdAt: DateTime.now(),
        ),
      ],
      conversationId: state.conversationId,
      sending: true,
      hydrated: true,
    );

    try {
      final exchange = await _ref
          .read(generatedCoursesDataSourceProvider)
          .askCourseTutor(
            id: _courseId,
            question: trimmed,
            conversationId: state.conversationId,
            language: language,
          );
      if (!mounted) return;
      state = CourseTutorState(
        messages: [
          ...state.messages.where((m) => !m.id.startsWith('local-')),
          exchange.userMessage,
          exchange.assistantMessage,
        ],
        conversationId: exchange.conversationId,
        hydrated: true,
      );
      _ref.invalidate(courseStudyWorkspaceProvider(_courseId));
    } catch (error) {
      if (!mounted) return;
      state = CourseTutorState(
        messages: state.messages,
        conversationId: state.conversationId,
        error: error,
        hydrated: true,
      );
    }
  }
}

final courseTutorProvider = StateNotifierProvider.autoDispose
    .family<CourseTutorController, CourseTutorState, String>(
      (ref, courseId) => CourseTutorController(ref, courseId),
    );
