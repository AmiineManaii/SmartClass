import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import {
  AppError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import type { StoragePort } from '../../../shared/storage/storage.port.js';
import type { ModelInventoryReport, SmartModelRouterPort } from '../../ai-assistant/index.js';
import type { KnowledgeIndexerPort } from '../../knowledge/index.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import type {
  GeneratedFlashcard,
  GeneratedQuizQuestion,
  ImportantMoment,
  LessonConcept,
  LessonDefinition,
  LessonExample,
  LessonPackageEntity,
  LessonPackageVersionEntity,
  RecordingChapterEntity,
  RecordingSlideFrameEntity,
  RecordingTranscriptEntity,
} from '../domain/recording.entity.js';
import {
  buildSrtFromSegments,
  buildVttFromSegments,
  canApproveLesson,
  canPublishLesson,
} from '../domain/recording.entity.js';
import type { RecordingRepositoryPort } from '../domain/recording-repository.port.js';
import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import { canHost, type UserContext } from '../domain/video-session-policy.js';
import {
  toRecordingOverviewDto,
  type RecordingOverviewDto,
} from './recording-workflow.use-cases.js';

export interface TeacherReviewWorkspaceDto {
  sessionTitle: string;
  sessionSubject: string | null;
  recording: RecordingOverviewDto;
  transcript: RecordingTranscriptEntity | null;
  slideFrames: RecordingSlideFrameEntity[];
  chapters: RecordingChapterEntity[];
  lessonPackage: LessonPackageEntity | null;
  versions: LessonPackageVersionEntity[];
  modelInventory: ModelInventoryReport;
}

export class GetLessonReviewPackageUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly modelRouter: SmartModelRouterPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
  ): Promise<TeacherReviewWorkspaceDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant ou un administrateur peut accéder au studio de révision');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording || recording.status === 'DELETED') {
      throw new AppError(
        'Aucun enregistrement disponible pour cette séance',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    const [latestJob, transcript, slideFrames, chapters, lessonPackage, modelInventory] =
      await Promise.all([
        this.recordingRepository.findLatestJobByRecordingId(recording.id),
        this.recordingRepository.getTranscript(recording.id),
        this.recordingRepository.listSlideFrames(recording.id),
        this.recordingRepository.listChapters(recording.id),
        this.recordingRepository.getLessonPackage(recording.id),
        this.modelRouter.inspectModels(),
      ]);

    const versions = lessonPackage
      ? await this.recordingRepository.listLessonPackageVersions(lessonPackage.id)
      : [];

    return {
      sessionTitle: session.title,
      sessionSubject: session.subject,
      recording: toRecordingOverviewDto(recording, latestJob),
      transcript,
      slideFrames,
      chapters,
      lessonPackage,
      versions,
      modelInventory,
    };
  }
}

export interface UpdateLessonReviewInput {
  title?: string;
  shortSummary?: string;
  detailedSummary?: string;
  structuredMarkdown?: string;
  changeSummary?: string;
  transcriptSegments?: Array<{
    orderIndex?: number;
    startSeconds: number;
    endSeconds: number;
    text: string;
    speaker?: string | null;
  }>;
  chapters?: Array<{
    orderIndex?: number;
    title: string;
    summary: string;
    startSeconds: number;
    endSeconds: number;
    keyConcepts?: string[];
    slideFrameId?: string | null;
    sourcePage?: number | null;
  }>;
  structuredNotes?: string;
  generalSummary?: string;
  keyConcepts?: LessonConcept[];
  definitions?: LessonDefinition[];
  importantExamples?: LessonExample[];
  learningObjectives?: string[];
  formulasAndRules?: string[];
  importantMoments?: ImportantMoment[];
  revisionSheet?: string;
  mindMapMermaid?: string;
  suggestedStudyOrder?: string[];
  flashcards?: GeneratedFlashcard[];
  quizzes?: GeneratedQuizQuestion[];
}

const enqueueLessonPackageKnowledge = (
  indexer: KnowledgeIndexerPort | undefined,
  params: {
    ownerId: string;
    sessionTitle: string;
    sessionSubject: string | null;
    sessionId: string;
    classGroupId: string;
    recordingId: string;
    recordingStatus: string;
    generalSummary: string;
    structuredNotes: string;
    keyConcepts: LessonConcept[];
    definitions: LessonDefinition[];
    formulasAndRules: string[];
    importantExamples: LessonExample[];
    importantMoments: ImportantMoment[];
  },
): void => {
  if (!indexer || !params.ownerId) return;
  const isPublished = params.recordingStatus === 'PUBLISHED';
  const isVerified = params.recordingStatus === 'APPROVED' || isPublished;
  indexer.enqueueIndex({
    sourceType: 'LECTURE_PACKAGE',
    sourceId: params.recordingId,
    authorId: params.ownerId,
    title: `${params.sessionTitle} — Synthèse & Notes`,
    subject: params.sessionSubject,
    visibility: isPublished ? 'CLASS_PUBLISHED' : 'PRIVATE_AUTHOR',
    trustTier: isVerified ? 'VERIFIED' : 'DRAFT_AI',
    classGroupIds: isPublished ? [params.classGroupId] : [],
    lessonPackage: {
      generalSummary: params.generalSummary,
      structuredNotes: params.structuredNotes,
      keyConcepts: params.keyConcepts,
      definitions: params.definitions,
      formulasAndRules: params.formulasAndRules,
      examples: params.importantExamples,
      importantMoments: params.importantMoments,
    },
    metadata: {
      recordingId: params.recordingId,
      sessionId: params.sessionId,
      classGroupId: params.classGroupId,
    },
  });
};

export class UpdateLessonReviewPackageUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly storage: StoragePort,
    private readonly modelRouter: SmartModelRouterPort,
    private readonly auditService?: AuditServicePort,
    private readonly knowledgeIndexer?: KnowledgeIndexerPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    input: UpdateLessonReviewInput,
  ): Promise<TeacherReviewWorkspaceDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant ou un administrateur peut modifier le package de cours');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording || recording.status === 'DELETED') {
      throw new AppError(
        'Enregistrement introuvable',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    if (input.transcriptSegments && input.transcriptSegments.length > 0) {
      const existingTranscript = await this.recordingRepository.getTranscript(recording.id);
      const fullText = input.transcriptSegments.map((s) => s.text.trim()).join('\n\n');
      const vttContent = buildVttFromSegments(input.transcriptSegments);
      const srtContent = buildSrtFromSegments(input.transcriptSegments);

      await this.recordingRepository.saveTranscript({
        recordingId: recording.id,
        language: existingTranscript?.language ?? 'fr',
        fullText,
        vttContent,
        srtContent,
        qualityScore: 1.0,
        modelUsed: existingTranscript?.modelUsed ?? 'teacher-edited',
        updatedById: user.id,
        segments: input.transcriptSegments.map((s, idx) => ({
          orderIndex: s.orderIndex ?? idx,
          startSeconds: s.startSeconds,
          endSeconds: s.endSeconds,
          text: s.text,
          speaker: s.speaker ?? 'Enseignant',
          confidence: 1.0,
        })),
      });

      await this.storage.putBuffer(
        `recordings/${session.id}/subtitles/captions.vtt`,
        Buffer.from(vttContent, 'utf8'),
      );
      await this.storage.putBuffer(
        `recordings/${session.id}/subtitles/captions.srt`,
        Buffer.from(srtContent, 'utf8'),
      );
    }

    if (input.chapters && input.chapters.length > 0) {
      await this.recordingRepository.replaceChapters(
        recording.id,
        input.chapters.map((ch, idx) => ({
          orderIndex: ch.orderIndex ?? idx,
          title: ch.title,
          summary: ch.summary,
          startSeconds: Math.round(ch.startSeconds),
          endSeconds: Math.round(ch.endSeconds),
          keyConcepts: ch.keyConcepts ?? [],
          slideFrameId: ch.slideFrameId ?? null,
          sourcePage: ch.sourcePage ?? null,
        })),
      );
    }

    const existingPkg = await this.recordingRepository.getLessonPackage(recording.id);
    if (existingPkg) {
      const nextVersion = existingPkg.version + 1;
      const resolvedNotes =
        input.structuredNotes ?? input.structuredMarkdown ?? existingPkg.structuredNotes;
      const resolvedSummary =
        input.generalSummary ??
        input.detailedSummary ??
        input.shortSummary ??
        existingPkg.generalSummary;
      await this.recordingRepository.saveLessonPackage(
        recording.id,
        {
          version: nextVersion,
          structuredNotes: resolvedNotes,
          generalSummary: resolvedSummary,
          keyConcepts: input.keyConcepts ?? existingPkg.keyConcepts,
          definitions: input.definitions ?? existingPkg.definitions,
          importantExamples: input.importantExamples ?? existingPkg.importantExamples,
          learningObjectives: input.learningObjectives ?? existingPkg.learningObjectives,
          formulasAndRules: input.formulasAndRules ?? existingPkg.formulasAndRules,
          importantMoments: input.importantMoments ?? existingPkg.importantMoments,
          revisionSheet: input.revisionSheet ?? existingPkg.revisionSheet,
          mindMapMermaid: input.mindMapMermaid ?? existingPkg.mindMapMermaid,
          suggestedStudyOrder: input.suggestedStudyOrder ?? existingPkg.suggestedStudyOrder,
          flashcards: input.flashcards ?? existingPkg.flashcards,
          quizzes: input.quizzes ?? existingPkg.quizzes,
          qualityReport: existingPkg.qualityReport,
          primaryModel: existingPkg.primaryModel,
          secondaryModel: existingPkg.secondaryModel,
          approvedById: existingPkg.approvedById,
          approvedAt: existingPkg.approvedAt,
          publishedAt: existingPkg.publishedAt,
        },
        {
          editedById: user.id,
          changeSummary: input.changeSummary ?? `Modification enseignant (v${nextVersion})`,
        },
      );
    }

    await this.auditService?.record({
      userId: user.id,
      action: 'lesson_package.updated',
      targetType: 'Recording',
      targetId: recording.id,
      details: {
        sessionId: session.id,
        changeSummary: input.changeSummary ?? 'Modification manuelle enseignant',
      },
    });

    const latestPkg = await this.recordingRepository.getLessonPackage(recording.id);
    if (latestPkg) {
      enqueueLessonPackageKnowledge(this.knowledgeIndexer, {
        ownerId: recording.hostId ?? session.hostId ?? '',
        sessionTitle: session.title,
        sessionSubject: session.subject,
        sessionId: session.id,
        classGroupId: recording.classGroupId,
        recordingId: recording.id,
        recordingStatus: recording.status,
        generalSummary: latestPkg.generalSummary,
        structuredNotes: latestPkg.structuredNotes,
        keyConcepts: latestPkg.keyConcepts,
        definitions: latestPkg.definitions,
        formulasAndRules: latestPkg.formulasAndRules,
        importantExamples: latestPkg.importantExamples,
        importantMoments: latestPkg.importantMoments,
      });
    }

    const getReview = new GetLessonReviewPackageUseCase(
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
      this.modelRouter,
    );
    return getReview.execute(user, sessionId);
  }
}

export type RegenerableSection =
  | 'summary'
  | 'structuredNotes'
  | 'quiz'
  | 'flashcards'
  | 'mindMap';

export class RegenerateLessonSectionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly modelRouter: SmartModelRouterPort,
    private readonly knowledgeIndexer?: KnowledgeIndexerPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    input: { section: RegenerableSection; instructions?: string },
  ): Promise<TeacherReviewWorkspaceDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant ou un administrateur peut régénérer une section');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording) {
      throw new AppError(
        'Enregistrement introuvable',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    const existingPkg = await this.recordingRepository.getLessonPackage(recording.id);
    if (!existingPkg) {
      throw new AppError(
        'Le package pédagogique n’est pas encore prêt',
        409,
        ErrorCodes.LESSON_PACKAGE_NOT_READY,
      );
    }

    const transcript = await this.recordingRepository.getTranscript(recording.id);
    const slideFrames = await this.recordingRepository.listSlideFrames(recording.id);
    const slidesContext =
      slideFrames.length > 0
        ? `\nDiapositives extraites :\n${slideFrames
            .map(
              (f, idx) =>
                `- [${f.timestampSeconds}s] Slide #${idx + 1}: ${f.ocrText} | ${f.visualSummary}`,
            )
            .join('\n')}`
        : '';
    const contextText = `${transcript?.fullText ?? existingPkg.structuredNotes}${slidesContext}`;
    const customHint = input.instructions ? `\nConsigne enseignant : ${input.instructions}` : '';
    const outputLang = (transcript?.language ?? 'fr').toLowerCase().startsWith('en')
      ? 'English'
      : 'French';

    let generalSummary = existingPkg.generalSummary;
    let structuredNotes = existingPkg.structuredNotes;
    let mindMapMermaid = existingPkg.mindMapMermaid;
    const flashcards = [...existingPkg.flashcards];
    const quizzes = [...existingPkg.quizzes];

    const cleanAiEducationalText = (raw: string): string => {
      let cleaned = raw.trim();
      const preambleRegex =
        /^(?:En tant que|Voici le r[eé]sum[eé]|Bonjour|Bienvenue|Je suis|En r[eé]ponse|Here is|Sure,)[^\n]*\n+(?:\*{3,}|-{3,})?\s*/i;
      while (preambleRegex.test(cleaned)) {
        cleaned = cleaned.replace(preambleRegex, '').trim();
      }
      return cleaned;
    };

    if (input.section === 'summary') {
      try {
        const res = await this.modelRouter.generateForRole('LESSON_PACKAGE_GENERATION', {
          systemPrompt: `You are a university professor on SmartClass. Regenerate a clear, accurate 2-paragraph executive summary in ${outputLang} grounded in BOTH the spoken transcript and extracted slide frames. NEVER start with greetings or meta introductions.`,
          messages: [
            {
              role: 'user',
              content: `Course: ${session.title}\n${contextText.slice(0, 6000)}${customHint}`,
            },
          ],
          temperature: 0.25,
          maxTokens: 600,
        });
        if (res.content.trim().length > 40) {
          generalSummary = cleanAiEducationalText(res.content);
        }
      } catch {
        generalSummary = `${existingPkg.generalSummary}\n\n*(Synthèse enrichie : ${input.instructions || 'Version consolidée par l’enseignant'})*`;
      }
    } else if (input.section === 'structuredNotes') {
      try {
        const res = await this.modelRouter.generateForRole('LESSON_PACKAGE_GENERATION', {
          systemPrompt: `You are a university professor on SmartClass. Regenerate comprehensive Markdown lecture notes in ${outputLang} with headings, bullet points, slide details, and key takeaways grounded in BOTH the transcript and extracted slides. NEVER start with greetings or meta introductions.`,
          messages: [
            {
              role: 'user',
              content: `Course: ${session.title}\n${contextText.slice(0, 6000)}${customHint}`,
            },
          ],
          temperature: 0.25,
          maxTokens: 1400,
        });
        if (res.content.trim().length > 80) {
          structuredNotes = cleanAiEducationalText(res.content);
        }
      } catch {
        structuredNotes = `${existingPkg.structuredNotes}\n\n### Complément pédagogique\n${input.instructions || 'Approfondissement méthodologique ajouté.'}`;
      }
    } else if (input.section === 'mindMap') {
      let generatedMap = '';
      try {
        const res = await this.modelRouter.generateForRole('LESSON_PACKAGE_GENERATION', {
          systemPrompt: `Generate ONLY a valid Mermaid "flowchart TD" diagram in ${outputLang} summarizing the real topics from this lecture and its slides. Quote all node labels in ["..."], never use "mindmap", no prose or markdown fences.`,
          messages: [
            {
              role: 'user',
              content: `Course: ${session.title}\n${contextText.slice(0, 4500)}${customHint}`,
            },
          ],
          temperature: 0.2,
          maxTokens: 500,
        });
        const cleaned = res.content
          .trim()
          .replace(/^```(?:mermaid)?\s*/i, '')
          .replace(/\s*```$/i, '')
          .trim();
        if (cleaned.startsWith('flowchart') && cleaned.includes('-->') && !cleaned.toLowerCase().includes('mindmap')) {
          generatedMap = cleaned;
        }
      } catch {
        // Fallback below
      }
      const safeTitle = session.title.replace(/["[\]()]/g, '');
      mindMapMermaid =
        generatedMap ||
        [
          'flowchart TD',
          `  Root["${safeTitle}"] --> A["1. Fondements & Définitions"]`,
          `  Root --> B["2. Architecture & Invariants"]`,
          `  Root --> C["3. Cas Pratique & Démonstration"]`,
          `  Root --> D["4. Synthèse & Auto-évaluation"]`,
        ].join('\n');
    } else if (input.section === 'flashcards') {
      let added = false;
      try {
        const res = await this.modelRouter.generateForRole('LESSON_PACKAGE_GENERATION', {
          systemPrompt: `Generate 2 new flashcards in ${outputLang} strictly grounded in the lecture transcript and slides. Return ONLY a JSON array: [{"front": "...", "back": "...", "chapterTitle": "...", "difficulty": "moyen", "timestampSeconds": 0}].`,
          messages: [
            {
              role: 'user',
              content: `Course: ${session.title}\n${contextText.slice(0, 5000)}${customHint}`,
            },
          ],
          temperature: 0.3,
          maxTokens: 500,
        });
        const raw = res.content.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '');
        const s = raw.indexOf('[');
        const e = raw.lastIndexOf(']');
        if (s !== -1 && e > s) {
          const parsed: unknown = JSON.parse(raw.slice(s, e + 1));
          if (Array.isArray(parsed)) {
            for (const item of parsed) {
              if (
                typeof item === 'object' &&
                item !== null &&
                typeof (item as Record<string, unknown>).front === 'string' &&
                typeof (item as Record<string, unknown>).back === 'string'
              ) {
                const rec = item as Record<string, unknown>;
                flashcards.push({
                  id: `fc_${Date.now()}_${flashcards.length + 1}`,
                  front: String(rec.front).trim(),
                  back: String(rec.back).trim(),
                  chapterTitle:
                    typeof rec.chapterTitle === 'string' ? rec.chapterTitle.trim() : session.title,
                  difficulty: 'moyen',
                  timestampSeconds:
                    typeof rec.timestampSeconds === 'number' ? Math.round(rec.timestampSeconds) : 0,
                });
                added = true;
              }
            }
          }
        }
      } catch {
        // Fallback below
      }
      if (!added) {
        flashcards.push({
          id: `fc_${Date.now()}`,
          front: `Point d'approfondissement : ${input.instructions || `Synthèse de ${session.title}`}`,
          back: `Retenir l'articulation entre les hypothèses du chapitre 1, le modèle du chapitre 2 et la vérification finale du chapitre 3.`,
          chapterTitle: 'Synthèse globale',
          difficulty: 'moyen',
          timestampSeconds: 0,
        });
      }
    } else if (input.section === 'quiz') {
      let added = false;
      try {
        const res = await this.modelRouter.generateForRole('LESSON_PACKAGE_GENERATION', {
          systemPrompt: `Generate 2 new quiz questions in ${outputLang} strictly grounded in the lecture transcript and slides. Return ONLY a JSON array: [{"type": "MULTIPLE_CHOICE", "question": "...", "options": ["A", "B", "C", "D"], "correctAnswer": "A", "explanation": "...", "difficulty": "moyen", "chapterTitle": "...", "timestampSeconds": 0}]. correctAnswer MUST exactly match one of options.`,
          messages: [
            {
              role: 'user',
              content: `Course: ${session.title}\n${contextText.slice(0, 5000)}${customHint}`,
            },
          ],
          temperature: 0.3,
          maxTokens: 700,
        });
        const raw = res.content.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '');
        const s = raw.indexOf('[');
        const e = raw.lastIndexOf(']');
        if (s !== -1 && e > s) {
          const parsed: unknown = JSON.parse(raw.slice(s, e + 1));
          if (Array.isArray(parsed)) {
            for (const item of parsed) {
              if (typeof item === 'object' && item !== null) {
                const rec = item as Record<string, unknown>;
                const opts = Array.isArray(rec.options)
                  ? rec.options.map((o) => String(o).trim()).filter(Boolean)
                  : [];
                const qText = typeof rec.question === 'string' ? rec.question.trim() : '';
                const ans = typeof rec.correctAnswer === 'string' ? rec.correctAnswer.trim() : '';
                const matched = opts.find((o) => o.toLowerCase() === ans.toLowerCase()) ?? opts[0];
                if (qText.length > 8 && opts.length >= 2 && matched) {
                  quizzes.push({
                    id: `qz_${Date.now()}_${quizzes.length + 1}`,
                    type: 'MULTIPLE_CHOICE',
                    question: qText,
                    options: opts,
                    correctAnswer: matched,
                    explanation:
                      typeof rec.explanation === 'string' ? rec.explanation.trim() : session.title,
                    difficulty: 'moyen',
                    chapterTitle:
                      typeof rec.chapterTitle === 'string'
                        ? rec.chapterTitle.trim()
                        : session.title,
                    timestampSeconds:
                      typeof rec.timestampSeconds === 'number'
                        ? Math.round(rec.timestampSeconds)
                        : 0,
                  });
                  added = true;
                }
              }
            }
          }
        }
      } catch {
        // Fallback below
      }
      if (!added) {
        quizzes.push({
          id: `qz_${Date.now()}`,
          type: 'MULTIPLE_CHOICE',
          question: `Question complémentaire (${input.instructions || session.title}) : quelle approche garantit la fiabilité de la méthode ?`,
          options: [
            'Vérifier systématiquement les hypothèses et valider sur un cas concret',
            'Ignorer les contraintes initiales',
            'Omettre la vérification finale',
            'Appliquer une formule aléatoire',
          ],
          correctAnswer: 'Vérifier systématiquement les hypothèses et valider sur un cas concret',
          explanation:
            'La rigueur méthodologique repose sur la validation des hypothèses et le contrôle final.',
          difficulty: 'moyen',
          chapterTitle: 'Synthèse globale',
          timestampSeconds: 0,
        });
      }
    }

    const nextVersion = existingPkg.version + 1;
    await this.recordingRepository.saveLessonPackage(
      recording.id,
      {
        ...existingPkg,
        version: nextVersion,
        generalSummary,
        structuredNotes,
        mindMapMermaid,
        flashcards,
        quizzes,
      },
      {
        editedById: user.id,
        changeSummary: `Régénération IA de la section "${input.section}" (v${nextVersion})`,
      },
    );

    enqueueLessonPackageKnowledge(this.knowledgeIndexer, {
      ownerId: recording.hostId ?? session.hostId ?? '',
      sessionTitle: session.title,
      sessionSubject: session.subject,
      sessionId: session.id,
      classGroupId: recording.classGroupId,
      recordingId: recording.id,
      recordingStatus: recording.status,
      generalSummary,
      structuredNotes,
      keyConcepts: existingPkg.keyConcepts,
      definitions: existingPkg.definitions,
      formulasAndRules: existingPkg.formulasAndRules,
      importantExamples: existingPkg.importantExamples,
      importantMoments: existingPkg.importantMoments,
    });

    const getReview = new GetLessonReviewPackageUseCase(
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
      this.modelRouter,
    );
    return getReview.execute(user, sessionId);
  }
}

export class ApproveLessonPackageUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly auditService?: AuditServicePort,
    private readonly knowledgeIndexer?: KnowledgeIndexerPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<RecordingOverviewDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant ou un administrateur peut approuver ce cours');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording || !canApproveLesson(recording.status)) {
      throw new AppError(
        'Le cours enregistré doit être au statut READY_FOR_REVIEW avant approbation',
        409,
        ErrorCodes.LESSON_PACKAGE_NOT_READY,
      );
    }

    const pkg = await this.recordingRepository.getLessonPackage(recording.id);
    if (!pkg || !pkg.generalSummary.trim() || !pkg.structuredNotes.trim()) {
      throw new AppError(
        'Le package de cours est incomplet (résumé ou notes manquants)',
        409,
        ErrorCodes.LESSON_PACKAGE_NOT_READY,
      );
    }

    const now = new Date();
    await this.recordingRepository.saveLessonPackage(
      recording.id,
      {
        ...pkg,
        approvedById: user.id,
        approvedAt: now,
      },
      {
        editedById: user.id,
        changeSummary: 'Approbation pédagogique par l’enseignant',
      },
    );

    const updated = await this.recordingRepository.updateRecording(recording.id, {
      status: recording.status === 'PUBLISHED' ? 'PUBLISHED' : 'APPROVED',
    });

    await this.knowledgeIndexer
      ?.syncRecordingLifecycle({
        recordingId: recording.id,
        visibility: updated.status === 'PUBLISHED' ? 'CLASS_PUBLISHED' : 'PRIVATE_AUTHOR',
        trustTier: 'VERIFIED',
        classGroupIds: updated.status === 'PUBLISHED' ? [session.classGroupId] : [],
      })
      .catch(() => undefined);

    await this.auditService?.record({
      userId: user.id,
      action: 'lesson_package.approved',
      targetType: 'Recording',
      targetId: recording.id,
      details: { sessionId: session.id, version: pkg.version },
    });

    const latestJob = await this.recordingRepository.findLatestJobByRecordingId(recording.id);
    return toRecordingOverviewDto(updated, latestJob);
  }
}

export class PublishLessonPackageUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
    private readonly knowledgeIndexer?: KnowledgeIndexerPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<RecordingOverviewDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant ou un administrateur peut publier ce cours');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording || !canPublishLesson(recording.status)) {
      throw new AppError(
        `Impossible de publier l'enregistrement dans l'état actuel (${recording?.status ?? 'ABSENT'})`,
        409,
        ErrorCodes.LESSON_PACKAGE_NOT_READY,
      );
    }

    const pkg = await this.recordingRepository.getLessonPackage(recording.id);
    if (!pkg) {
      throw new AppError(
        'Aucun package pédagogique trouvé pour cet enregistrement',
        409,
        ErrorCodes.LESSON_PACKAGE_NOT_READY,
      );
    }

    const now = new Date();
    await this.recordingRepository.saveLessonPackage(
      recording.id,
      {
        ...pkg,
        approvedById: pkg.approvedById ?? user.id,
        approvedAt: pkg.approvedAt ?? now,
        publishedAt: now,
      },
      {
        editedById: user.id,
        changeSummary: 'Publication du cours pour les étudiants',
      },
    );

    const updated = await this.recordingRepository.updateRecording(recording.id, {
      status: 'PUBLISHED',
      publishedAt: now,
    });

    if (this.knowledgeIndexer) {
      await this.knowledgeIndexer
        .syncRecordingLifecycle({
          recordingId: recording.id,
          visibility: 'CLASS_PUBLISHED',
          trustTier: 'VERIFIED',
          classGroupIds: [session.classGroupId],
        })
        .catch(() => undefined);
      enqueueLessonPackageKnowledge(this.knowledgeIndexer, {
        ownerId: recording.hostId ?? session.hostId ?? '',
        sessionTitle: session.title,
        sessionSubject: session.subject,
        sessionId: session.id,
        classGroupId: session.classGroupId,
        recordingId: recording.id,
        recordingStatus: 'PUBLISHED',
        generalSummary: pkg.generalSummary,
        structuredNotes: pkg.structuredNotes,
        keyConcepts: pkg.keyConcepts,
        definitions: pkg.definitions,
        formulasAndRules: pkg.formulasAndRules,
        importantExamples: pkg.importantExamples,
        importantMoments: pkg.importantMoments,
      });
    }

    await this.auditService?.record({
      userId: user.id,
      action: 'lesson_package.published',
      targetType: 'Recording',
      targetId: recording.id,
      details: {
        sessionId: session.id,
        classGroupId: session.classGroupId,
        publishedAt: now.toISOString(),
      },
    });

    await this.eventsPublisher?.publishToClass(session.classGroupId, {
      type: 'recording.published',
      sessionId: session.id,
      classGroupId: session.classGroupId,
      status: session.status,
      at: now.toISOString(),
      data: {
        recordingId: recording.id,
        status: 'PUBLISHED',
        publishedAt: now.toISOString(),
      },
    });

    const latestJob = await this.recordingRepository.findLatestJobByRecordingId(recording.id);
    return toRecordingOverviewDto(updated, latestJob);
  }
}

export class UnpublishLessonPackageUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly auditService?: AuditServicePort,
    private readonly knowledgeIndexer?: KnowledgeIndexerPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<RecordingOverviewDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant ou un administrateur peut dépublier ce cours');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording) {
      throw new AppError(
        'Enregistrement introuvable',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    const updated = await this.recordingRepository.updateRecording(recording.id, {
      status: 'READY_FOR_REVIEW',
      publishedAt: null,
    });

    await this.knowledgeIndexer
      ?.syncRecordingLifecycle({
        recordingId: recording.id,
        visibility: 'PRIVATE_AUTHOR',
        trustTier: 'DRAFT_AI',
        classGroupIds: [],
      })
      .catch(() => undefined);

    await this.auditService?.record({
      userId: user.id,
      action: 'lesson_package.unpublished',
      targetType: 'Recording',
      targetId: recording.id,
      details: { sessionId: session.id },
    });

    const latestJob = await this.recordingRepository.findLatestJobByRecordingId(recording.id);
    return toRecordingOverviewDto(updated, latestJob);
  }
}
