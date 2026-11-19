import { ValidationError } from '../../../shared/errors/app-error.js';
import { ImportFormatUnsupportedError } from '../../../shared/errors/app-error.js';
import type { CreateExamQuestionInput } from '../domain/exam-repository.port.js';
import { normalizeQuestionInputs } from '../application/exam-input.js';

export interface ExamImportFile {
  originalname: string;
  mimetype: string;
  buffer: Buffer;
}

export interface ImportedExamPreview {
  title: string;
  description: string | null;
  sourceFormat: 'json' | 'csv' | 'txt';
  questions: CreateExamQuestionInput[];
}

const extensionOf = (name: string): string => {
  const index = name.lastIndexOf('.');
  return index >= 0 ? name.slice(index + 1).toLowerCase() : '';
};

const asString = (value: unknown): string => (typeof value === 'string' ? value.trim() : '');

const optionIdAt = (index: number): string => String.fromCharCode(65 + index);

const toRawQuestions = (questions: unknown[]): unknown[] => questions;

const parseJson = (buffer: Buffer): ImportedExamPreview => {
  let parsed: unknown;
  try {
    parsed = JSON.parse(buffer.toString('utf8'));
  } catch {
    throw new ValidationError('The JSON file is not valid JSON', [
      { path: 'file', message: 'Fix the JSON syntax and retry' },
    ]);
  }
  const container =
    parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? (parsed as Record<string, unknown>)
      : {};
  const rawQuestions = Array.isArray(parsed)
    ? parsed
    : Array.isArray(container.questions)
      ? container.questions
      : null;
  if (!rawQuestions) {
    throw new ValidationError('The JSON file contains no question list', [
      { path: 'file', message: 'Expected { "questions": [...] } or a questions array' },
    ]);
  }
  return {
    title: asString(container.title) || 'Examen importé',
    description: asString(container.description) || null,
    sourceFormat: 'json',
    questions: normalizeQuestionInputs(toRawQuestions(rawQuestions)),
  };
};

const splitCsvLine = (line: string, delimiter: string): string[] => {
  const cells: string[] = [];
  let current = '';
  let quoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const char = line[index] as string;
    if (char === '"') {
      if (quoted && line[index + 1] === '"') {
        current += '"';
        index += 1;
      } else {
        quoted = !quoted;
      }
      continue;
    }
    if (char === delimiter && !quoted) {
      cells.push(current.trim());
      current = '';
      continue;
    }
    current += char;
  }
  cells.push(current.trim());
  return cells;
};

const normalizeHeader = (value: string): string =>
  value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');

const parseCsv = (buffer: Buffer): ImportedExamPreview => {
  const text = buffer.toString('utf8').replace(/^\uFEFF/, '');
  const lines = text.split(/\r?\n/).filter((line) => line.trim().length > 0);
  if (lines.length < 1) {
    throw new ValidationError('The CSV file is empty', [
      { path: 'file', message: 'Provide a header row and at least one question' },
    ]);
  }
  const delimiter = lines[0]?.includes(';') ? ';' : lines[0]?.includes('\t') ? '\t' : ',';
  const header = splitCsvLine(lines[0] as string, delimiter).map(normalizeHeader);
  const hasHeader = header.some((cell) =>
    ['question', 'prompt', 'enonce', 'intitule'].includes(cell),
  );
  const dataLines = hasHeader ? lines.slice(1) : lines;
  if (dataLines.length === 0) {
    throw new ValidationError('The CSV file has no question rows', [
      { path: 'file', message: 'Add at least one question row below the header' },
    ]);
  }
  const columns = hasHeader ? header : [];

  const promptIndex = hasHeader
    ? columns.findIndex((cell) => ['question', 'prompt', 'enonce', 'intitule'].includes(cell))
    : 0;
  const correctIndex = hasHeader
    ? columns.findIndex((cell) => ['correct', 'answer', 'reponse', 'bonne'].includes(cell))
    : -1;
  const pointsIndex = hasHeader
    ? columns.findIndex((cell) => ['points', 'point', 'score'].includes(cell))
    : -1;
  const hintIndex = hasHeader
    ? columns.findIndex((cell) => ['hint', 'indice'].includes(cell))
    : -1;
  const explanationIndex = hasHeader
    ? columns.findIndex((cell) => ['explanation', 'explication'].includes(cell))
    : -1;

  const optionColumns: number[] = [];
  if (hasHeader) {
    columns.forEach((cell, index) => {
      const match = cell.match(/^(option|choix|reponse)?([a-h])$/) ?? cell.match(/^option([a-h])$/);
      if (match) optionColumns.push(index);
    });
  }
  const effectiveOptionColumns =
    optionColumns.length >= 2
      ? optionColumns
      : columns.map((_, index) => index).filter((index) => ![
          promptIndex,
          correctIndex,
          pointsIndex,
          hintIndex,
          explanationIndex,
        ].includes(index));

  const questions = dataLines.map((line, lineIndex) => {
    const cells = splitCsvLine(line, delimiter);
    const prompt = cells[promptIndex] ?? '';
    const optionCells = hasHeader
      ? effectiveOptionColumns
          .map((index) => cells[index] ?? '')
          .filter((value) => value.length > 0)
      : cells.slice(1).slice(0, -1).filter((value) => value.length > 0);
    const correctRaw = hasHeader
      ? correctIndex >= 0
        ? cells[correctIndex] ?? ''
        : ''
      : cells[cells.length - 1] ?? '';
    if (optionCells.length < 2) {
      throw new ValidationError(`CSV row ${lineIndex + (hasHeader ? 2 : 1)} has fewer than 2 options`, [
        { path: 'file', message: `Row ${lineIndex + (hasHeader ? 2 : 1)}: provide at least 2 options` },
      ]);
    }
    const options = optionCells.map((text, index) => ({ id: optionIdAt(index), text }));
    let correctOptionId = correctRaw.trim();
    if (/^\d+$/.test(correctOptionId)) {
      const numeric = Number.parseInt(correctOptionId, 10);
      correctOptionId = optionIdAt(Math.max(0, numeric - 1));
    }
    return {
      prompt,
      hint: hintIndex >= 0 ? cells[hintIndex] ?? null : null,
      options,
      correctOptionId: correctOptionId.toUpperCase(),
      explanation: explanationIndex >= 0 ? cells[explanationIndex] ?? null : null,
      points: pointsIndex >= 0 ? cells[pointsIndex] : undefined,
    };
  });

  return {
    title: hasHeader ? 'Examen importé (CSV)' : 'Examen importé',
    description: null,
    sourceFormat: 'csv',
    questions: normalizeQuestionInputs(questions),
  };
};

const cleanOptionLine = (line: string): { text: string; correct: boolean; id: string | null } => {
  let text = line.trim();
  let correct = false;
  if (text.startsWith('*')) {
    correct = true;
    text = text.slice(1).trim();
  }
  const letterMatch = text.match(/^([A-Ha-h])\s*[).:-]\s*(.+)$/);
  const id = letterMatch?.[1] ? (letterMatch[1] as string).toUpperCase() : null;
  if (letterMatch?.[2]) text = letterMatch[2].trim();
  if (/\((correct|bonne|vrai)\)$/i.test(text)) {
    correct = true;
    text = text.replace(/\((correct|bonne|vrai)\)$/i, '').trim();
  }
  return { text, correct, id };
};

const parseTxt = (buffer: Buffer): ImportedExamPreview => {
  const lines = buffer
    .toString('utf8')
    .replace(/^\uFEFF/, '')
    .split(/\r?\n/);

  // Single-line pipe format: "Question | A | B | C | B"
  const pipeLines = lines.filter((line) => line.split('|').length >= 3);
  if (pipeLines.length > 0 && pipeLines.length === lines.filter((l) => l.trim()).length) {
    const questions = pipeLines.map((line, index) => {
      const cells = line.split('|').map((cell) => cell.trim()).filter((cell) => cell.length > 0);
      const prompt = cells.shift() ?? '';
      const answer = cells.pop() ?? '';
      if (cells.length < 2) {
        throw new ValidationError(`Question ${index + 1} needs at least 2 options`, [
          { path: 'file', message: 'Use "Question | A | B | B" format' },
        ]);
      }
      return {
        prompt,
        options: cells.map((text, optionIndex) => ({ id: optionIdAt(optionIndex), text })),
        correctOptionId: /^\d+$/.test(answer)
          ? optionIdAt(Math.max(0, Number.parseInt(answer, 10) - 1))
          : answer.toUpperCase(),
      };
    });
    return {
      title: 'Examen importé (texte)',
      description: null,
      sourceFormat: 'txt',
      questions: normalizeQuestionInputs(questions),
    };
  }

  const blocks: string[][] = [];
  let current: string[] = [];
  for (const line of lines) {
    if (line.trim().length === 0) {
      if (current.length > 0) {
        blocks.push(current);
        current = [];
      }
      continue;
    }
    current.push(line);
  }
  if (current.length > 0) blocks.push(current);

  const questions = blocks.map((block, blockIndex) => {
    let prompt = '';
    let hint: string | null = null;
    let explanation: string | null = null;
    let points: string | undefined;
    let explicitAnswer: string | null = null;
    const options: { id: string; text: string }[] = [];
    let markedCorrect: string | null = null;

    for (const rawLine of block) {
      const line = rawLine.trim();
      const labelled = line.match(/^(question|enonce|intitule|q)\s*[:-]\s*(.+)$/i);
      if (labelled?.[2]) {
        prompt = labelled[2].trim();
        continue;
      }
      const hintMatch = line.match(/^(indice|hint)\s*[:-]\s*(.+)$/i);
      if (hintMatch?.[2]) {
        hint = hintMatch[2].trim();
        continue;
      }
      const explanationMatch = line.match(/^(explication|explanation)\s*[:-]\s*(.+)$/i);
      if (explanationMatch?.[2]) {
        explanation = explanationMatch[2].trim();
        continue;
      }
      const answerMatch = line.match(/^(answer|reponse|réponse|correct)\s*[:-]\s*(.+)$/i);
      if (answerMatch?.[2]) {
        explicitAnswer = answerMatch[2].trim();
        continue;
      }
      const pointsMatch = line.match(/^(points?|score)\s*[:-]\s*(\d+)$/i);
      if (pointsMatch?.[2]) {
        points = pointsMatch[2];
        continue;
      }
      const option = cleanOptionLine(line);
      if (option.text) {
        const id = option.id ?? optionIdAt(options.length);
        options.push({ id, text: option.text });
        if (option.correct) markedCorrect = id;
      }
      if (!prompt && options.length === 0 && line.length > 0) {
        prompt = line;
      }
    }

    if (!prompt && block[0]) prompt = block[0].trim();
    if (options.length === 0) {
      throw new ValidationError(`Question ${blockIndex + 1} has no options`, [
        { path: 'file', message: 'Add option lines such as "A) ..." and mark the correct one with *' },
      ]);
    }
    const correct = explicitAnswer ?? markedCorrect;
    if (!correct) {
      throw new ValidationError(`Question ${blockIndex + 1} has no correct answer`, [
        { path: 'file', message: 'Add "Answer: B" or prefix the right option with *' },
      ]);
    }
    const normalizedCorrect = /^\d+$/.test(correct)
      ? optionIdAt(Math.max(0, Number.parseInt(correct, 10) - 1))
      : correct.toUpperCase();

    return {
      prompt,
      hint,
      options,
      correctOptionId: normalizedCorrect,
      explanation,
      points,
    };
  });

  return {
    title: 'Examen importé (texte)',
    description: null,
    sourceFormat: 'txt',
    questions: normalizeQuestionInputs(questions),
  };
};

/**
 * Parses a teacher upload into a preview. Nothing is persisted and no
 * attempt/answer is ever created here.
 */
export const parseExamImport = (file: ExamImportFile): ImportedExamPreview => {
  if (!file.buffer || file.buffer.length === 0) {
    throw new ValidationError('The uploaded file is empty', [
      { path: 'file', message: 'Upload a non-empty .json, .csv or .txt file' },
    ]);
  }
  const extension = extensionOf(file.originalname);
  const mimetype = file.mimetype.toLowerCase();

  if (extension === 'json' || mimetype === 'application/json') return parseJson(file.buffer);
  if (extension === 'csv' || mimetype === 'text/csv') return parseCsv(file.buffer);
  if (extension === 'txt' || mimetype === 'text/plain') return parseTxt(file.buffer);

  throw new ImportFormatUnsupportedError(
    'Only .json, .csv and .txt exam files are supported. Use AI generation for PDFs.',
  );
};
