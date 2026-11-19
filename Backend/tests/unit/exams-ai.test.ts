import { describe, expect, it } from 'vitest';
import type { Role } from '../../src/modules/auth/index.js';
import type { AiGatewayPort, ChatCompletionInput } from '../../src/modules/ai-assistant/index.js';
import {
  AiInvalidOutputError,
  AiModelUnavailableError,
  ForbiddenError,
  ValidationError,
} from '../../src/shared/errors/app-error.js';
import { GenerateExamAiUseCase } from '../../src/modules/exams/application/generate-exam-ai.use-case.js';
import { ListClassCoursesUseCase } from '../../src/modules/exams/application/list-class-courses.use-case.js';
import { FakeExamRepository } from './exams.test-helpers.js';

const TEACHER: Role = 'TEACHER';
const CLASS_ID = 'class-ai';
const MODEL = 'hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1';

const setup = () => {
  const repo = new FakeExamRepository();
  repo.addClass(CLASS_ID, 'Terminale');
  repo.allowTeacher('teacher-ai', CLASS_ID);
  repo.classCourses.set(CLASS_ID, [
    {
      id: 'course-photosynthesis',
      title: 'La photosynthèse',
      subject: 'SVT',
      content:
        'La photosynthèse transforme le dioxyde de carbone et l’eau en glucose grâce à la lumière.',
    },
  ]);
  return repo;
};

const gatewayWith = (
  content: string,
  capture?: (input: ChatCompletionInput) => void,
): AiGatewayPort => ({
  async chatCompletion() {
    throw new Error('not used');
  },
  async streamCompletion(input, onDelta) {
    capture?.(input);
    // Deliver in two chunks to cover accumulation on the use-case side.
    const mid = Math.ceil(content.length / 2);
    onDelta(content.slice(0, mid));
    onDelta(content.slice(mid));
    return { promptTokens: 10, completionTokens: 20, model: MODEL };
  },
  async checkHealth() {
    return { available: true, model: MODEL, latencyMs: 1 };
  },
});

const catalogWith = (models: string[]) => ({
  async listInstalledModels() {
    return models;
  },
});

const validContent = JSON.stringify({
  title: 'Contrôle sur la photosynthèse',
  questions: [
    {
      prompt: 'Quel gaz est consommé par la photosynthèse ?',
      options: ['Le dioxyde de carbone', 'Le diazote', 'Le méthane', 'L’hélium'],
      correctOptionId: 'A',
      explanation: 'Le cours indique que le dioxyde de carbone est transformé.',
      points: 2,
    },
  ],
});

const dto = {
  requesterId: 'teacher-ai',
  requesterRole: TEACHER,
  classGroupId: CLASS_ID,
  title: 'Contrôle',
  difficulty: 'moyen' as const,
  questionCount: 5,
};

describe('AI exam generation', () => {
  it('generates a validated preview from the class courses only', async () => {
    const repo = setup();
    let captured: ChatCompletionInput | null = null;
    const useCase = new GenerateExamAiUseCase(
      repo,
      gatewayWith(validContent, (input) => {
        captured = input;
      }),
      catalogWith([MODEL, 'other:model']),
      MODEL,
    );

    const preview = await useCase.execute(dto);
    expect(preview.questions).toHaveLength(1);
    expect(preview.questions[0]?.correctOptionIds).toEqual(['A']);
    expect(preview.model).toBe(MODEL);
    expect(captured?.user).toContain('La photosynthèse');
    expect(captured?.user).toContain('dioxyde de carbone');
  });

  it('uses only the courses selected by the teacher', async () => {
    const repo = setup();
    repo.classCourses.set(CLASS_ID, [
      {
        id: 'course-photosynthesis',
        title: 'La photosynthèse',
        subject: 'SVT',
        content: 'La photosynthèse transforme le dioxyde de carbone en glucose.',
      },
      {
        id: 'course-respiration',
        title: 'La respiration cellulaire',
        subject: 'SVT',
        content: 'La respiration cellulaire libère de l’énergie à partir du glucose.',
      },
    ]);
    let captured: ChatCompletionInput | null = null;
    const useCase = new GenerateExamAiUseCase(
      repo,
      gatewayWith(validContent, (input) => {
        captured = input;
      }),
      catalogWith([MODEL]),
      MODEL,
    );

    await useCase.execute({ ...dto, courseIds: ['course-respiration'] });
    expect(captured?.user).toContain('La respiration cellulaire');
    expect(captured?.user).not.toContain('La photosynthèse');
  });

  it('rejects a course that is not published and validated for the class', async () => {
    const repo = setup();
    const useCase = new GenerateExamAiUseCase(
      repo,
      gatewayWith(validContent),
      catalogWith([MODEL]),
      MODEL,
    );
    await expect(
      useCase.execute({ ...dto, courseIds: ['course-unknown'] }),
    ).rejects.toBeInstanceOf(ValidationError);
  });

  it('refuses to generate when the required model is not installed', async () => {
    const repo = setup();
    const useCase = new GenerateExamAiUseCase(
      repo,
      gatewayWith(validContent),
      catalogWith(['some-other:model']),
      MODEL,
    );
    await expect(useCase.execute(dto)).rejects.toBeInstanceOf(AiModelUnavailableError);
  });

  it('rejects an invalid JSON payload from the model', async () => {
    const repo = setup();
    const useCase = new GenerateExamAiUseCase(
      repo,
      gatewayWith('Voici un examen, sans JSON.'),
      catalogWith([MODEL]),
      MODEL,
    );
    await expect(useCase.execute(dto)).rejects.toBeInstanceOf(AiInvalidOutputError);
  });

  it('refuses to generate without any published course in the class', async () => {
    const repo = setup();
    repo.classCourses.set(CLASS_ID, []);
    const useCase = new GenerateExamAiUseCase(
      repo,
      gatewayWith(validContent),
      catalogWith([MODEL]),
      MODEL,
    );
    await expect(useCase.execute(dto)).rejects.toBeInstanceOf(ValidationError);
  });

  it('refuses a teacher who does not teach the class', async () => {
    const repo = setup();
    const useCase = new GenerateExamAiUseCase(
      repo,
      gatewayWith(validContent),
      catalogWith([MODEL]),
      MODEL,
    );
    await expect(useCase.execute({ ...dto, requesterId: 'intruder' })).rejects.toBeInstanceOf(
      ForbiddenError,
    );
  });
});

describe('AI source course picker', () => {
  it('lists published courses without exposing their content', async () => {
    const repo = setup();
    const useCase = new ListClassCoursesUseCase(repo);
    const courses = await useCase.execute({
      requesterId: 'teacher-ai',
      requesterRole: TEACHER,
      classGroupId: CLASS_ID,
    });
    expect(courses).toEqual([
      { id: 'course-photosynthesis', title: 'La photosynthèse', subject: 'SVT' },
    ]);
  });

  it('rejects a teacher who does not teach the class', async () => {
    const repo = setup();
    const useCase = new ListClassCoursesUseCase(repo);
    await expect(
      useCase.execute({
        requesterId: 'intruder',
        requesterRole: TEACHER,
        classGroupId: CLASS_ID,
      }),
    ).rejects.toBeInstanceOf(ForbiddenError);
  });
});
