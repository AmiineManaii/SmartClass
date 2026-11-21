import type { Role } from '../../auth/index.js';
import type { SmartModelRouterPort } from '../../ai-assistant/index.js';
import type { CourseDetail } from '../domain/course.entity.js';
import type {
  CourseFlashcard,
  CourseFlashcardsContent,
  CourseStudyArtifact,
  CourseStudyLanguage,
  CourseSummaryContent,
  CourseSummaryMode,
} from '../domain/course-study.entity.js';
import type { CourseStudyRepositoryPort } from '../domain/course-study-repository.port.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';
import {
  buildExtractiveFlashcards,
  buildExtractiveSummary,
  parseFlashcardsJson,
  splitCoursePassages,
  summaryModeLabel,
} from '../domain/course-grounding.js';
import { loadReadableCourse } from './course-access.js';

export interface GenerateCourseStudyArtifactInput {
  kind: 'SUMMARY' | 'FLASHCARDS';
  language?: CourseStudyLanguage;
  /** SUMMARY only. */
  summaryMode?: CourseSummaryMode;
  /** FLASHCARDS only. */
  flashcardCount?: number;
  /** Optional chapter focused on (matches a passage title). */
  focus?: string;
}

const MAX_SOURCE_CHARS = 16000;

const excerpt = (text: string, max = 200): string => {
  const clean = text.replace(/[#*_>`]/g, ' ').replace(/\s+/g, ' ').trim();
  return clean.length > max ? `${clean.slice(0, max).trimEnd()}…` : clean;
};

const truncateSource = (text: string): string =>
  text.length > MAX_SOURCE_CHARS ? `${text.slice(0, MAX_SOURCE_CHARS)}\n[…]` : text;

const MODE_INSTRUCTIONS: Record<CourseSummaryMode, string> = {
  short:
    'Produis un résumé court : 5 à 7 puces essentielles, une phrase par puce, aucune digression.',
  medium:
    'Produis un résumé structuré : ## Points clés (5-8 puces) puis ## Développement (un paragraphe par chapitre).',
  detailed:
    'Produis une synthèse détaillée : un bloc ### par chapitre du cours, avec les définitions, mécanismes et exemples réellement présents.',
  exam:
    'Produis une fiche de révision examen : définitions, formules/règles, pièges et points à vérifier, uniquement ceux du cours.',
  eli15:
    'Explique le cours avec des mots simples et des analogies concrètes, sans introduire de notion absente du cours.',
  bullet_points:
    'Produis une liste de points clés (12 puces maximum), chacune commençant par un verbe ou un concept du cours.',
};

/**
 * Generates a student summary or flashcard deck from ONE published course.
 *
 * Grounding is enforced twice: only this course's passages are sent to the
 * local model, and a deterministic extractive fallback is used when the
 * model is unavailable (never a fabricated empty artifact).
 */
export class GenerateCourseStudyArtifactUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly groups: GroupRepositoryPort | undefined,
    private readonly study: CourseStudyRepositoryPort,
    private readonly modelRouter: SmartModelRouterPort,
  ) {}

  public async execute(input: {
    requesterId: string;
    requesterRole: Role | null;
    courseId: string;
    artifact: GenerateCourseStudyArtifactInput;
  }): Promise<CourseStudyArtifact> {
    const course = await loadReadableCourse(
      this.courses,
      {
        requesterId: input.requesterId,
        requesterRole: input.requesterRole,
        courseId: input.courseId,
      },
      this.groups,
    );

    const language: 'fr' | 'en' =
      (input.artifact.language ?? 'fr') === 'en' ? 'en' : 'fr';
    const passages = splitCoursePassages(course.content, course.title);
    const focus = (input.artifact.focus ?? '').trim();
    const focusedPassages =
      focus.length > 0 && focus.toLowerCase() !== 'all'
        ? passages.filter(
            (passage) =>
              `${passage.title} ${passage.content}`
                .toLowerCase()
                .includes(focus.toLowerCase()),
          )
        : passages;
    const selected = focusedPassages.length > 0 ? focusedPassages : passages;
    const source = truncateSource(
      selected.map((passage) => `## ${passage.title}\n${passage.content}`).join('\n\n'),
    );

    if (input.artifact.kind === 'SUMMARY') {
      return this.generateSummary({
        course,
        source,
        selected,
        language,
        mode: input.artifact.summaryMode ?? 'medium',
        requesterId: input.requesterId,
        focus,
      });
    }

    return this.generateFlashcards({
      course,
      source,
      selected,
      language,
      count: input.artifact.flashcardCount ?? 8,
      requesterId: input.requesterId,
      focus,
    });
  }

  private async generateSummary(args: {
    course: CourseDetail;
    source: string;
    selected: ReturnType<typeof splitCoursePassages>;
    language: 'fr' | 'en';
    mode: CourseSummaryMode;
    requesterId: string;
    focus: string;
  }): Promise<CourseStudyArtifact> {
    const { course, source, selected, language, mode } = args;
    const label = summaryModeLabel(mode);
    let markdown = '';
    let modelUsed = 'extractive-fallback';

    try {
      const response = await this.modelRouter.generateForRole('STUDENT_SUMMARY', {
        systemPrompt: [
          'Tu es le tuteur académique SmartClass.',
          'Tu produis une fiche d’étude UNIQUEMENT à partir du contenu de cours fourni.',
          'RÈGLE ABSOLUE : n’ajoute aucune connaissance externe, n’invente aucune notion.',
          'Si une notion n’est pas dans le cours, ne la mentionne pas.',
          language === 'en' ? 'Write in English.' : 'Écris en français.',
          MODE_INSTRUCTIONS[mode],
        ].join(' '),
        messages: [
          {
            role: 'user',
            content: `Cours : ${course.title}${course.subject ? ` (${course.subject})` : ''}\n\nContenu du cours :\n${source}`,
          },
        ],
        temperature: 0.2,
        maxTokens: mode === 'detailed' ? 2200 : mode === 'short' ? 700 : 1400,
      });
      modelUsed = response.modelUsed;
      if (response.content.trim().length >= 60) {
        markdown = response.content.trim();
      }
    } catch {
      // Local model offline: deterministic extractive summary below.
    }

    if (markdown.length === 0) {
      markdown = buildExtractiveSummary({
        courseTitle: course.title,
        passages: selected,
        mode,
        language,
      });
    }

    const keyTakeaways = selected
      .slice(0, 8)
      .map((passage) => `${passage.title} : ${excerpt(passage.content, 160)}`);

    const content: CourseSummaryContent = {
      mode,
      markdown,
      keyTakeaways,
      sections: selected.map((passage) => ({
        title: passage.title,
        excerpt: excerpt(passage.content, 300),
      })),
    };

    return this.study.createArtifact({
      courseId: course.id,
      userId: args.requesterId,
      kind: 'SUMMARY',
      title: `${label} — ${course.title}`,
      language,
      config: {
        mode,
        focus: args.focus || null,
        sections: selected.map((passage) => passage.title),
      },
      content: content as unknown as Record<string, unknown>,
      modelUsed,
    });
  }

  private async generateFlashcards(args: {
    course: CourseDetail;
    source: string;
    selected: ReturnType<typeof splitCoursePassages>;
    language: 'fr' | 'en';
    count: number;
    requesterId: string;
    focus: string;
  }): Promise<CourseStudyArtifact> {
    const { course, source, selected, language } = args;
    const count = Math.max(4, Math.min(args.count, 20));
    let cards: CourseFlashcard[] = [];
    let modelUsed = 'extractive-fallback';

    try {
      const response = await this.modelRouter.generateForRole('QUIZ_FLASHCARDS', {
        systemPrompt: [
          'Tu es le tuteur académique SmartClass.',
          'Tu crées des flashcards de révision UNIQUEMENT à partir du contenu de cours fourni.',
          'RÈGLE ABSOLUE : aucune connaissance externe, aucune notion inventée.',
          `Réponds STRICTEMENT avec un tableau JSON valide, sans texte autour : ` +
            '[{"front":"question","back":"réponse","sectionTitle":"chapitre"}]',
          `Produis exactement ${count} cartes.`,
          language === 'en' ? 'Write in English.' : 'Écris en français.',
        ].join(' '),
        messages: [
          {
            role: 'user',
            content: `Cours : ${course.title}${course.subject ? ` (${course.subject})` : ''}\n\nContenu du cours :\n${source}`,
          },
        ],
        temperature: 0.2,
        maxTokens: 1600,
      });
      const parsed = parseFlashcardsJson(response.content);
      if (parsed.length >= 2) {
        cards = parsed.slice(0, count);
        modelUsed = response.modelUsed;
      }
    } catch {
      // Local model offline: deterministic cards below.
    }

    if (cards.length === 0) {
      cards = buildExtractiveFlashcards({
        courseTitle: course.title,
        passages: selected,
        count,
      });
    }

    const content: CourseFlashcardsContent = {
      focus: args.focus || 'all',
      cards,
    };

    return this.study.createArtifact({
      courseId: course.id,
      userId: args.requesterId,
      kind: 'FLASHCARDS',
      title: `Flashcards — ${course.title}`,
      language,
      config: { count: cards.length, focus: content.focus },
      content: content as unknown as Record<string, unknown>,
      modelUsed,
    });
  }
}
