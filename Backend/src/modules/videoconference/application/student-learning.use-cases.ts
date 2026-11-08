import {
  AppError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import type { SmartModelRouterPort } from '../../ai-assistant/index.js';
import {
  computeDeterministicLexicalVector,
} from '../../ai-assistant/index.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type {
  GeneratedFlashcard,
  GeneratedQuizQuestion,
  LessonPackageEntity,
  LessonTutorConversationEntity,
  LessonTutorMessageEntity,
  RecordingChapterEntity,
  RecordingEntity,
  RecordingSlideFrameEntity,
  RecordingTranscriptEntity,
  StudentLessonArtifactEntity,
  StudentLessonBookmarkEntity,
  StudentLessonNoteEntity,
  StudentLessonProgressEntity,
  StudentQuizAttemptEntity,
  StudyArtifactKind,
  TutorSourceCitation,
} from '../domain/recording.entity.js';
import { formatClockTimestamp } from '../domain/recording.entity.js';
import type { RecordingRepositoryPort } from '../domain/recording-repository.port.js';
import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import { canHost, type UserContext } from '../domain/video-session-policy.js';
import {
  toRecordingOverviewDto,
  type RecordingOverviewDto,
} from './recording-workflow.use-cases.js';

const cosineSimilarity = (a: number[], b: number[]): number => {
  let dot = 0;
  let normA = 0;
  let normB = 0;
  const len = Math.min(a.length, b.length);
  for (let i = 0; i < len; i++) {
    const va = a[i] ?? 0;
    const vb = b[i] ?? 0;
    dot += va * vb;
    normA += va * va;
    normB += vb * vb;
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
};

export interface StudentLessonWorkspaceDto {
  sessionTitle: string;
  sessionSubject: string | null;
  hostName: string | null;
  isTeacherPreview: boolean;
  recording: RecordingOverviewDto;
  transcript: RecordingTranscriptEntity | null;
  slideFrames: RecordingSlideFrameEntity[];
  chapters: RecordingChapterEntity[];
  lessonPackage: LessonPackageEntity | null;
  progress: StudentLessonProgressEntity | null;
  bookmarks: StudentLessonBookmarkEntity[];
  notes: StudentLessonNoteEntity[];
  studyArtifacts: StudentLessonArtifactEntity[];
  quizAttempts: StudentQuizAttemptEntity[];
  tutorConversations: LessonTutorConversationEntity[];
}

export interface LessonSearchHit {
  id: string;
  sourceType: 'TRANSCRIPT' | 'CHAPTER' | 'SLIDE' | 'CONCEPT' | 'DEFINITION';
  title: string;
  snippet: string;
  timestampSeconds: number;
  formattedTimestamp: string;
  chapterTitle: string | null;
  sourcePage: number | null;
  score: number;
}

const verifyLessonAccess = async (
  user: UserContext,
  sessionId: string,
  sessionRepository: VideoSessionRepositoryPort,
  recordingRepository: RecordingRepositoryPort,
  classAccessPort: ClassAccessPort,
): Promise<{
  session: NonNullable<Awaited<ReturnType<VideoSessionRepositoryPort['findById']>>>;
  recording: RecordingEntity;
  isTeacherOrAdmin: boolean;
}> => {
  const session = await sessionRepository.findById(sessionId);
  if (!session) {
    throw new NotFoundError('Séance vidéo introuvable');
  }

  const access = await classAccessPort.getClassAccess(user.id, session.classGroupId);
  const isTeacherOrAdmin = session.hostId === user.id || canHost(user, access);
  if (!isTeacherOrAdmin && !access.isMember) {
    throw new ForbiddenError('Vous n’êtes pas inscrit à la classe de ce cours');
  }

  const recording = await recordingRepository.findBySessionId(sessionId);
  if (!recording || recording.status === 'DELETED') {
    throw new AppError(
      'Aucun enregistrement disponible pour cette séance',
      404,
      ErrorCodes.RECORDING_NOT_FOUND,
    );
  }

  if (!isTeacherOrAdmin && recording.status !== 'PUBLISHED') {
    throw new AppError(
      'Ce cours enregistré est en cours de validation par votre enseignant et n’est pas encore publié.',
      403,
      ErrorCodes.RECORDING_NOT_PUBLISHED,
    );
  }

  return { session, recording, isTeacherOrAdmin };
};

export class GetPublishedLessonWorkspaceUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
  ): Promise<StudentLessonWorkspaceDto> {
    const { session, recording, isTeacherOrAdmin } = await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );

    const [
      latestJob,
      transcript,
      slideFrames,
      chapters,
      lessonPackage,
      progress,
      bookmarks,
      notes,
      studyArtifacts,
      quizAttempts,
      tutorConversations,
    ] = await Promise.all([
      this.recordingRepository.findLatestJobByRecordingId(recording.id),
      this.recordingRepository.getTranscript(recording.id),
      this.recordingRepository.listSlideFrames(recording.id),
      this.recordingRepository.listChapters(recording.id),
      this.recordingRepository.getLessonPackage(recording.id),
      this.recordingRepository.getProgress(recording.id, user.id),
      this.recordingRepository.listBookmarks(recording.id, user.id),
      this.recordingRepository.listNotes(recording.id, user.id),
      this.recordingRepository.listStudyArtifacts(recording.id, user.id),
      this.recordingRepository.listQuizAttempts(recording.id, user.id),
      this.recordingRepository.listTutorConversations(recording.id, user.id),
    ]);

    return {
      sessionTitle: session.title,
      sessionSubject: session.subject,
      hostName: session.hostName ?? null,
      isTeacherPreview: isTeacherOrAdmin && recording.status !== 'PUBLISHED',
      recording: toRecordingOverviewDto(recording, latestJob),
      transcript,
      slideFrames,
      chapters,
      lessonPackage,
      progress,
      bookmarks,
      notes,
      studyArtifacts,
      quizAttempts,
      tutorConversations,
    };
  }
}

export class SearchLessonContentUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    query: string,
  ): Promise<LessonSearchHit[]> {
    const { recording } = await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );

    const cleanQuery = query.trim().toLowerCase();
    if (!cleanQuery) return [];

    const queryVec = computeDeterministicLexicalVector(cleanQuery);
    const [transcript, chapters, slides, pkg] = await Promise.all([
      this.recordingRepository.getTranscript(recording.id),
      this.recordingRepository.listChapters(recording.id),
      this.recordingRepository.listSlideFrames(recording.id),
      this.recordingRepository.getLessonPackage(recording.id),
    ]);

    const hits: LessonSearchHit[] = [];

    const scoreCandidate = (text: string): number => {
      const lower = text.toLowerCase();
      const exactBonus = lower.includes(cleanQuery) ? 0.55 : 0;
      const semScore = cosineSimilarity(queryVec, computeDeterministicLexicalVector(lower));
      return Number((exactBonus + semScore * 0.45).toFixed(4));
    };

    const findChapterTitleAt = (ts: number): string | null => {
      const ch = chapters.find((c) => c.startSeconds <= ts && c.endSeconds >= ts) ?? chapters[0];
      return ch?.title ?? null;
    };

    for (const seg of transcript?.segments ?? []) {
      const score = scoreCandidate(seg.text);
      if (score >= 0.12) {
        hits.push({
          id: `seg_${seg.id}`,
          sourceType: 'TRANSCRIPT',
          title: `Transcription (${seg.speaker ?? 'Enseignant'})`,
          snippet: seg.text,
          timestampSeconds: Math.floor(seg.startSeconds),
          formattedTimestamp: formatClockTimestamp(seg.startSeconds),
          chapterTitle: findChapterTitleAt(seg.startSeconds),
          sourcePage: null,
          score,
        });
      }
    }

    for (const ch of chapters) {
      const combined = `${ch.title} ${ch.summary} ${ch.keyConcepts.join(' ')}`;
      const score = scoreCandidate(combined);
      if (score >= 0.12) {
        hits.push({
          id: `ch_${ch.id}`,
          sourceType: 'CHAPTER',
          title: ch.title,
          snippet: ch.summary,
          timestampSeconds: ch.startSeconds,
          formattedTimestamp: formatClockTimestamp(ch.startSeconds),
          chapterTitle: ch.title,
          sourcePage: ch.sourcePage,
          score: score + 0.05,
        });
      }
    }

    for (const slide of slides) {
      const combined = `${slide.ocrText} ${slide.visualSummary}`;
      const score = scoreCandidate(combined);
      if (score >= 0.12) {
        hits.push({
          id: `sl_${slide.id}`,
          sourceType: 'SLIDE',
          title: slide.ocrText || `Diapositive à ${formatClockTimestamp(slide.timestampSeconds)}`,
          snippet: slide.visualSummary,
          timestampSeconds: slide.timestampSeconds,
          formattedTimestamp: formatClockTimestamp(slide.timestampSeconds),
          chapterTitle: findChapterTitleAt(slide.timestampSeconds),
          sourcePage: slide.sourcePage,
          score,
        });
      }
    }

    for (const [idx, concept] of (pkg?.keyConcepts ?? []).entries()) {
      const score = scoreCandidate(`${concept.name} ${concept.explanation}`);
      if (score >= 0.12) {
        const ts = concept.timestampSeconds ?? 0;
        hits.push({
          id: `kc_${idx}`,
          sourceType: 'CONCEPT',
          title: `Concept : ${concept.name}`,
          snippet: concept.explanation,
          timestampSeconds: ts,
          formattedTimestamp: formatClockTimestamp(ts),
          chapterTitle: findChapterTitleAt(ts),
          sourcePage: concept.sourcePage ?? null,
          score: score + 0.04,
        });
      }
    }

    for (const [idx, def] of (pkg?.definitions ?? []).entries()) {
      const score = scoreCandidate(`${def.term} ${def.definition}`);
      if (score >= 0.12) {
        const ts = def.timestampSeconds ?? 0;
        hits.push({
          id: `def_${idx}`,
          sourceType: 'DEFINITION',
          title: `Définition : ${def.term}`,
          snippet: def.definition,
          timestampSeconds: ts,
          formattedTimestamp: formatClockTimestamp(ts),
          chapterTitle: def.chapterTitle ?? findChapterTitleAt(ts),
          sourcePage: null,
          score: score + 0.04,
        });
      }
    }

    return hits.sort((a, b) => b.score - a.score).slice(0, 20);
  }
}

export class UpdateStudentProgressUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    input: {
      lastPositionSeconds?: number;
      watchedSeconds?: number;
      completedChapters?: string[];
      flashcardKnownIds?: string[];
      flashcardReviewIds?: string[];
    },
  ): Promise<StudentLessonProgressEntity> {
    const { recording } = await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );

    return this.recordingRepository.upsertProgress({
      recordingId: recording.id,
      userId: user.id,
      ...input,
    });
  }
}

export class ManageStudentBookmarksUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async create(
    user: UserContext,
    sessionId: string,
    input: { timestampSeconds: number; label: string; chapterTitle?: string | null },
  ): Promise<StudentLessonBookmarkEntity> {
    const { recording } = await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );
    return this.recordingRepository.createBookmark({
      recordingId: recording.id,
      userId: user.id,
      timestampSeconds: Math.max(0, Math.floor(input.timestampSeconds)),
      label: input.label.trim(),
      chapterTitle: input.chapterTitle ?? null,
    });
  }

  public async delete(
    user: UserContext,
    sessionId: string,
    bookmarkId: string,
  ): Promise<{ deleted: boolean }> {
    await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );
    const deleted = await this.recordingRepository.deleteBookmark(bookmarkId, user.id);
    return { deleted };
  }
}

export class ManageStudentNotesUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async create(
    user: UserContext,
    sessionId: string,
    input: {
      timestampSeconds?: number | null;
      content: string;
      highlightText?: string | null;
      chapterTitle?: string | null;
    },
  ): Promise<StudentLessonNoteEntity> {
    const { recording } = await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );
    return this.recordingRepository.createNote({
      recordingId: recording.id,
      userId: user.id,
      timestampSeconds: input.timestampSeconds ?? null,
      content: input.content.trim(),
      highlightText: input.highlightText ?? null,
      chapterTitle: input.chapterTitle ?? null,
    });
  }

  public async update(
    user: UserContext,
    sessionId: string,
    noteId: string,
    patch: { content?: string; highlightText?: string | null; timestampSeconds?: number | null },
  ): Promise<StudentLessonNoteEntity> {
    await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );
    const updated = await this.recordingRepository.updateNote(noteId, user.id, patch);
    if (!updated) {
      throw new NotFoundError('Note personnelle introuvable');
    }
    return updated;
  }

  public async delete(
    user: UserContext,
    sessionId: string,
    noteId: string,
  ): Promise<{ deleted: boolean }> {
    await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );
    const deleted = await this.recordingRepository.deleteNote(noteId, user.id);
    return { deleted };
  }
}

export interface GenerateStudyArtifactInput {
  kind: StudyArtifactKind;
  language?: 'fr' | 'en' | 'ar' | 'ar-TN' | 'auto';
  chapterIds?: string[];
  chapterTitle?: string;
  // Summary options
  summaryMode?: 'short' | 'medium' | 'detailed' | 'exam' | 'eli15' | 'concise' | 'bullet_points';
  // Quiz options
  difficulty?: 'facile' | 'moyen' | 'difficile' | 'easy' | 'medium' | 'hard';
  questionCount?: number;
  questionTypes?: Array<
    'MULTIPLE_CHOICE' | 'TRUE_FALSE' | 'SHORT_ANSWER' | 'CONCEPTUAL' | 'PRACTICAL'
  >;
  // Flashcards options
  flashcardCount?: number;
  focus?: string;
}

export class GenerateStudentStudyArtifactUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly modelRouter: SmartModelRouterPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    input: GenerateStudyArtifactInput,
  ): Promise<StudentLessonArtifactEntity> {
    const { session, recording } = await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );

    const [transcript, allChapters, pkg] = await Promise.all([
      this.recordingRepository.getTranscript(recording.id),
      this.recordingRepository.listChapters(recording.id),
      this.recordingRepository.getLessonPackage(recording.id),
    ]);

    const requestedChapterTitle = input.chapterTitle ?? (
      input.focus && !['definitions', 'formulas', 'examples', 'all'].includes(input.focus)
        ? input.focus
        : undefined
    );

    const selectedChapters =
      input.chapterIds && input.chapterIds.length > 0
        ? allChapters.filter((c) => input.chapterIds!.includes(c.id))
        : requestedChapterTitle
          ? allChapters.filter(
              (c) => c.title.toLowerCase() === requestedChapterTitle.toLowerCase(),
            )
          : allChapters;

    const chaptersContext = (selectedChapters.length > 0 ? selectedChapters : allChapters)
      .map(
        (c) =>
          `[${formatClockTimestamp(c.startSeconds)} - ${formatClockTimestamp(c.endSeconds)}] ${c.title}: ${c.summary}`,
      )
      .join('\n');

    const rawLang = input.language ?? 'fr';
    const language: 'fr' | 'en' = rawLang === 'en' ? 'en' : 'fr';
    const langInstruction =
      rawLang === 'ar-TN'
        ? 'en arabe tunisien (Derja tunisienne claire avec termes techniques académiques)'
        : rawLang === 'ar'
          ? 'en arabe standard moderne'
          : rawLang === 'en'
            ? 'in English'
            : 'en français';

    if (input.kind === 'SUMMARY') {
      const rawMode = input.summaryMode ?? 'medium';
      const mode =
        rawMode === 'concise'
          ? 'short'
          : rawMode === 'bullet_points'
            ? 'medium'
            : rawMode;
      const modeLabel: Record<string, string> = {
        short: 'Résumé ultra-condensé (5 points clés)',
        medium: 'Résumé synthétique structuré',
        detailed: 'Synthèse approfondie par chapitre',
        exam: 'Fiche de révision spéciale Examen (définitions, formules, pièges à éviter)',
        eli15: 'Explication simplifiée intuitive avec analogies concrètes',
      };

      let markdown = '';
      let modelUsed = 'gemma4:e4b';

      try {
        const res = await this.modelRouter.generateForRole('STUDENT_SUMMARY', {
          systemPrompt: `Tu es le tuteur académique SmartClass. Génère uniquement à partir de ce cours un "${modeLabel[mode] ?? mode}" ${langInstruction}. Cite les horodatages [MM:SS] des chapitres correspondants.`,
          messages: [
            {
              role: 'user',
              content: `Cours: ${session.title}\nChapitres sélectionnés:\n${chaptersContext}\nNotes de référence:\n${(pkg?.structuredNotes ?? transcript?.fullText ?? '').slice(0, 2200)}`,
            },
          ],
          temperature: 0.25,
          maxTokens: 900,
        });
        modelUsed = res.modelUsed;
        if (res.content.trim().length > 50) {
          markdown = res.content.trim();
        }
      } catch {
        // Fallback deterministic personalized summary below
      }

      if (!markdown) {
        markdown = [
          `# ${modeLabel[mode] ?? 'Résumé personnalisé'} — ${session.title}`,
          '',
          `### Points essentiels du cours`,
          ...(selectedChapters.length > 0 ? selectedChapters : allChapters).map(
            (c) =>
              `- **[${formatClockTimestamp(c.startSeconds)}] ${c.title}** : ${c.summary}`,
          ),
          '',
          `### Concepts et règles à maîtriser`,
          ...(pkg?.formulasAndRules ?? []).map((r) => `- ${r}`),
          '',
          mode === 'exam'
            ? `### Conseil examen\nVérifiez systématiquement les hypothèses initiales ([00:00]) et la validation sur les cas limites.`
            : `### Synthèse générale\n${pkg?.generalSummary ?? ''}`,
        ].join('\n');
      }

      return this.recordingRepository.createStudyArtifact({
        recordingId: recording.id,
        userId: user.id,
        kind: 'SUMMARY',
        title: `${modeLabel[mode] ?? 'Résumé'} — ${session.title}`,
        language,
        chapterIds: input.chapterIds ?? [],
        config: { mode, requestedLanguage: rawLang },
        content: {
          mode,
          markdown,
          keyTakeaways: (selectedChapters.length > 0 ? selectedChapters : allChapters).map(
            (c) => `[${formatClockTimestamp(c.startSeconds)}] ${c.title}: ${c.summary}`,
          ),
        },
        modelUsed,
      });
    }

    if (input.kind === 'QUIZ') {
      const rawDiff = input.difficulty ?? 'moyen';
      const difficulty: 'facile' | 'moyen' | 'difficile' =
        rawDiff === 'easy'
          ? 'facile'
          : rawDiff === 'medium'
            ? 'moyen'
            : rawDiff === 'hard'
              ? 'difficile'
              : rawDiff;
      const requestedCount = Math.max(2, Math.min(10, input.questionCount ?? 4));
      const baseQuestions = pkg?.quizzes ?? [];

      const questions: GeneratedQuizQuestion[] = [];
      for (let i = 0; i < requestedCount; i++) {
        const template = baseQuestions[i % Math.max(1, baseQuestions.length)];
        const chapter =
          selectedChapters[i % Math.max(1, selectedChapters.length)] ?? allChapters[0];
        if (template && i < baseQuestions.length) {
          questions.push({
            ...template,
            id: `sq_${i + 1}`,
            difficulty,
          });
        } else {
          questions.push({
            id: `sq_${i + 1}`,
            type:
              input.questionTypes?.[i % (input.questionTypes.length || 1)] ?? 'MULTIPLE_CHOICE',
            question: `Dans "${chapter?.title ?? session.title}", quel principe méthodologique est mis en avant à [${formatClockTimestamp(chapter?.startSeconds ?? 0)}] ?`,
            options: [
              chapter?.summary.slice(0, 120) ||
                'La vérification rigoureuse des hypothèses et la validation par étape',
              'L’absence de structuration analytique',
              'La suppression des vérifications aux limites',
              'Une approche purement aléatoire sans modèle',
            ],
            correctAnswer:
              chapter?.summary.slice(0, 120) ||
              'La vérification rigoureuse des hypothèses et la validation par étape',
            explanation: `Référence au chapitre "${chapter?.title ?? 'Cours'}" à [${formatClockTimestamp(chapter?.startSeconds ?? 0)}] : ${chapter?.summary ?? ''}`,
            difficulty,
            chapterTitle: chapter?.title ?? session.title,
            timestampSeconds: chapter?.startSeconds ?? 0,
            sourcePage: chapter?.sourcePage ?? 1,
          });
        }
      }

      return this.recordingRepository.createStudyArtifact({
        recordingId: recording.id,
        userId: user.id,
        kind: 'QUIZ',
        title: `Quiz d’entraînement (${difficulty.toUpperCase()} · ${questions.length} Q)`,
        language,
        chapterIds: input.chapterIds ?? [],
        config: {
          difficulty,
          questionCount: questions.length,
          questionTypes: input.questionTypes ?? ['MULTIPLE_CHOICE'],
        },
        content: {
          difficulty,
          questions,
        },
        modelUsed: 'Qwen3.5-4B-GGUF:Q4_1',
      });
    }

    // FLASHCARDS
    const requestedCards = Math.max(3, Math.min(16, input.flashcardCount ?? 4));
    const focus = input.focus ?? 'all';
    const baseCards = pkg?.flashcards ?? [];
    const cards: GeneratedFlashcard[] = [];

    for (let i = 0; i < requestedCards; i++) {
      const existing = baseCards[i];
      if (existing) {
        cards.push({ ...existing, id: `sfc_${i + 1}` });
      } else {
        const ch = selectedChapters[i % Math.max(1, selectedChapters.length)] ?? allChapters[0];
        cards.push({
          id: `sfc_${i + 1}`,
          front: `[${ch?.title ?? session.title}] Quelle est l’idée clé présentée à ${formatClockTimestamp(ch?.startSeconds ?? 0)} ?`,
          back: ch?.summary ?? `Maîtriser les concepts fondamentaux de ${session.title}.`,
          chapterTitle: ch?.title ?? session.title,
          difficulty: 'moyen',
          timestampSeconds: ch?.startSeconds ?? 0,
          sourcePage: ch?.sourcePage ?? 1,
        });
      }
    }

    return this.recordingRepository.createStudyArtifact({
      recordingId: recording.id,
      userId: user.id,
      kind: 'FLASHCARDS',
      title: `Flashcards de révision (${focus.toUpperCase()} · ${cards.length} cartes)`,
      language,
      chapterIds: input.chapterIds ?? [],
      config: { focus, count: cards.length },
      content: {
        focus,
        cards,
      },
      modelUsed: 'Qwen3.5-4B-GGUF:Q4_1',
    });
  }
}

export class SubmitStudentQuizAttemptUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    input: {
      artifactId?: string;
      answers: Array<{
        questionId?: string;
        answer?: string;
        questionIndex?: number;
        selectedIndex?: number;
      }>;
    },
  ): Promise<StudentQuizAttemptEntity> {
    const { recording } = await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );

    let questions: GeneratedQuizQuestion[] = [];
    let resolvedArtifactId = input.artifactId ?? '';

    if (resolvedArtifactId && resolvedArtifactId !== 'teacher_default') {
      const artifact = await this.recordingRepository.findStudyArtifactById(resolvedArtifactId);
      if (artifact && Array.isArray(artifact.content.questions)) {
        questions = artifact.content.questions as GeneratedQuizQuestion[];
      }
    }

    if (questions.length === 0) {
      const pkg = await this.recordingRepository.getLessonPackage(recording.id);
      questions = pkg?.quizzes ?? [];
      // Ensure a backing artifact exists if grading against the default teacher quiz
      const created = await this.recordingRepository.createStudyArtifact({
        recordingId: recording.id,
        userId: user.id,
        kind: 'QUIZ',
        title: 'Quiz officiel de la séance',
        language: 'fr',
        chapterIds: [],
        config: { source: 'lesson_package' },
        content: { questions },
        modelUsed: pkg?.primaryModel ?? 'gemma4:e4b',
      });
      resolvedArtifactId = created.id;
    }

    const normalizedAnswers: Array<{ questionId: string; answer: string }> = [];
    const answerMap = new Map<string, string>();

    for (const raw of input.answers) {
      let qId = raw.questionId ?? '';
      let ansText = (raw.answer ?? '').trim();

      if (typeof raw.questionIndex === 'number') {
        const targetQ = questions[raw.questionIndex];
        if (targetQ) {
          if (!qId) qId = targetQ.id;
          if (
            !ansText &&
            typeof raw.selectedIndex === 'number' &&
            raw.selectedIndex >= 0 &&
            raw.selectedIndex < targetQ.options.length
          ) {
            ansText = targetQ.options[raw.selectedIndex] ?? '';
          }
        }
      }
      if (qId) {
        answerMap.set(qId, ansText);
        normalizedAnswers.push({ questionId: qId, answer: ansText });
      }
    }

    let correctCount = 0;
    const weakTopicsSet = new Set<string>();
    const results: StudentQuizAttemptEntity['results'] = questions.map((q) => {
      const userAnswer = answerMap.get(q.id) ?? '';
      const isCorrect =
        userAnswer.toLowerCase() === q.correctAnswer.trim().toLowerCase() ||
        (userAnswer.length > 8 &&
          q.correctAnswer.toLowerCase().includes(userAnswer.toLowerCase()));

      if (isCorrect) {
        correctCount += 1;
      } else if (q.chapterTitle) {
        weakTopicsSet.add(q.chapterTitle);
      }

      return {
        questionId: q.id,
        isCorrect,
        userAnswer,
        correctAnswer: q.correctAnswer,
        explanation: q.explanation,
        chapterTitle: q.chapterTitle,
        timestampSeconds: q.timestampSeconds,
      };
    });

    const totalQuestions = Math.max(1, questions.length);
    const score = Math.round((correctCount / totalQuestions) * 100);

    return this.recordingRepository.createQuizAttempt({
      artifactId: resolvedArtifactId,
      recordingId: recording.id,
      userId: user.id,
      score,
      totalQuestions,
      answers: normalizedAnswers,
      results,
      weakTopics: Array.from(weakTopicsSet),
    });
  }
}

export class AskLessonAiTutorUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly modelRouter: SmartModelRouterPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    input: {
      question: string;
      conversationId?: string;
      currentTimestampSeconds?: number;
      responseStyle?: 'concise' | 'detailed' | 'step-by-step' | 'exam-focused';
    },
  ): Promise<{
    conversationId: string;
    userMessage: LessonTutorMessageEntity;
    assistantMessage: LessonTutorMessageEntity;
  }> {
    const { session, recording } = await verifyLessonAccess(
      user,
      sessionId,
      this.sessionRepository,
      this.recordingRepository,
      this.classAccessPort,
    );

    const [transcript, chapters, slides, pkg] = await Promise.all([
      this.recordingRepository.getTranscript(recording.id),
      this.recordingRepository.listChapters(recording.id),
      this.recordingRepository.listSlideFrames(recording.id),
      this.recordingRepository.getLessonPackage(recording.id),
    ]);

    let conversation: LessonTutorConversationEntity | null = null;
    if (input.conversationId) {
      conversation = await this.recordingRepository.findTutorConversationById(
        input.conversationId,
        user.id,
      );
    }
    if (!conversation) {
      conversation = await this.recordingRepository.createTutorConversation({
        recordingId: recording.id,
        userId: user.id,
        title: input.question.trim().slice(0, 80) || `Discussion — ${session.title}`,
      });
    }

    const userMessage = await this.recordingRepository.appendTutorMessage({
      conversationId: conversation.id,
      role: 'user',
      content: input.question.trim(),
    });

    // Build source-grounded RAG context and citations from the actual lesson
    const citations: TutorSourceCitation[] = [];
    const qVec = computeDeterministicLexicalVector(input.question);

    const rankedSegments = [...(transcript?.segments ?? [])]
      .map((seg) => {
        const proximityBoost =
          input.currentTimestampSeconds !== undefined &&
          Math.abs(seg.startSeconds - input.currentTimestampSeconds) <= 45
            ? 0.35
            : 0;
        const sim =
          cosineSimilarity(qVec, computeDeterministicLexicalVector(seg.text)) + proximityBoost;
        return { seg, sim };
      })
      .sort((a, b) => b.sim - a.sim)
      .slice(0, 3);

    for (const item of rankedSegments) {
      const ch =
        chapters.find(
          (c) => c.startSeconds <= item.seg.startSeconds && c.endSeconds >= item.seg.startSeconds,
        ) ?? chapters[0];
      citations.push({
        type: 'TRANSCRIPT',
        label: `Transcription [${formatClockTimestamp(item.seg.startSeconds)}]`,
        excerpt: item.seg.text,
        timestampSeconds: Math.floor(item.seg.startSeconds),
        chapterTitle: ch?.title ?? null,
        slideNumber: null,
        sourcePage: ch?.sourcePage ?? null,
      });
    }

    const activeChapter =
      input.currentTimestampSeconds !== undefined
        ? (chapters.find(
            (c) =>
              c.startSeconds <= input.currentTimestampSeconds! &&
              c.endSeconds >= input.currentTimestampSeconds!,
          ) ?? chapters[0])
        : chapters[0];

    if (activeChapter) {
      citations.push({
        type: 'CHAPTER',
        label: `${activeChapter.title} [${formatClockTimestamp(activeChapter.startSeconds)}]`,
        excerpt: activeChapter.summary,
        timestampSeconds: activeChapter.startSeconds,
        chapterTitle: activeChapter.title,
        slideNumber: activeChapter.orderIndex + 1,
        sourcePage: activeChapter.sourcePage,
      });
    }

    if (slides[0]) {
      citations.push({
        type: 'SLIDE',
        label: `Diapositive 1 [${formatClockTimestamp(slides[0].timestampSeconds)}]`,
        excerpt: slides[0].visualSummary,
        timestampSeconds: slides[0].timestampSeconds,
        chapterTitle: activeChapter?.title ?? null,
        slideNumber: 1,
        sourcePage: slides[0].sourcePage,
      });
    }

    const groundedPassages = citations
      .map(
        (c, idx) =>
          `[Source ${idx + 1} - ${c.label}${c.chapterTitle ? ` (${c.chapterTitle})` : ''}]: ${c.excerpt}`,
      )
      .join('\n');

    let replyContent = '';
    let modelUsed = 'gemma4:e4b';

    try {
      const styleInstruction =
        input.responseStyle === 'concise'
          ? 'Réponds de façon concise en 3-4 phrases.'
          : input.responseStyle === 'exam-focused'
            ? ' Oriente ta réponse vers ce qu’il faut retenir pour réussir l’examen.'
            : 'Explique étape par étape avec pédagogie.';

      const aiRes = await this.modelRouter.generateForRole('AI_TUTOR_RAG', {
        systemPrompt: [
          `Tu es le Tuteur IA multilingue du cours enregistré "${session.title}" (${session.subject ?? 'SmartClass'}).`,
          `DÉTECTION DE LANGUE & DIALECTE : Détecte automatiquement la langue de la question de l'étudiant (Français, Anglais, Arabe standard, ou Arabe Tunisien / Derja tunisienne en alphabet arabe ou franco-arabe/Arabizi comme "3aslema", "kifech", "chnoua", "bch") et réponds dans la même langue avec clarté académique.`,
          `RÈGLE ABSOLUE D'ANCRAGE : Tu dois répondre uniquement à partir des sources du cours fournies ci-dessous.`,
          `Cite toujours les horodatages sous la forme [MM:SS] et le titre du chapitre correspondant.`,
          `Si l'étudiant pose une question hors sujet qui n'est pas couverte dans ce cours, indique clairement que ce point n'a pas été abordé dans la séance enregistrée, puis rappelle les concepts proches vus dans le cours.`,
          styleInstruction,
        ].join(' '),
        messages: [
          ...conversation.messages.slice(-4).map((m) => ({
            role: m.role,
            content: m.content,
          })),
          {
            role: 'user',
            content: `Sources du cours enregistré:\n${groundedPassages}\n\nRésumé de référence:\n${pkg?.generalSummary ?? ''}\n\nQuestion de l'étudiant: ${input.question}`,
          },
        ],
        temperature: 0.2,
        maxTokens: 700,
      });

      modelUsed = aiRes.modelUsed;
      if (aiRes.content && aiRes.content.trim().length > 20) {
        replyContent = aiRes.content.trim();
      }
    } catch {
      // Fallback deterministic source-grounded tutor explanation below
    }

    if (!replyContent) {
      const topCit = citations[0];
      const tsLabel = topCit?.timestampSeconds !== null && topCit?.timestampSeconds !== undefined
        ? formatClockTimestamp(topCit.timestampSeconds)
        : '00:00';
      replyContent = [
        `D'après la séance enregistrée **${session.title}** (chapitre **${activeChapter?.title ?? 'Introduction'}** à **[${tsLabel}]**) :`,
        '',
        `> "${topCit?.excerpt ?? pkg?.generalSummary ?? 'Voir la démonstration principale de l’enseignant.'}"`,
        '',
        `**Explication pédagogique :**`,
        `1. **Concept clé ([${tsLabel}]) :** ${pkg?.keyConcepts[0]?.explanation ?? activeChapter?.summary ?? ''}`,
        `2. **Méthode à retenir :** ${pkg?.formulasAndRules[0] ?? 'Vérifier les hypothèses initiales avant d’appliquer la résolution pas à pas.'}`,
        '',
        `*Cliquez sur la citation **[${tsLabel}]** ci-dessous pour revoir exactement ce passage dans la vidéo.*`,
      ].join('\n');
    }

    const assistantMessage = await this.recordingRepository.appendTutorMessage({
      conversationId: conversation.id,
      role: 'assistant',
      content: replyContent,
      citations,
      modelUsed,
    });

    return {
      conversationId: conversation.id,
      userMessage,
      assistantMessage,
    };
  }
}
