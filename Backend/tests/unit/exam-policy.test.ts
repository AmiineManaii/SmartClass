import { describe, expect, it } from 'vitest';
import {
  computeExpiresAt,
  countsAsViolation,
  decideSanction,
  gradeAttempt,
  isAnswerAllowed,
  remainingMs,
} from '../../src/modules/exams/domain/exam-policy.js';
import { makeQuestion, examSettings } from './exams.test-helpers.js';

describe('exam timer policy', () => {
  it('caps the attempt at min(start + duration, exam end)', () => {
    const startedAt = new Date('2026-01-01T10:00:00Z');
    expect(
      computeExpiresAt(startedAt, 30, new Date('2026-01-01T10:20:00Z')).toISOString(),
    ).toBe('2026-01-01T10:20:00.000Z');
    expect(
      computeExpiresAt(startedAt, 30, new Date('2026-01-01T11:00:00Z')).toISOString(),
    ).toBe('2026-01-01T10:30:00.000Z');
  });

  it('never returns negative remaining time', () => {
    const expiresAt = new Date('2026-01-01T10:00:00Z');
    expect(remainingMs(expiresAt, new Date('2026-01-01T09:59:00Z'))).toBe(60_000);
    expect(remainingMs(expiresAt, new Date('2026-01-01T10:01:00Z'))).toBe(0);
  });
});

describe('server-side grading', () => {
  it('awards points only for the exact single choice', () => {
    const questions = [
      makeQuestion('q1', ['A'], 2),
      makeQuestion('q2', ['C'], 3),
    ];
    const result = gradeAttempt(questions, [
      { questionId: 'q1', selectedOptionIds: ['A'], savedAt: new Date() },
      { questionId: 'q2', selectedOptionIds: ['B'], savedAt: new Date() },
    ]);
    expect(result.score).toBe(2);
    expect(result.maxScore).toBe(5);
    expect(result.correctCount).toBe(1);
    expect(result.graded).toEqual([
      { questionId: 'q1', correct: true, pointsAwarded: 2, pointsMax: 2 },
      { questionId: 'q2', correct: false, pointsAwarded: 0, pointsMax: 3 },
    ]);
  });

  it('rejects two selected options on a single-choice question', () => {
    const question = makeQuestion('q1', ['A']);
    expect(isAnswerAllowed(question, ['A', 'B'])).toBe(false);
    expect(isAnswerAllowed(question, ['A'])).toBe(true);
    expect(isAnswerAllowed(question, [])).toBe(true);
    expect(isAnswerAllowed(question, ['Z'])).toBe(false);
  });
});

describe('anti-fraud sanction policy', () => {
  const settings = examSettings({ maxViolationCount: 3 });

  it('never sanctions a network interruption', () => {
    const result = decideSanction({
      type: 'NETWORK_LOST',
      durationMs: null,
      previousViolations: 0,
      settings,
    });
    expect(result.decision).toBe('NONE');
    expect(result.severity).toBe('LOW');
  });

  it('terminates a confirmed environment exit on first occurrence', () => {
    expect(
      decideSanction({ type: 'TAB_HIDDEN', durationMs: null, previousViolations: 0, settings })
        .decision,
    ).toBe('TERMINATED');
    expect(
      decideSanction({ type: 'APP_BACKGROUND', durationMs: 4000, previousViolations: 0, settings })
        .decision,
    ).toBe('TERMINATED');
  });

  it('only warns for an exit shorter than the grace period', () => {
    const result = decideSanction({
      type: 'TAB_HIDDEN',
      durationMs: 500,
      previousViolations: 0,
      settings,
    });
    expect(result.decision).toBe('WARNING');
    expect(result.severity).toBe('MEDIUM');
  });

  it('terminates repeated copy/paste attempts at the configured limit', () => {
    expect(
      decideSanction({ type: 'COPY_ATTEMPT', durationMs: null, previousViolations: 0, settings })
        .decision,
    ).toBe('WARNING');
    expect(
      decideSanction({ type: 'PASTE_ATTEMPT', durationMs: null, previousViolations: 1, settings })
        .decision,
    ).toBe('WARNING');
    expect(
      decideSanction({ type: 'COPY_ATTEMPT', durationMs: null, previousViolations: 2, settings })
        .decision,
    ).toBe('TERMINATED');
  });

  it('keeps focus/gaze signals as low-severity warnings', () => {
    for (const type of ['FOCUS_LOST', 'GAZE_OFF_SCREEN'] as const) {
      const result = decideSanction({ type, durationMs: null, previousViolations: 10, settings });
      expect(result.decision).toBe('WARNING');
      expect(result.severity).toBe('LOW');
    }
  });

  it('counts only copy/paste and screenshot attempts as violations', () => {
    expect(countsAsViolation('COPY_ATTEMPT')).toBe(true);
    expect(countsAsViolation('SCREENSHOT_ATTEMPT')).toBe(true);
    expect(countsAsViolation('TAB_HIDDEN')).toBe(false);
    expect(countsAsViolation('FOCUS_LOST')).toBe(false);
  });
});
