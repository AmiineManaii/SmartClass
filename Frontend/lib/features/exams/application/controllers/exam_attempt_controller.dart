import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/exam_attempt.dart';
import '../../domain/entities/exam_definition.dart';
import '../../domain/entities/exam_monitoring.dart';
import '../../domain/repositories/exam_repository.dart';

enum ExamAttemptPhase { loading, active, completed, error }

enum ExamSaveStatus { idle, saving, saved, failed }

/// Immutable state of one server-owned attempt.
class ExamAttemptState {
  const ExamAttemptState({
    required this.phase,
    this.session,
    this.answers = const {},
    this.remainingMs = 0,
    this.violationCount = 0,
    this.saveStatus = ExamSaveStatus.idle,
    this.submitting = false,
    this.autoSubmitted = false,
    this.terminatedReason,
    this.errorKey,
    this.errorDetail,
  });

  const ExamAttemptState.loading() : this(phase: ExamAttemptPhase.loading);

  final ExamAttemptPhase phase;
  final AttemptSession? session;

  /// `questionId -> selected option ids` (always at most one for the
  /// single-choice questions the backend supports today).
  final Map<String, List<String>> answers;
  final int remainingMs;
  final int violationCount;
  final ExamSaveStatus saveStatus;
  final bool submitting;
  final bool autoSubmitted;
  final String? terminatedReason;
  final String? errorKey;
  final String? errorDetail;

  bool get isActive => phase == ExamAttemptPhase.active;

  bool get isCompleted => phase == ExamAttemptPhase.completed;

  bool get isTerminated =>
      isCompleted && (terminatedReason?.isNotEmpty ?? false);

  List<StudentQuestion> get questions =>
      session?.exam.questions ?? const <StudentQuestion>[];

  int get answeredCount => questions
      .where((question) => (answers[question.id] ?? const []).isNotEmpty)
      .length;

  int get questionCount => questions.length;

  ExamAttemptState copyWith({
    ExamAttemptPhase? phase,
    AttemptSession? session,
    Map<String, List<String>>? answers,
    int? remainingMs,
    int? violationCount,
    ExamSaveStatus? saveStatus,
    bool? submitting,
    bool? autoSubmitted,
    String? Function()? terminatedReason,
    String? Function()? errorKey,
    String? Function()? errorDetail,
  }) {
    return ExamAttemptState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      answers: answers ?? this.answers,
      remainingMs: remainingMs ?? this.remainingMs,
      violationCount: violationCount ?? this.violationCount,
      saveStatus: saveStatus ?? this.saveStatus,
      submitting: submitting ?? this.submitting,
      autoSubmitted: autoSubmitted ?? this.autoSubmitted,
      terminatedReason: terminatedReason != null
          ? terminatedReason()
          : this.terminatedReason,
      errorKey: errorKey != null ? errorKey() : this.errorKey,
      errorDetail: errorDetail != null ? errorDetail() : this.errorDetail,
    );
  }
}

/// Drives the student attempt from the server clock. It never decides a
/// sanction, never grades and never invents a result: the backend owns the
/// timer, the answers, the violation count and every lifecycle transition.
class ExamAttemptController extends StateNotifier<ExamAttemptState> {
  ExamAttemptController({
    required this.repository,
    required this.examId,
  }) : super(const ExamAttemptState.loading());

  final ExamRepository repository;
  final String examId;

  Timer? _ticker;
  Timer? _saveDebounce;
  Timer? _retrySubmit;
  DateTime? _deadline;
  Future<void>? _saveInFlight;
  Future<void>? _eventChain;
  final Set<String> _dirty = <String>{};
  bool _loaded = false;
  int _saveRetries = 0;
  int _submitRetries = 0;
  bool _autoSubmitStarted = false;

  /// Loads (or resumes) the single attempt of the student for this exam.
  /// `POST /start` is idempotent server-side: an existing attempt is resumed.
  Future<void> load() async {
    if (!mounted) return;
    state = const ExamAttemptState.loading();
    try {
      final session = await repository.startAttempt(examId);
      if (!mounted) return;
      _loaded = true;
      _applySession(session);
    } on ApiException catch (error) {
      if (!mounted) return;
      state = ExamAttemptState(
        phase: ExamAttemptPhase.error,
        errorKey: 'exam_error_start',
        errorDetail: error.message,
      );
    } catch (error) {
      if (!mounted) return;
      state = ExamAttemptState(
        phase: ExamAttemptPhase.error,
        errorKey: 'exam_error_start',
        errorDetail: error.toString(),
      );
    }
  }

  void _applySession(AttemptSession session) {
    final answers = <String, List<String>>{
      for (final answer in session.answers)
        answer.questionId: List<String>.unmodifiable(answer.selectedOptionIds),
    };
    for (final question in session.exam.questions) {
      answers.putIfAbsent(question.id, () => const <String>[]);
    }
    _dirty.clear();
    _deadline = _deadlineFor(session.attempt.remainingMs);
    if (session.attempt.isActive && session.canResume) {
      state = ExamAttemptState(
        phase: ExamAttemptPhase.active,
        session: session,
        answers: answers,
        remainingMs: session.attempt.remainingMs,
        violationCount: session.attempt.violationCount,
      );
      _startTicker();
    } else {
      _stopTicker();
      state = ExamAttemptState(
        phase: ExamAttemptPhase.completed,
        session: session,
        answers: answers,
        remainingMs: session.attempt.remainingMs,
        violationCount: session.attempt.violationCount,
        autoSubmitted: session.attempt.status == AttemptStatus.autoSubmitted,
        terminatedReason: session.attempt.terminatedReason,
      );
    }
  }

  /// Selects (or clears, when the same option is tapped again) one option.
  void selectOption(String questionId, String optionId) {
    if (!state.isActive || state.submitting) return;
    final current = state.answers[questionId] ?? const <String>[];
    final isSelected = current.length == 1 && current.first == optionId;
    final next = isSelected ? <String>[] : <String>[optionId];
    final answers = Map<String, List<String>>.of(state.answers);
    answers[questionId] = next;
    _dirty.add(questionId);
    state = state.copyWith(
      answers: answers,
      saveStatus: ExamSaveStatus.idle,
      errorKey: () => null,
    );
    _scheduleSave();
  }

  bool isSelected(String questionId, String optionId) {
    final current = state.answers[questionId] ?? const <String>[];
    return current.length == 1 && current.first == optionId;
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () {
      unawaited(_saveNow());
    });
  }

  DateTime? _deadlineFor(int remaining) {
    if (remaining < 0) return null;
    return DateTime.now().add(Duration(milliseconds: remaining));
  }

  void _applyRemaining(int remaining) {
    _deadline = _deadlineFor(remaining);
    if (mounted && remaining != state.remainingMs) {
      state = state.copyWith(remainingMs: remaining);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final deadline = _deadline;
      if (deadline == null) return;
      final remaining = deadline.difference(DateTime.now()).inMilliseconds;
      final clamped = remaining < 0 ? 0 : remaining;
      if (clamped != state.remainingMs) {
        state = state.copyWith(remainingMs: clamped);
      }
      if (clamped <= 0) {
        _ticker?.cancel();
        unawaited(_autoSubmit());
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Persists dirty answers. Serialized so two saves never overwrite each
  /// other and a submit always flushes the latest selection.
  Future<bool> _saveNow({bool force = false}) async {
    if (!mounted) return false;
    if (!state.isActive) return false;
    if (_dirty.isEmpty) return true;

    final inFlight = _saveInFlight;
    if (inFlight != null) {
      await inFlight;
      if (!mounted) return false;
      if (_dirty.isEmpty) return true;
    }

    final snapshot = <String, List<String>>{};
    for (final id in _dirty) {
      snapshot[id] = List<String>.of(state.answers[id] ?? const <String>[]);
    }
    final inputs = snapshot.entries
        .where((entry) => _questionIds.contains(entry.key))
        .map(
          (entry) => StudentAnswerInput(
            questionId: entry.key,
            selectedOptionIds: entry.value,
          ),
        )
        .toList();
    if (inputs.isEmpty) {
      _dirty.clear();
      return true;
    }

    state = state.copyWith(saveStatus: ExamSaveStatus.saving);
    final future = repository.saveAnswers(examId, inputs);
    _saveInFlight = future.then<void>((_) {}, onError: (_) {});
    try {
      final result = await future;
      if (!mounted) return false;
      _saveRetries = 0;
      _applyRemaining(result.remainingMs);
      for (final entry in snapshot.entries) {
        final current = state.answers[entry.key] ?? const <String>[];
        if (_sameSelection(current, entry.value)) {
          _dirty.remove(entry.key);
        }
      }
      state = state.copyWith(
        saveStatus: _dirty.isEmpty
            ? ExamSaveStatus.saved
            : ExamSaveStatus.idle,
        errorKey: () => null,
        errorDetail: () => null,
      );
      if (_dirty.isNotEmpty) _scheduleSave();
      return true;
    } on ApiException catch (error) {
      if (!mounted) return false;
      if (error.code == 'EXAM_ATTEMPT_CLOSED') {
        await load();
        return false;
      }
      _markSaveFailed(error.message);
      return false;
    } catch (error) {
      if (!mounted) return false;
      _markSaveFailed(error.toString());
      return false;
    } finally {
      _saveInFlight = null;
    }
  }

  Set<String> get _questionIds =>
      state.questions.map((question) => question.id).toSet();

  static bool _sameSelection(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _markSaveFailed(String detail) {
    if (!mounted) return;
    state = state.copyWith(
      saveStatus: ExamSaveStatus.failed,
      errorKey: () => 'exam_error_save',
      errorDetail: () => detail,
    );
    _saveRetries += 1;
    if (_saveRetries <= 3) {
      _saveDebounce?.cancel();
      _saveDebounce = Timer(Duration(seconds: _saveRetries * 2), () {
        unawaited(_saveNow(force: true));
      });
    }
  }

  /// Manual submission: refuses to submit when the latest answers could not
  /// be persisted, so the student never submits a stale answer sheet silently.
  Future<void> submit() async {
    if (!state.isActive || state.submitting || !mounted) return;
    state = state.copyWith(submitting: true, errorKey: () => null);
    _saveDebounce?.cancel();
    final saved = await _saveNow(force: true);
    if (!mounted) return;
    if (!saved && _dirty.isNotEmpty) {
      state = state.copyWith(
        submitting: false,
        errorKey: () => 'exam_error_save',
      );
      return;
    }
    try {
      final result = await repository.submitAttempt(examId);
      if (!mounted) return;
      _applyTerminal(
        result.attempt,
        autoSubmitted: result.autoSubmitted,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'EXAM_ATTEMPT_CLOSED') {
        await load();
        return;
      }
      state = state.copyWith(
        submitting: false,
        errorKey: () => 'exam_error_submit',
        errorDetail: () => error.message,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        submitting: false,
        errorKey: () => 'exam_error_submit',
        errorDetail: () => error.toString(),
      );
    }
  }

  Future<void> _autoSubmit() async {
    if (_autoSubmitStarted || state.submitting || !state.isActive || !mounted) {
      return;
    }
    _autoSubmitStarted = true;
    state = state.copyWith(submitting: true);
    _saveDebounce?.cancel();
    // Best effort: even if the last autosave fails, the server must still
    // finalise the expired attempt with the answers it already has.
    await _saveNow(force: true);
    if (!mounted) return;
    try {
      final result = await repository.submitAttempt(examId);
      if (!mounted) return;
      _autoSubmitStarted = false;
      _applyTerminal(result.attempt, autoSubmitted: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'EXAM_ATTEMPT_CLOSED') {
        await load();
        return;
      }
      _retryAutoSubmit(error.message);
    } catch (error) {
      if (!mounted) return;
      _retryAutoSubmit(error.toString());
    }
  }

  void _retryAutoSubmit(String detail) {
    _autoSubmitStarted = false;
    if (!mounted) return;
    _submitRetries += 1;
    if (_submitRetries > 12) {
      state = state.copyWith(
        submitting: false,
        errorKey: () => 'exam_error_submit',
        errorDetail: () => detail,
      );
      return;
    }
    state = state.copyWith(
      submitting: true,
      errorKey: () => 'exam_error_submit',
      errorDetail: () => detail,
    );
    _retrySubmit?.cancel();
    _retrySubmit = Timer(const Duration(seconds: 5), () {
      unawaited(_autoSubmit());
    });
  }

  void _applyTerminal(StudentAttempt attempt, {required bool autoSubmitted}) {
    _stopTicker();
    _saveDebounce?.cancel();
    _retrySubmit?.cancel();
    _deadline = null;
    _dirty.clear();
    if (!mounted) return;
    state = state.copyWith(
      phase: ExamAttemptPhase.completed,
      submitting: false,
      autoSubmitted: autoSubmitted || attempt.status == AttemptStatus.autoSubmitted,
      terminatedReason: () => attempt.terminatedReason,
      remainingMs: attempt.remainingMs,
      violationCount: attempt.violationCount,
      saveStatus: ExamSaveStatus.idle,
      errorKey: () => null,
      errorDetail: () => null,
    );
  }

  /// Reports one client signal. The returned decision is the backend's, never
  /// a local guess. Events are serialized so the termination order is exact.
  Future<RecordEventResult?> reportSignal(ExamSignalInput input) {
    if (!state.isActive) return Future<RecordEventResult?>.value();
    final previous = _eventChain ?? Future<void>.value();
    final completer = Completer<RecordEventResult?>();
    _eventChain = previous.then((_) async {
      if (!mounted || !state.isActive) {
        completer.complete(null);
        return;
      }
      try {
        final result = await repository.reportEvent(examId, input);
        if (!mounted) {
          completer.complete(null);
          return;
        }
        _applyRemaining(result.remainingMs);
        state = state.copyWith(
          violationCount: result.attempt.violationCount,
        );
        if (result.decision == ExamDecision.terminated ||
            result.attempt.status != AttemptStatus.inProgress) {
          _applyTerminal(
            result.attempt,
            autoSubmitted:
                result.attempt.status == AttemptStatus.autoSubmitted,
          );
        }
        completer.complete(result);
      } on ApiException catch (error) {
        if (!mounted) {
          completer.complete(null);
          return;
        }
        if (error.code == 'EXAM_ATTEMPT_CLOSED') {
          await load();
        }
        if (completer.isCompleted == false) {
          completer.complete(null);
        }
      } catch (_) {
        completer.complete(null);
      }
    });
    return completer.future;
  }

  Future<void> retryLoad() => load();

  bool get hasLoaded => _loaded;

  @override
  void dispose() {
    _ticker?.cancel();
    _saveDebounce?.cancel();
    _retrySubmit?.cancel();
    super.dispose();
  }
}
