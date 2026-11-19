import { describe, expect, it } from 'vitest';
import { parseExamImport } from '../../src/modules/exams/infrastructure/exam-import.parser.js';
import { ImportFormatUnsupportedError } from '../../src/shared/errors/app-error.js';

const file = (name: string, content: string, mimetype = 'text/plain') => ({
  originalname: name,
  mimetype,
  buffer: Buffer.from(content, 'utf8'),
});

describe('exam import parser', () => {
  it('parses the JSON export and keeps the correct answer server-side', () => {
    const preview = parseExamImport(
      file(
        'exam.json',
        JSON.stringify({
          title: 'Contrôle',
          questions: [
            {
              prompt: 'Quelle est la capitale de la France ?',
              options: ['Paris', 'Londres', 'Berlin'],
              correctOptionId: 'A',
              points: 2,
            },
          ],
        }),
        'application/json',
      ),
    );
    expect(preview.sourceFormat).toBe('json');
    expect(preview.title).toBe('Contrôle');
    expect(preview.questions).toHaveLength(1);
    expect(preview.questions[0]?.correctOptionIds).toEqual(['A']);
    expect(preview.questions[0]?.points).toBe(2);
  });

  it('parses a CSV with a header, quote handling and semicolons', () => {
    const preview = parseExamImport(
      file(
        'exam.csv',
        'question;optionA;optionB;optionC;correct;points\n"Quel est 1+1 ?";1;2;3;B;1\n',
        'text/csv',
      ),
    );
    expect(preview.questions).toHaveLength(1);
    expect(preview.questions[0]?.prompt).toBe('Quel est 1+1 ?');
    expect(preview.questions[0]?.options.map((option) => option.text)).toEqual(['1', '2', '3']);
    expect(preview.questions[0]?.correctOptionIds).toEqual(['B']);
  });

  it('parses a CSV without a header (prompt, options, then the letter)', () => {
    const preview = parseExamImport(
      file('exam.csv', 'Quel est 1+1 ?,1,2,3,B\n', 'text/csv'),
    );
    expect(preview.questions[0]?.options).toHaveLength(3);
    expect(preview.questions[0]?.correctOptionIds).toEqual(['B']);
  });

  it('parses a text block with * marking the correct option', () => {
    const preview = parseExamImport(
      file(
        'exam.txt',
        [
          'Quelle est la capitale de la France ?',
          'A) Londres',
          '*B) Paris',
          'C) Berlin',
          'Points: 3',
          '',
          'Question: 2 + 2 = ?',
          'A) 3',
          'B) 4',
          'C) 5',
          'Answer: B',
        ].join('\n'),
      ),
    );
    expect(preview.questions).toHaveLength(2);
    expect(preview.questions[0]?.correctOptionIds).toEqual(['B']);
    expect(preview.questions[0]?.points).toBe(3);
    expect(preview.questions[1]?.prompt).toBe('2 + 2 = ?');
    expect(preview.questions[1]?.correctOptionIds).toEqual(['B']);
  });

  it('parses the single-line pipe format', () => {
    const preview = parseExamImport(
      file('exam.txt', '2 + 2 ? | 3 | 4 | 5 | B\n', 'text/plain'),
    );
    expect(preview.questions[0]?.prompt).toBe('2 + 2 ?');
    expect(preview.questions[0]?.correctOptionIds).toEqual(['B']);
  });

  it('rejects an unsupported format', () => {
    expect(() =>
      parseExamImport(file('exam.pdf', '%PDF-1.7', 'application/pdf')),
    ).toThrow(ImportFormatUnsupportedError);
  });
});
