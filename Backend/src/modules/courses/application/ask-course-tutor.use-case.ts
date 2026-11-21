import type { Role } from '../../auth/index.js';
import type { SmartModelRouterPort } from '../../ai-assistant/index.js';
import type {
  CourseTutorCitation,
  CourseTutorConversation,
  CourseTutorMessage,
} from '../domain/course-study.entity.js';
import type { CourseStudyRepositoryPort } from '../domain/course-study-repository.port.js';
import type { CoursePassageRetrievalPort } from '../domain/course-passage-retrieval.port.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';
import {
  evaluateCourseScope,
  splitCoursePassages,
} from '../domain/course-grounding.js';
import { loadReadableCourse } from './course-access.js';

export interface AskCourseTutorInput {
  question: string;
  conversationId?: string;
  language?: 'fr' | 'en';
}

export interface AskCourseTutorResult {
  conversationId: string;
  userMessage: CourseTutorMessage;
  assistantMessage: CourseTutorMessage;
}

const REFUSAL = {
  fr: (title: string): string =>
    `Cette question ne porte pas sur le contenu du cours « ${title} ».\n\n` +
    'Le tuteur IA répond uniquement aux questions liées à ce cours publié par votre professeur. ' +
    'Reformulez votre question à partir d’une notion du cours, ou consultez le résumé et les flashcards générés.',
  en: (title: string): string =>
    `This question is outside the content of the course “${title}”.\n\n` +
    'The AI tutor only answers questions about this course published by your teacher. ' +
    'Ask about a concept covered in the course, or use the generated summary and flashcards.',
};

const excerpt = (text: string, max = 400): string => {
  const clean = text.replace(/[#*_>`]/g, ' ').replace(/\s+/g, ' ').trim();
  return clean.length > max ? `${clean.slice(0, max).trimEnd()}…` : clean;
};

/**
 * Course-scoped AI tutor.
 *
 * The deterministic scope gate runs BEFORE the model: an off-course question
 * is refused with `inScope: false` and never reaches the LLM. In-scope
 * answers are grounded in this course's passages only and carry citations.
 */
export class AskCourseTutorUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly groups: GroupRepositoryPort | undefined,
    private readonly study: CourseStudyRepositoryPort,
    private readonly retrieval: CoursePassageRetrievalPort,
    private readonly modelRouter: SmartModelRouterPort,
  ) {}

  public async execute(input: {
    requesterId: string;
    requesterRole: Role | null;
    courseId: string;
    question: string;
  } & AskCourseTutorInput): Promise<AskCourseTutorResult> {
    const course = await loadReadableCourse(
      this.courses,
      {
        requesterId: input.requesterId,
        requesterRole: input.requesterRole,
        courseId: input.courseId,
      },
      this.groups,
    );

    const language: 'fr' | 'en' = input.language === 'en' ? 'en' : 'fr';
    const question = input.question.trim();
    const passages = splitCoursePassages(course.content, course.title);
    const scope = evaluateCourseScope({
      question,
      courseTitle: course.title,
      courseSubject: course.subject,
      passages,
    });

    let conversation: CourseTutorConversation | null = null;
    if (input.conversationId) {
      const found = await this.study.findConversation(input.conversationId, input.requesterId);
      if (found && found.courseId === course.id) {
        conversation = found;
      }
    }
    if (!conversation) {
      conversation = await this.study.createConversation({
        courseId: course.id,
        userId: input.requesterId,
        title: question.slice(0, 80) || `Discussion — ${course.title}`,
      });
    }

    const userMessage = await this.study.appendMessage({
      conversationId: conversation.id,
      role: 'user',
      content: question,
      inScope: scope.inScope,
    });

    if (!scope.inScope) {
      const assistantMessage = await this.study.appendMessage({
        conversationId: conversation.id,
        role: 'assistant',
        content: REFUSAL[language](course.title),
        citations: [],
        inScope: false,
        modelUsed: null,
      });
      return { conversationId: conversation.id, userMessage, assistantMessage };
    }

    // ---- Grounded context: lexical passages + pgvector retrieval ----
    const retrievalHits = await this.retrieval.search({
      courseId: course.id,
      authorId: course.authorId,
      query: question,
      k: 5,
    });

    const sources: Array<{ title: string; content: string; score: number }> = [];
    const seenTitles = new Set<string>();
    for (const entry of scope.ranked.slice(0, 4)) {
      if (entry.score <= 0 || seenTitles.has(entry.passage.title)) continue;
      seenTitles.add(entry.passage.title);
      sources.push({
        title: entry.passage.title,
        content: entry.passage.content,
        score: entry.score,
      });
    }
    for (const hit of retrievalHits) {
      if (hit.content.trim().length === 0 || seenTitles.has(hit.title)) continue;
      seenTitles.add(hit.title);
      sources.push({ title: hit.title, content: hit.content, score: hit.score });
    }
    if (sources.length === 0 && passages[0]) {
      sources.push({
        title: passages[0].title,
        content: passages[0].content,
        score: 1,
      });
    }

    const groundedPassages = sources
      .slice(0, 6)
      .map(
        (source, index) =>
          `[Source ${index + 1} — ${source.title}] ${excerpt(source.content, 1400)}`,
      )
      .join('\n\n');

    let replyContent = '';
    let modelUsed = 'extractive-fallback';

    try {
      const history = conversation.messages
        .slice(-4)
        .map((message) => ({ role: message.role, content: message.content }));

      const response = await this.modelRouter.generateForRole('AI_TUTOR_RAG', {
        systemPrompt: [
          `Tu es le Tuteur IA du cours publié « ${course.title} »${course.subject ? ` (${course.subject})` : ''}.`,
          'RÈGLE ABSOLUE D’ANCRAGE : réponds uniquement à partir des sources du cours fournies ci-dessous.',
          'N’utilise aucune connaissance externe. Si la réponse n’est pas dans les sources, dis clairement que ce point n’est pas abordé dans ce cours.',
          'Cite le titre du chapitre source entre guillemets quand tu t’appuies dessus.',
          language === 'en'
            ? 'Answer in the student’s language (English).'
            : 'Réponds dans la langue de l’étudiant (français).',
          'Sois pédagogique et structuré (3 à 6 phrases ou une courte liste).',
        ].join(' '),
        messages: [
          ...history,
          {
            role: 'user',
            content: `Sources du cours :\n${groundedPassages}\n\nQuestion de l’étudiant : ${question}`,
          },
        ],
        temperature: 0.2,
        maxTokens: 800,
      });

      modelUsed = response.modelUsed;
      if (response.content.trim().length >= 20) {
        replyContent = response.content.trim();
      }
    } catch {
      // Local model offline: deterministic grounded answer below.
    }

    const citations: CourseTutorCitation[] = sources.slice(0, 3).map((source, index) => ({
      passageId: `p-${index + 1}`,
      sectionTitle: source.title,
      excerpt: excerpt(source.content, 300),
      score: Number(source.score.toFixed(4)),
    }));

    if (replyContent.length === 0) {
      const top = sources[0];
      replyContent = top
        ? [
            `D’après le cours **${course.title}**, chapitre **« ${top.title} »** :`,
            '',
            `> ${excerpt(top.content, 320)}`,
            '',
            'Ce point est bien couvert par le cours. Consultez le chapitre correspondant pour le détail complet.',
          ].join('\n')
        : language === 'en'
          ? `This course (${course.title}) does not contain the answer.`
          : `Le cours « ${course.title} » ne contient pas la réponse à cette question.`;
    }

    const assistantMessage = await this.study.appendMessage({
      conversationId: conversation.id,
      role: 'assistant',
      content: replyContent,
      citations,
      inScope: true,
      modelUsed,
    });

    return { conversationId: conversation.id, userMessage, assistantMessage };
  }
}
