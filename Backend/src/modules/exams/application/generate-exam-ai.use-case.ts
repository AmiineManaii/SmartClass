import { ValidationError } from '../../../shared/errors/app-error.js';
import { getEnv } from '../../../config/env.js';
import {
  AiInvalidOutputError,
  AiModelUnavailableError,
} from '../../../shared/errors/app-error.js';
import type { AiGatewayPort } from '../../ai-assistant/index.js';
import type { Role } from '../../auth/index.js';
import type { ExamAiModelCatalogPort } from '../domain/exam-ai-model-catalog.port.js';
import type {
  ExamCoverageReport,
  ExamKnowledgeSearchMode,
  ExamKnowledgeSourceAttribution,
} from '../domain/exam-knowledge.types.js';
import type { ExamRepositoryPort, CreateExamQuestionInput } from '../domain/exam-repository.port.js';
import { assertCanUseClass } from './exam-access.js';
import { normalizeQuestionInputs } from './exam-input.js';
import { buildExamJsonSchema, buildExamPrompt, extractJsonPayload } from './exam-ai.prompt.js';
import { ExamKnowledgeBlueprintService } from './exam-knowledge-blueprint.service.js';

export interface GenerateExamAiDTO {
  requesterId: string;
  requesterRole: Role | null;
  classGroupId: string;
  /** Published + validated courses the teacher explicitly selected. */
  courseIds?: string[];
  /** Optional chapter headings filter across the selected courses. */
  chapters?: string[];
  /** Optional key topics/concepts to emphasize during RAG retrieval and drafting. */
  focusTopics?: string[];
  /** Optional Knowledge Engine document IDs (e.g. verified recorded video lectures). */
  knowledgeDocumentIds?: string[];
  /** Opt-in to include teacher's own unvalidated DRAFT_AI knowledge docs (default false). */
  includeDrafts?: boolean;
  /** Equal-weight balanced allocation across selected sources (default true). */
  balancedCoverage?: boolean;
  title?: string;
  difficulty?: 'facile' | 'moyen' | 'difficile';
  questionCount?: number;
}

export interface GeneratedExamPreview {
  title: string;
  description: string | null;
  questions: CreateExamQuestionInput[];
  model: string;
  source: 'AI';
  knowledgeSearchMode: ExamKnowledgeSearchMode;
  knowledgeDegradedReason: string | null;
  knowledgeSources: ExamKnowledgeSourceAttribution[];
  coverage: ExamCoverageReport;
}

const normalizeModelTag = (name: string): string =>
  name.includes(':') ? name.trim() : `${name.trim()}:latest`;

/**
 * Generates a draft question preview from balanced published class courses
 * and/or authorized teacher Knowledge Engine resources (never indexed into
 * student retrieval). The local model is verified BEFORE generation and never
 * pulled automatically. Nothing is persisted until the teacher reviews & saves.
 */
export class GenerateExamAiUseCase {
  constructor(
    private readonly exams: ExamRepositoryPort,
    private readonly gateway: AiGatewayPort,
    private readonly catalog: ExamAiModelCatalogPort,
    private readonly modelName: string = getEnv().AI_MODEL,
    private readonly blueprintService: ExamKnowledgeBlueprintService = new ExamKnowledgeBlueprintService(),
  ) {}

  public async execute(dto: GenerateExamAiDTO): Promise<GeneratedExamPreview> {
    const classGroup = await this.exams.findClassGroup(dto.classGroupId);
    if (!classGroup) {
      throw new ValidationError('Unknown class', [
        { path: 'classGroupId', message: 'This class does not exist' },
      ]);
    }
    await assertCanUseClass(this.exams, dto.classGroupId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });

    const available = await this.exams.listClassCourses(
      dto.classGroupId,
      dto.requesterId,
    );
    const requestedIds = Array.from(new Set(dto.courseIds ?? []));
    const requestedDocIds = Array.from(new Set(dto.knowledgeDocumentIds ?? []));

    let courses = available;
    if (requestedIds.length > 0) {
      const byId = new Map(available.map((course) => [course.id, course]));
      const missing = requestedIds.filter((courseId) => !byId.has(courseId));
      if (missing.length > 0) {
        throw new ValidationError(
          'Some selected courses are not published and validated for this class',
          [
            {
              path: 'courseIds',
              message: `Unknown or unpublished course(s): ${missing.join(', ')}`,
            },
          ],
        );
      }
      // Keep the teacher's selection order rather than the repository order.
      courses = requestedIds.map((courseId) => byId.get(courseId)!);
    } else if (requestedDocIds.length > 0) {
      // Teacher explicitly pinned Knowledge Engine sources (e.g. recorded lectures)
      // without picking class courses; avoid dumping unrelated class courses.
      courses = [];
    }

    if (courses.length === 0 && requestedDocIds.length === 0) {
      throw new ValidationError('No published course in this class', [
        {
          path: requestedIds.length > 0 ? 'courseIds' : 'classGroupId',
          message:
            requestedIds.length > 0
              ? 'Select at least one published and validated course'
              : 'Publish and validate at least one course for this class before generating an exam',
        },
      ]);
    }

    const installed = await this.catalog.listInstalledModels();
    const isModelInstalled = installed.some(
      (entry) =>
        entry === this.modelName ||
        normalizeModelTag(entry) === normalizeModelTag(this.modelName),
    );
    if (!isModelInstalled) {
      throw new AiModelUnavailableError(
        `The required local model "${this.modelName}" is not installed. Install it manually with Ollama; it is never downloaded automatically.`,
        [{ installedModels: installed }],
      );
    }

    const questionCount = Math.min(30, Math.max(1, dto.questionCount ?? 10));
    const desiredTitle = dto.title?.trim() || `Contrôle — ${classGroup.name}`;
    const env = getEnv();
    const blueprint = await this.blueprintService.build({
      requesterId: dto.requesterId,
      requesterRole: dto.requesterRole,
      title: desiredTitle,
      courses,
      chapters: dto.chapters,
      focusTopics: dto.focusTopics,
      knowledgeDocumentIds: requestedDocIds,
      includeDrafts: dto.includeDrafts,
      questionCount,
      maxSourceChars: env.AI_MAX_SOURCE_CHARS,
      balancedCoverage: dto.balancedCoverage,
    });

    if (blueprint.coverage.coveredSources === 0 || blueprint.promptContext.trim().length === 0) {
      throw new ValidationError(
        'No accessible knowledge source available to generate exam',
        [
          {
            path: requestedDocIds.length > 0 ? 'knowledgeDocumentIds' : 'courseIds',
            message:
              blueprint.coverage.warnings[0] ??
              'Selected sources returned no accessible validated content',
          },
        ],
      );
    }

    const prompt = buildExamPrompt({
      title: desiredTitle,
      subject: courses[0]?.subject ?? null,
      difficulty: dto.difficulty ?? 'moyen',
      questionCount,
      courses,
      maxSourceChars: env.AI_MAX_SOURCE_CHARS,
      focusTopics: dto.focusTopics,
      blueprint,
    });

    // Stream the model hop: Ollama sends SSE headers immediately, which
    // avoids undici's hard 5-minute `headersTimeout` on a plain fetch (the
    // local model needs 4-6 minutes when it runs partly on CPU). Content is
    // accumulated and parsed exactly like a non-streamed completion.
    let content = '';
    const usage = await this.gateway.streamCompletion(
      {
        system: prompt.system,
        user: prompt.user,
        maxTokens: Math.min(8192, 700 + questionCount * 320),
        temperature: 0.2,
        thinking: false,
        responseFormat: {
          type: 'json_schema',
          json_schema: {
            name: 'exam_preview',
            strict: true,
            schema: buildExamJsonSchema(questionCount),
          },
        },
      },
      (delta) => {
        content += delta;
      },
    );

    let payload: unknown;
    try {
      payload = extractJsonPayload(content);
    } catch {
      throw new AiInvalidOutputError(
        'The local model did not return a JSON object. Retry or generate the exam manually.',
      );
    }

    const container =
      payload && typeof payload === 'object' && !Array.isArray(payload)
        ? (payload as Record<string, unknown>)
        : {};
    const rawQuestions = Array.isArray(container.questions)
      ? container.questions
      : Array.isArray(payload)
        ? payload
        : null;
    if (!rawQuestions) {
      throw new AiInvalidOutputError('The model output has no "questions" array.');
    }

    let questions: CreateExamQuestionInput[];
    try {
      questions = normalizeQuestionInputs(rawQuestions, { max: 30 }).slice(0, questionCount);
    } catch (error) {
      throw new AiInvalidOutputError(
        'The model questions are malformed (missing options or correct answer).',
        [error instanceof Error ? error.message : String(error)],
      );
    }

    return {
      title:
        typeof container.title === 'string' && container.title.trim().length > 0
          ? container.title.trim()
          : desiredTitle,
      description:
        typeof container.description === 'string' ? container.description.trim() || null : null,
      questions,
      model: usage.model || this.modelName,
      source: 'AI',
      knowledgeSearchMode: blueprint.searchMode,
      knowledgeDegradedReason: blueprint.degradedReason,
      knowledgeSources: blueprint.knowledgeSources,
      coverage: blueprint.coverage,
    };
  }
}
