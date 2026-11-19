import { ValidationError } from '../../../shared/errors/app-error.js';
import type { CreateExamQuestionInput } from '../domain/exam-repository.port.js';

const OPTION_IDS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

const optionIdForIndex = (index: number): string =>
  index < OPTION_IDS.length ? (OPTION_IDS[index] as string) : `O${index + 1}`;

const asOptionalString = (value: unknown, maxLength: number): string | null => {
  if (value === null || value === undefined) return null;
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (trimmed.length === 0) return null;
  return trimmed.slice(0, maxLength);
};

const resolveOptionId = (raw: string, options: { id: string; text: string }[]): string | null => {
  const value = raw.trim();
  if (value.length === 0) return null;
  const byId = options.find((option) => option.id === value);
  if (byId) return byId.id;
  const upper = value.toUpperCase();
  const byUpperId = options.find((option) => option.id.toUpperCase() === upper);
  if (byUpperId) return byUpperId.id;
  const byText = options.find(
    (option) => option.text.trim().toLowerCase() === value.toLowerCase(),
  );
  return byText ? byText.id : null;
};

const parseOptions = (
  raw: unknown,
  index: number,
): { id: string; text: string }[] => {
  if (!Array.isArray(raw)) {
    throw new ValidationError('Question options are required', [
      { path: `questions.${index}.options`, message: 'Expected an array of at least 2 options' },
    ]);
  }
  const seen = new Set<string>();
  const options: { id: string; text: string }[] = [];
  raw.forEach((entry, optionIndex) => {
    let id = optionIdForIndex(optionIndex);
    let text = '';
    if (typeof entry === 'string') {
      text = entry.trim();
    } else if (entry && typeof entry === 'object') {
      const candidate = entry as Record<string, unknown>;
      if (typeof candidate.id === 'string' && candidate.id.trim().length > 0) {
        id = candidate.id.trim().slice(0, 8);
      }
      if (typeof candidate.text === 'string') {
        text = candidate.text.trim();
      }
    }
    if (!text) {
      throw new ValidationError('Every option needs text', [
        { path: `questions.${index}.options.${optionIndex}`, message: 'Option text is empty' },
      ]);
    }
    const uniqueId = seen.has(id) ? optionIdForIndex(options.length) : id;
    seen.add(uniqueId);
    options.push({ id: uniqueId, text: text.slice(0, 2000) });
  });

  if (options.length < 2) {
    throw new ValidationError('A question needs at least 2 options', [
      { path: `questions.${index}.options`, message: 'Provide 2 to 8 options' },
    ]);
  }
  if (options.length > 8) {
    throw new ValidationError('A question has too many options', [
      { path: `questions.${index}.options`, message: 'Maximum 8 options per question' },
    ]);
  }
  return options;
};

const parseCorrectIds = (
  raw: Record<string, unknown>,
  options: { id: string; text: string }[],
  index: number,
): string[] => {
  const candidates: unknown[] = [];
  if (Array.isArray(raw.correctOptionIds)) candidates.push(...raw.correctOptionIds);
  if (Array.isArray(raw.correctOptions)) candidates.push(...raw.correctOptions);
  if (raw.correctOptionId !== undefined) candidates.push(raw.correctOptionId);
  if (raw.answer !== undefined) candidates.push(raw.answer);
  if (raw.correctAnswer !== undefined) candidates.push(raw.correctAnswer);

  const resolved: string[] = [];
  for (const candidate of candidates) {
    if (typeof candidate === 'number' && Number.isInteger(candidate)) {
      const option = options[candidate];
      if (option) resolved.push(option.id);
      continue;
    }
    if (typeof candidate !== 'string') continue;
    const direct = resolveOptionId(candidate, options);
    if (direct) {
      resolved.push(direct);
    }
  }

  const unique = Array.from(new Set(resolved));
  if (unique.length !== 1) {
    throw new ValidationError('A single-choice question needs exactly one correct answer', [
      {
        path: `questions.${index}.correctOptionIds`,
        message: 'Provide one correct option id (or use correctOptionId / answer)',
      },
    ]);
  }
  return unique;
};

const parsePoints = (raw: unknown, index: number): number => {
  if (raw === undefined || raw === null) return 1;
  const value = typeof raw === 'string' ? Number.parseInt(raw, 10) : raw;
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new ValidationError('Question points must be a number', [
      { path: `questions.${index}.points`, message: 'Expected an integer between 1 and 100' },
    ]);
  }
  const points = Math.trunc(value);
  if (points < 1 || points > 100) {
    throw new ValidationError('Question points are out of range', [
      { path: `questions.${index}.points`, message: 'Expected an integer between 1 and 100' },
    ]);
  }
  return points;
};

/**
 * Validates a teacher-provided / imported / AI-generated question list.
 * Option ids are normalized to A, B, C… so the student client only ever
 * submits stable server-owned ids. Correct answers stay server-side.
 */
export const normalizeQuestionInputs = (
  raw: unknown,
  options: { min?: number; max?: number } = {},
): CreateExamQuestionInput[] => {
  if (!Array.isArray(raw)) {
    throw new ValidationError('Exam questions are required', [
      { path: 'questions', message: 'Expected an array of questions' },
    ]);
  }
  const min = options.min ?? 1;
  const max = options.max ?? 200;
  if (raw.length < min) {
    throw new ValidationError('The exam needs at least one question', [
      { path: 'questions', message: `Provide at least ${min} question(s)` },
    ]);
  }
  if (raw.length > max) {
    throw new ValidationError('The exam has too many questions', [
      { path: 'questions', message: `Maximum ${max} questions per exam` },
    ]);
  }

  return raw.map((entry, index) => {
    if (!entry || typeof entry !== 'object') {
      throw new ValidationError('Invalid question payload', [
        { path: `questions.${index}`, message: 'Expected an object' },
      ]);
    }
    const candidate = entry as Record<string, unknown>;
    const prompt = typeof candidate.prompt === 'string' ? candidate.prompt.trim() : '';
    if (!prompt) {
      throw new ValidationError('Question prompt is required', [
        { path: `questions.${index}.prompt`, message: 'Prompt is empty' },
      ]);
    }
    const questionOptions = parseOptions(candidate.options, index);
    const correctOptionIds = parseCorrectIds(candidate, questionOptions, index);
    return {
      prompt: prompt.slice(0, 5000),
      hint: asOptionalString(candidate.hint, 2000),
      options: questionOptions,
      correctOptionIds,
      explanation: asOptionalString(candidate.explanation, 5000),
      points: parsePoints(candidate.points, index),
      type: 'SINGLE_CHOICE' as const,
    };
  });
};
