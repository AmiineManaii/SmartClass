import { describe, expect, it } from 'vitest';
import type { Role } from '../../src/modules/auth/index.js';
import {
  ExamAttemptClosedError,
  ExamResultsNotAvailableError,
  ForbiddenError,
  ValidationError,
} from '../../src/shared/errors/app-error.js';
import { CreateExamUseCase } from '../../src/modules/exams/application/create-exam.use-case.js';
import { PublishExamUseCase } from '../../src/modules/exams/application/publish-exam.use-case.js';
import { CloseExamUseCase } from '../../src/modules/exams/application/close-exam.use-case.js';
import { StartAttemptUseCase } from '../../src/modules/exams/application/start-attempt.use-case.js';
import { SaveAnswersUseCase } from '../../src/modules/exams/application/save-answers.use-case.js';
import { SubmitAttemptUseCase } from '../../src/modules/exams/application/submit-attempt.use-case.js';
import { GetStudentResultUseCase } from '../../src/modules/exams/application/get-student-result.use-case.js';
import { RecordEventUseCase } from '../../src/modules/exams/application/record-event.use-case.js';
import { ListAvailableExamsUseCase } from '../../src/modules/exams/application/list-available-exams.use-case.js';
import { FakeExamRepository, examSettings } from './exams.test-helpers.js';

const TEACHER: Role = 'TEACHER';
const CLASS_ID = 'class-1';
const TEACHER_ID = 'teacher-1';
const STUDENT_ID = 'student-1';

const setup = (): FakeExamRepository => {
  const repo = new FakeExamRepository();
  repo.addClass(CLASS_ID, '3e A');
  repo.allowTeacher(TEACHER_ID, CLASS_ID);
  repo.enroll(STUDENT_ID, CLASS_ID);
  return repo;
};

const createDto = (overrides: Record<string, unknown> = {}) => {
  const now = new Date();
  return {
    requesterId: TEACHER_ID,
    requesterRole: TEACHER,
    title: 'Contrôle de mathématiques',
    description: 'Chapitre 2',
    classGroupId: CLASS_ID,
    durationMinutes: 30,
    startsAt: new Date(now.getTime() - 60_000),
    endsAt: new Date(now.getTime() + 3_600_000),
    questions: [
      {
        prompt: 'Combien font 2 + 2 ?',
        options: ['3', '4', '5'],
        correctOptionId: 'B',
        points: 2,
      },
      {
        prompt: 'Combien font 3 x 3 ?',
        options: ['6', '9', '12'],
        correctOptionId: 'B',
        points: 2,
      },
    ],
    ...overrides,
  };
};

const createPublishedExam = async (
  repo: FakeExamRepository,
  overrides: Record<string, unknown> = {},
) => {
  const create = new CreateExamUseCase(repo);
  const publish = new PublishExamUseCase(repo);
  const exam = await create.execute(createDto(overrides) as never);
  return publish.execute({
    requesterId: TEACHER_ID,
    requesterRole: TEACHER,
    examId: exam.id,
  });
};

describe('teacher exam authoring', () => {
  it('creates a draft with server-normalized options and total points', async () => {
    const repo = setup();
    const exam = await new CreateExamUseCase(repo).execute(createDto() as never);
    expect(exam.status).toBe('DRAFT');
    expect(exam.questions).toHaveLength(2);
    expect(exam.questions[0]?.options.map((option) => option.id)).toEqual(['A', 'B', 'C']);
    expect(exam.questions[0]?.correctOptionIds).toEqual(['B']);
    expect(exam.totalPoints).toBe(4);
  });

  it('refuses a teacher who does not teach the class', async () => {
    const repo = setup();
    await expect(
      new CreateExamUseCase(repo).execute(
        createDto({ requesterId: 'teacher-2' }) as never,
      ),
    ).rejects.toBeInstanceOf(ForbiddenError);
  });

  it('refuses a question without exactly one correct answer', async () => {
    const repo = setup();
    await expect(
      new CreateExamUseCase(repo).execute(
        createDto({
          questions: [
            {
              prompt: 'Question',
              options: ['A', 'B'],
              correctOptionIds: ['A', 'B'],
            },
          ],
        }) as never,
      ),
    ).rejects.toBeInstanceOf(ValidationError);
  });
});

describe('student attempt lifecycle', () => {
  it('starts, saves, submits and reveals the score only after the teacher closes', async () => {
    const repo = setup();
    const exam = await createPublishedExam(repo);
    const start = await new StartAttemptUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
    });

    expect(start.attempt.status).toBe('IN_PROGRESS');
    expect(start.exam.questions).toHaveLength(2);
    expect(start.exam.questions[0]).not.toHaveProperty('correctOptionIds');
    expect(start.exam.questions[0]).not.toHaveProperty('explanation');

    const firstQuestionId = start.exam.questions[0]?.id as string;
    await new SaveAnswersUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
      answers: [{ questionId: firstQuestionId, selectedOptionIds: ['B'] }],
    });

    const submitted = await new SubmitAttemptUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
    });
    expect(submitted.attempt.status).toBe('SUBMITTED');
    expect(submitted.autoSubmitted).toBe(false);

    await expect(
      new GetStudentResultUseCase(repo).execute({
        studentId: STUDENT_ID,
        examId: exam.id,
        requesterRole: 'STUDENT',
      }),
    ).rejects.toBeInstanceOf(ExamResultsNotAvailableError);

    await new CloseExamUseCase(repo).execute({
      requesterId: TEACHER_ID,
      requesterRole: TEACHER,
      examId: exam.id,
    });

    const result = await new GetStudentResultUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
      requesterRole: 'STUDENT',
    });
    expect(result.score).toBe(2);
    expect(result.maxScore).toBe(4);
    expect(result.correctCount).toBe(1);
    expect(result.items[0]?.correct).toBe(true);
    expect(JSON.stringify(result)).not.toContain('correctOptionIds');
    expect(JSON.stringify(result)).not.toContain('Because');
  });

  it('blocks a second submission', async () => {
    const repo = setup();
    const exam = await createPublishedExam(repo);
    await new StartAttemptUseCase(repo).execute({ studentId: STUDENT_ID, examId: exam.id });
    await new SubmitAttemptUseCase(repo).execute({ studentId: STUDENT_ID, examId: exam.id });
    await expect(
      new SubmitAttemptUseCase(repo).execute({ studentId: STUDENT_ID, examId: exam.id }),
    ).rejects.toBeInstanceOf(ExamAttemptClosedError);
  });

  it('refuses a student outside the class (IDOR)', async () => {
    const repo = setup();
    const exam = await createPublishedExam(repo);
    await expect(
      new StartAttemptUseCase(repo).execute({ studentId: 'student-2', examId: exam.id }),
    ).rejects.toBeInstanceOf(ForbiddenError);
  });

  it('auto-submits and closes the attempt once the server deadline passed', async () => {
    const repo = setup();
    const exam = await createPublishedExam(repo);
    const now = new Date();
    const start = await new StartAttemptUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
      now,
    });
    const questionId = start.exam.questions[0]?.id as string;
    const late = new Date(now.getTime() + 31 * 60_000);
    await expect(
      new SaveAnswersUseCase(repo).execute({
        studentId: STUDENT_ID,
        examId: exam.id,
        answers: [{ questionId, selectedOptionIds: ['B'] }],
        now: late,
      }),
    ).rejects.toBeInstanceOf(ExamAttemptClosedError);

    const attempt = repo.attempts.get(start.attempt.id);
    expect(attempt?.status).toBe('AUTO_SUBMITTED');
  });

  it('lists availability and the attempt state for a student', async () => {
    const repo = setup();
    const exam = await createPublishedExam(repo);
    const before = await new ListAvailableExamsUseCase(repo).execute({ studentId: STUDENT_ID });
    expect(before[0]).toMatchObject({ id: exam.id, availability: 'ACTIVE', canStart: true });

    await new StartAttemptUseCase(repo).execute({ studentId: STUDENT_ID, examId: exam.id });
    const after = await new ListAvailableExamsUseCase(repo).execute({ studentId: STUDENT_ID });
    expect(after[0]).toMatchObject({ canStart: false, canResume: true });
    expect(after[0]?.remainingMs).toBeGreaterThan(0);
  });
});

describe('anti-fraud event ingestion', () => {
  it('records a network interruption without sanctioning the student', async () => {
    const repo = setup();
    const exam = await createPublishedExam(repo);
    const start = await new StartAttemptUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
    });
    const result = await new RecordEventUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
      type: 'NETWORK_LOST',
      source: 'web',
    });
    expect(result.decision).toBe('NONE');
    expect(result.attempt.status).toBe('IN_PROGRESS');
    expect(repo.attempts.get(start.attempt.id)?.violationCount).toBe(0);
  });

  it('terminates a confirmed tab exit', async () => {
    const repo = setup();
    const exam = await createPublishedExam(repo);
    const start = await new StartAttemptUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
    });
    const result = await new RecordEventUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
      type: 'TAB_HIDDEN',
      durationMs: null,
      source: 'web',
    });
    expect(result.decision).toBe('TERMINATED');
    expect(repo.attempts.get(start.attempt.id)?.status).toBe('TERMINATED');
    expect(result.attempt.terminatedReason).toContain('confirmed_exit');
  });

  it('warns once then terminates when copy/paste repeats', async () => {
    const repo = setup();
    const exam = await createPublishedExam(repo, {
      settings: examSettings({ maxViolationCount: 2 }),
    });
    const start = await new StartAttemptUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
    });
    const first = await new RecordEventUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
      type: 'COPY_ATTEMPT',
    });
    expect(first.decision).toBe('WARNING');
    const second = await new RecordEventUseCase(repo).execute({
      studentId: STUDENT_ID,
      examId: exam.id,
      type: 'PASTE_ATTEMPT',
    });
    expect(second.decision).toBe('TERMINATED');
    expect(repo.attempts.get(start.attempt.id)?.status).toBe('TERMINATED');
  });
});
