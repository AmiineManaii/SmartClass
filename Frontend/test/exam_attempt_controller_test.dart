import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/features/exams/application/controllers/exam_attempt_controller.dart';
import 'package:smartclass/features/exams/domain/entities/exam_attempt.dart';
import 'package:smartclass/features/exams/domain/entities/exam_definition.dart';
import 'package:smartclass/features/exams/domain/entities/exam_monitoring.dart';
import 'package:smartclass/features/exams/domain/repositories/exam_repository.dart';

/// Only the student lifecycle methods are exercised here; every other
/// repository member is intentionally unsupported.
class _FakeExamRepository implements ExamRepository {
  _FakeExamRepository({
    required this.session,
    required this.savedResult,
    required this.submitResult,
    this.eventResult,
  });

  final AttemptSession session;
  final SaveAnswersResult Function() savedResult;
  final SubmitAttemptResult Function() submitResult;
  final RecordEventResult? eventResult;

  final List<List<StudentAnswerInput>> saves = <List<StudentAnswerInput>>[];
  final List<ExamSignalInput> events = <ExamSignalInput>[];
  final List<String> calls = <String>[];

  @override
  Future<AttemptSession> startAttempt(String examId) async {
    calls.add('start');
    return session;
  }

  @override
  Future<SaveAnswersResult> saveAnswers(
    String examId,
    List<StudentAnswerInput> answers,
  ) async {
    calls.add('save');
    saves.add(answers);
    return savedResult();
  }

  @override
  Future<SubmitAttemptResult> submitAttempt(String examId) async {
    calls.add('submit');
    return submitResult();
  }

  @override
  Future<RecordEventResult> reportEvent(String examId, ExamSignalInput input) async {
    calls.add('event');
    events.add(input);
    return eventResult!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AttemptSession _session({
  AttemptStatus status = AttemptStatus.inProgress,
  bool canResume = true,
  int remainingMs = 60000,
  String? terminatedReason,
}) {
  final now = DateTime.now();
  return AttemptSession(
    exam: StudentExam(
      id: 'exam-1',
      title: 'Contrôle',
      durationMinutes: 60,
      startsAt: now.subtract(const Duration(minutes: 1)),
      endsAt: now.add(const Duration(hours: 1)),
      status: ExamStatus.published,
      settings: const ExamSettings(),
      questionCount: 1,
      totalPoints: 2,
      serverNow: now,
      questions: const <StudentQuestion>[
        StudentQuestion(
          id: 'q1',
          order: 1,
          type: ExamQuestionType.singleChoice,
          prompt: 'Question ?',
          options: <ExamOption>[
            ExamOption(id: 'A', text: 'A'),
            ExamOption(id: 'B', text: 'B'),
          ],
          points: 2,
        ),
      ],
    ),
    attempt: StudentAttempt(
      id: 'attempt-1',
      examId: 'exam-1',
      status: status,
      startedAt: now.subtract(const Duration(minutes: 1)),
      expiresAt: now.add(Duration(milliseconds: remainingMs)),
      remainingMs: remainingMs,
      violationCount: 0,
      terminatedReason: terminatedReason,
    ),
    answers: const <StudentAnswer>[],
    resumed: true,
    canResume: canResume,
    serverNow: now,
  );
}

void main() {
  late _FakeExamRepository repository;
  late ExamAttemptController controller;

  ExamAttemptController buildController() {
    controller = ExamAttemptController(repository: repository, examId: 'exam-1');
    return controller;
  }

  setUp(() {
    repository = _FakeExamRepository(
      session: _session(),
      savedResult: () => SaveAnswersResult(
        savedAt: DateTime.now(),
        answers: const <StudentAnswer>[],
        remainingMs: 59000,
        serverNow: DateTime.now(),
      ),
      submitResult: () => SubmitAttemptResult(
        attempt: StudentAttempt(
          id: 'attempt-1',
          examId: 'exam-1',
          status: AttemptStatus.submitted,
          startedAt: DateTime.now(),
          expiresAt: DateTime.now(),
          remainingMs: 55000,
          violationCount: 0,
        ),
        autoSubmitted: false,
        serverNow: DateTime.now(),
      ),
    );
  });

  tearDown(() {
    if (controller.mounted) controller.dispose();
  });

  test('load resumes the server attempt and seeds every question', () async {
    buildController();
    await controller.load();

    expect(controller.state.isActive, isTrue);
    expect(controller.state.remainingMs, 60000);
    expect(controller.state.answers.keys, <String>['q1']);
    expect(controller.state.answers['q1'], isEmpty);
    expect(repository.calls, <String>['start']);
  });

  test('selecting an option autosaves it after the debounce', () async {
    buildController();
    await controller.load();

    controller.selectOption('q1', 'A');
    expect(controller.isSelected('q1', 'A'), isTrue);
    expect(repository.saves, isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 900));

    expect(repository.saves, hasLength(1));
    expect(repository.saves.single.single.questionId, 'q1');
    expect(repository.saves.single.single.selectedOptionIds, <String>['A']);
    expect(controller.state.saveStatus, ExamSaveStatus.saved);
  });

  test('submit flushes dirty answers before calling the backend', () async {
    buildController();
    await controller.load();

    controller.selectOption('q1', 'B');
    await controller.submit();

    expect(repository.calls, <String>['start', 'save', 'submit']);
    expect(controller.state.phase, ExamAttemptPhase.completed);
  });

  test('a backend termination decision ends the attempt', () async {
    final now = DateTime.now();
    repository = _FakeExamRepository(
      session: _session(),
      savedResult: () => SaveAnswersResult(
        savedAt: now,
        answers: const <StudentAnswer>[],
        remainingMs: 59000,
        serverNow: now,
      ),
      submitResult: () => throw UnimplementedError(),
      eventResult: RecordEventResult(
        event: ExamEvent(
          id: 'event-1',
          attemptId: 'attempt-1',
          examId: 'exam-1',
          studentId: 'student-1',
          type: ExamEventType.tabHidden,
          severity: ExamSeverity.high,
          state: ExamEventState.confirmed,
          occurredAt: now,
          source: 'client',
          metadata: const <String, dynamic>{},
          decision: ExamDecision.terminated,
          createdAt: now,
        ),
        attempt: StudentAttempt(
          id: 'attempt-1',
          examId: 'exam-1',
          status: AttemptStatus.terminated,
          startedAt: now,
          expiresAt: now,
          remainingMs: 0,
          violationCount: 1,
          terminatedReason: 'confirmed_exit:TAB_HIDDEN',
        ),
        decision: ExamDecision.terminated,
        severity: ExamSeverity.high,
        remainingMs: 0,
        serverNow: now,
      ),
    );
    buildController();
    await controller.load();

    await controller.reportSignal(
      const ExamSignalInput(type: ExamEventType.tabHidden, durationMs: null),
    );

    expect(controller.state.isCompleted, isTrue);
    expect(controller.state.terminatedReason, 'confirmed_exit:TAB_HIDDEN');
    expect(controller.state.violationCount, 1);
  });
}
