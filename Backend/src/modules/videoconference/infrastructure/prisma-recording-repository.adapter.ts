import { Prisma, type PrismaClient } from '@prisma/client';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type {
  GeneratedFlashcard,
  GeneratedQuizQuestion,
  ImportantMoment,
  LessonConcept,
  LessonDefinition,
  LessonExample,
  LessonPackageEntity,
  LessonPackageVersionEntity,
  LessonQualityReport,
  LessonTutorConversationEntity,
  LessonTutorMessageEntity,
  ProcessingJobStatus,
  ProcessingStage,
  RecordingChapterEntity,
  RecordingEntity,
  RecordingProcessingJobEntity,
  RecordingSlideFrameEntity,
  RecordingStatus,
  RecordingTranscriptEntity,
  StageLogEntry,
  StudentLessonArtifactEntity,
  StudentLessonBookmarkEntity,
  StudentLessonNoteEntity,
  StudentLessonProgressEntity,
  StudentQuizAttemptEntity,
  StudyArtifactKind,
  TutorSourceCitation,
} from '../domain/recording.entity.js';
import type {
  RecordingRepositoryPort,
  UpsertRecordingInput,
} from '../domain/recording-repository.port.js';

export class PrismaRecordingRepositoryAdapter implements RecordingRepositoryPort {
  constructor(private readonly prisma: PrismaClient = getPrismaClient()) {}

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapRecording(row: any): RecordingEntity {
    return {
      id: row.id,
      sessionId: row.sessionId,
      classGroupId: row.classGroupId,
      hostId: row.hostId,
      status: row.status as RecordingStatus,
      egressId: row.egressId,
      storageKey: row.storageKey,
      mimeType: row.mimeType,
      sizeBytes: row.sizeBytes !== null && row.sizeBytes !== undefined ? Number(row.sizeBytes) : null,
      durationSeconds: row.durationSeconds,
      width: row.width,
      height: row.height,
      thumbnailKey: row.thumbnailKey,
      sourceDocKey: row.sourceDocKey,
      sourceDocTitle: row.sourceDocTitle,
      sourceDocText: row.sourceDocText,
      errorCode: row.errorCode,
      errorMessage: row.errorMessage,
      startedAt: row.startedAt,
      stoppedAt: row.stoppedAt,
      publishedAt: row.publishedAt,
      processingVersion: row.processingVersion,
      aiModelUsed: row.aiModelUsed,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapProcessingJob(row: any): RecordingProcessingJobEntity {
    return {
      id: row.id,
      recordingId: row.recordingId,
      status: row.status as ProcessingJobStatus,
      stage: row.stage as ProcessingStage,
      progress: row.progress,
      attempts: row.attempts,
      maxAttempts: row.maxAttempts,
      lockedAt: row.lockedAt,
      workerId: row.workerId,
      errorMessage: row.errorMessage,
      stageLogs: Array.isArray(row.stageLogs) ? (row.stageLogs as StageLogEntry[]) : [],
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapTranscript(row: any): RecordingTranscriptEntity {
    return {
      id: row.id,
      recordingId: row.recordingId,
      language: row.language,
      fullText: row.fullText,
      vttContent: row.vttContent,
      srtContent: row.srtContent,
      qualityScore: row.qualityScore,
      modelUsed: row.modelUsed,
      updatedById: row.updatedById,
      segments: Array.isArray(row.segments)
        ? // eslint-disable-next-line @typescript-eslint/no-explicit-any
          row.segments.map((seg: any) => ({
            id: seg.id,
            transcriptId: seg.transcriptId,
            recordingId: seg.recordingId,
            orderIndex: seg.orderIndex,
            startSeconds: seg.startSeconds,
            endSeconds: seg.endSeconds,
            text: seg.text,
            speaker: seg.speaker,
            confidence: seg.confidence,
          }))
        : [],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapSlideFrame(row: any): RecordingSlideFrameEntity {
    return {
      id: row.id,
      recordingId: row.recordingId,
      timestampSeconds: row.timestampSeconds,
      storageKey: row.storageKey,
      perceptualHash: row.perceptualHash,
      ocrText: row.ocrText,
      visualSummary: row.visualSummary,
      sourcePage: row.sourcePage,
      modelUsed: row.modelUsed,
      createdAt: row.createdAt,
    };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapChapter(row: any): RecordingChapterEntity {
    return {
      id: row.id,
      recordingId: row.recordingId,
      orderIndex: row.orderIndex,
      title: row.title,
      summary: row.summary,
      startSeconds: row.startSeconds,
      endSeconds: row.endSeconds,
      keyConcepts: Array.isArray(row.keyConcepts) ? (row.keyConcepts as string[]) : [],
      slideFrameId: row.slideFrameId,
      sourcePage: row.sourcePage,
    };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapLessonPackage(row: any): LessonPackageEntity {
    const defaultQuality: LessonQualityReport = {
      isValid: true,
      score: 100,
      warnings: [],
      checkedAt: new Date().toISOString(),
      transcriptCoverageRatio: 1,
      chaptersAlignedCount: 0,
    };
    return {
      id: row.id,
      recordingId: row.recordingId,
      version: row.version,
      structuredNotes: row.structuredNotes,
      generalSummary: row.generalSummary,
      keyConcepts: Array.isArray(row.keyConcepts) ? (row.keyConcepts as LessonConcept[]) : [],
      definitions: Array.isArray(row.definitions) ? (row.definitions as LessonDefinition[]) : [],
      importantExamples: Array.isArray(row.importantExamples)
        ? (row.importantExamples as LessonExample[])
        : [],
      learningObjectives: Array.isArray(row.learningObjectives)
        ? (row.learningObjectives as string[])
        : [],
      formulasAndRules: Array.isArray(row.formulasAndRules)
        ? (row.formulasAndRules as string[])
        : [],
      importantMoments: Array.isArray(row.importantMoments)
        ? (row.importantMoments as ImportantMoment[])
        : [],
      revisionSheet: row.revisionSheet,
      mindMapMermaid: row.mindMapMermaid,
      suggestedStudyOrder: Array.isArray(row.suggestedStudyOrder)
        ? (row.suggestedStudyOrder as string[])
        : [],
      flashcards: Array.isArray(row.flashcards) ? (row.flashcards as GeneratedFlashcard[]) : [],
      quizzes: Array.isArray(row.quizzes) ? (row.quizzes as GeneratedQuizQuestion[]) : [],
      qualityReport:
        row.qualityReport && typeof row.qualityReport === 'object'
          ? (row.qualityReport as LessonQualityReport)
          : defaultQuality,
      primaryModel: row.primaryModel,
      secondaryModel: row.secondaryModel,
      approvedById: row.approvedById,
      approvedAt: row.approvedAt,
      publishedAt: row.publishedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  public async findBySessionId(sessionId: string): Promise<RecordingEntity | null> {
    const row = await this.prisma.recording.findUnique({ where: { sessionId } });
    return row ? this.mapRecording(row) : null;
  }

  public async findById(recordingId: string): Promise<RecordingEntity | null> {
    const row = await this.prisma.recording.findUnique({ where: { id: recordingId } });
    return row ? this.mapRecording(row) : null;
  }

  public async findByEgressId(egressId: string): Promise<RecordingEntity | null> {
    const row = await this.prisma.recording.findUnique({ where: { egressId } });
    return row ? this.mapRecording(row) : null;
  }

  public async listByClassGroups(params: {
    classGroupIds?: string[];
    hostId?: string;
    status?: RecordingStatus;
    publishedOnly?: boolean;
  }): Promise<RecordingEntity[]> {
    const where: Prisma.RecordingWhereInput = {
      status: { not: 'DELETED' },
    };
    if (params.classGroupIds && params.classGroupIds.length > 0) {
      where.classGroupId = { in: params.classGroupIds };
    }
    if (params.hostId) {
      where.hostId = params.hostId;
    }
    if (params.status) {
      where.status = params.status;
    } else if (params.publishedOnly) {
      where.status = 'PUBLISHED';
    }
    const rows = await this.prisma.recording.findMany({
      where,
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.mapRecording(r));
  }

  public async upsertBySessionId(input: UpsertRecordingInput): Promise<RecordingEntity> {
    const row = await this.prisma.recording.upsert({
      where: { sessionId: input.sessionId },
      create: {
        sessionId: input.sessionId,
        classGroupId: input.classGroupId,
        hostId: input.hostId,
        status: input.status,
        egressId: input.egressId ?? null,
        storageKey: input.storageKey ?? null,
        mimeType: input.mimeType ?? 'video/mp4',
        sizeBytes:
          input.sizeBytes !== undefined && input.sizeBytes !== null
            ? BigInt(input.sizeBytes)
            : null,
        durationSeconds: input.durationSeconds ?? null,
        width: input.width ?? null,
        height: input.height ?? null,
        thumbnailKey: input.thumbnailKey ?? null,
        sourceDocKey: input.sourceDocKey ?? null,
        sourceDocTitle: input.sourceDocTitle ?? null,
        sourceDocText: input.sourceDocText ?? null,
        errorCode: input.errorCode ?? null,
        errorMessage: input.errorMessage ?? null,
        startedAt: input.startedAt ?? null,
        stoppedAt: input.stoppedAt ?? null,
        publishedAt: input.publishedAt ?? null,
        processingVersion: input.processingVersion ?? 1,
        aiModelUsed: input.aiModelUsed ?? null,
      },
      update: {
        hostId: input.hostId,
        status: input.status,
        ...(input.egressId !== undefined ? { egressId: input.egressId } : {}),
        ...(input.storageKey !== undefined ? { storageKey: input.storageKey } : {}),
        ...(input.mimeType !== undefined ? { mimeType: input.mimeType } : {}),
        ...(input.sizeBytes !== undefined
          ? { sizeBytes: input.sizeBytes !== null ? BigInt(input.sizeBytes) : null }
          : {}),
        ...(input.durationSeconds !== undefined ? { durationSeconds: input.durationSeconds } : {}),
        ...(input.width !== undefined ? { width: input.width } : {}),
        ...(input.height !== undefined ? { height: input.height } : {}),
        ...(input.thumbnailKey !== undefined ? { thumbnailKey: input.thumbnailKey } : {}),
        ...(input.sourceDocKey !== undefined ? { sourceDocKey: input.sourceDocKey } : {}),
        ...(input.sourceDocTitle !== undefined ? { sourceDocTitle: input.sourceDocTitle } : {}),
        ...(input.sourceDocText !== undefined ? { sourceDocText: input.sourceDocText } : {}),
        ...(input.errorCode !== undefined ? { errorCode: input.errorCode } : {}),
        ...(input.errorMessage !== undefined ? { errorMessage: input.errorMessage } : {}),
        ...(input.startedAt !== undefined ? { startedAt: input.startedAt } : {}),
        ...(input.stoppedAt !== undefined ? { stoppedAt: input.stoppedAt } : {}),
        ...(input.publishedAt !== undefined ? { publishedAt: input.publishedAt } : {}),
        ...(input.processingVersion !== undefined
          ? { processingVersion: input.processingVersion }
          : {}),
        ...(input.aiModelUsed !== undefined ? { aiModelUsed: input.aiModelUsed } : {}),
      },
    });
    return this.mapRecording(row);
  }

  public async updateRecording(
    recordingId: string,
    patch: Partial<Omit<UpsertRecordingInput, 'sessionId' | 'classGroupId'>>,
  ): Promise<RecordingEntity> {
    const data: Prisma.RecordingUpdateInput = {};
    if (patch.status !== undefined) data.status = patch.status;
    if (patch.egressId !== undefined) data.egressId = patch.egressId;
    if (patch.storageKey !== undefined) data.storageKey = patch.storageKey;
    if (patch.mimeType !== undefined) data.mimeType = patch.mimeType;
    if (patch.sizeBytes !== undefined) {
      data.sizeBytes = patch.sizeBytes !== null ? BigInt(patch.sizeBytes) : null;
    }
    if (patch.durationSeconds !== undefined) data.durationSeconds = patch.durationSeconds;
    if (patch.width !== undefined) data.width = patch.width;
    if (patch.height !== undefined) data.height = patch.height;
    if (patch.thumbnailKey !== undefined) data.thumbnailKey = patch.thumbnailKey;
    if (patch.sourceDocKey !== undefined) data.sourceDocKey = patch.sourceDocKey;
    if (patch.sourceDocTitle !== undefined) data.sourceDocTitle = patch.sourceDocTitle;
    if (patch.sourceDocText !== undefined) data.sourceDocText = patch.sourceDocText;
    if (patch.errorCode !== undefined) data.errorCode = patch.errorCode;
    if (patch.errorMessage !== undefined) data.errorMessage = patch.errorMessage;
    if (patch.startedAt !== undefined) data.startedAt = patch.startedAt;
    if (patch.stoppedAt !== undefined) data.stoppedAt = patch.stoppedAt;
    if (patch.publishedAt !== undefined) data.publishedAt = patch.publishedAt;
    if (patch.processingVersion !== undefined) data.processingVersion = patch.processingVersion;
    if (patch.aiModelUsed !== undefined) data.aiModelUsed = patch.aiModelUsed;

    const row = await this.prisma.recording.update({
      where: { id: recordingId },
      data,
    });
    return this.mapRecording(row);
  }

  public async createProcessingJob(recordingId: string): Promise<RecordingProcessingJobEntity> {
    const row = await this.prisma.recordingProcessingJob.create({
      data: {
        recordingId,
        status: 'QUEUED',
        stage: 'VALIDATION',
        progress: 0,
        attempts: 0,
        maxAttempts: 3,
        stageLogs: [],
      },
    });
    return this.mapProcessingJob(row);
  }

  public async findLatestJobByRecordingId(
    recordingId: string,
  ): Promise<RecordingProcessingJobEntity | null> {
    const row = await this.prisma.recordingProcessingJob.findFirst({
      where: { recordingId },
      orderBy: { createdAt: 'desc' },
    });
    return row ? this.mapProcessingJob(row) : null;
  }

  public async listJobsByRecordingId(recordingId: string): Promise<RecordingProcessingJobEntity[]> {
    const rows = await this.prisma.recordingProcessingJob.findMany({
      where: { recordingId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((r) => this.mapProcessingJob(r));
  }

  public async updateProcessingJob(
    jobId: string,
    patch: {
      status?: ProcessingJobStatus;
      stage?: ProcessingStage;
      progress?: number;
      attempts?: number;
      lockedAt?: Date | null;
      workerId?: string | null;
      errorMessage?: string | null;
      stageLogs?: StageLogEntry[];
      startedAt?: Date | null;
      completedAt?: Date | null;
    },
  ): Promise<RecordingProcessingJobEntity> {
    const data: Prisma.RecordingProcessingJobUpdateInput = {};
    if (patch.status !== undefined) data.status = patch.status;
    if (patch.stage !== undefined) data.stage = patch.stage;
    if (patch.progress !== undefined) data.progress = patch.progress;
    if (patch.attempts !== undefined) data.attempts = patch.attempts;
    if (patch.lockedAt !== undefined) data.lockedAt = patch.lockedAt;
    if (patch.workerId !== undefined) data.workerId = patch.workerId;
    if (patch.errorMessage !== undefined) data.errorMessage = patch.errorMessage;
    if (patch.stageLogs !== undefined) {
      data.stageLogs = patch.stageLogs as unknown as Prisma.InputJsonValue;
    }
    if (patch.startedAt !== undefined) data.startedAt = patch.startedAt;
    if (patch.completedAt !== undefined) data.completedAt = patch.completedAt;

    const row = await this.prisma.recordingProcessingJob.update({
      where: { id: jobId },
      data,
    });
    return this.mapProcessingJob(row);
  }

  public async saveTranscript(params: {
    recordingId: string;
    language: string;
    fullText: string;
    vttContent: string;
    srtContent: string;
    qualityScore: number;
    modelUsed: string | null;
    updatedById?: string | null;
    segments: Array<{
      orderIndex: number;
      startSeconds: number;
      endSeconds: number;
      text: string;
      speaker?: string | null;
      confidence?: number;
    }>;
  }): Promise<RecordingTranscriptEntity> {
    const result = await this.prisma.$transaction(async (tx) => {
      const transcript = await tx.recordingTranscript.upsert({
        where: { recordingId: params.recordingId },
        create: {
          recordingId: params.recordingId,
          language: params.language,
          fullText: params.fullText,
          vttContent: params.vttContent,
          srtContent: params.srtContent,
          qualityScore: params.qualityScore,
          modelUsed: params.modelUsed,
          updatedById: params.updatedById ?? null,
        },
        update: {
          language: params.language,
          fullText: params.fullText,
          vttContent: params.vttContent,
          srtContent: params.srtContent,
          qualityScore: params.qualityScore,
          modelUsed: params.modelUsed,
          updatedById: params.updatedById ?? null,
        },
      });

      await tx.recordingTranscriptSegment.deleteMany({
        where: { transcriptId: transcript.id },
      });

      if (params.segments.length > 0) {
        await tx.recordingTranscriptSegment.createMany({
          data: params.segments.map((seg) => ({
            transcriptId: transcript.id,
            recordingId: params.recordingId,
            orderIndex: seg.orderIndex,
            startSeconds: seg.startSeconds,
            endSeconds: seg.endSeconds,
            text: seg.text,
            speaker: seg.speaker ?? null,
            confidence: seg.confidence ?? 1.0,
          })),
        });
      }

      return tx.recordingTranscript.findUniqueOrThrow({
        where: { id: transcript.id },
        include: {
          segments: {
            orderBy: { orderIndex: 'asc' },
          },
        },
      });
    });

    return this.mapTranscript(result);
  }

  public async getTranscript(recordingId: string): Promise<RecordingTranscriptEntity | null> {
    const row = await this.prisma.recordingTranscript.findUnique({
      where: { recordingId },
      include: {
        segments: {
          orderBy: { orderIndex: 'asc' },
        },
      },
    });
    return row ? this.mapTranscript(row) : null;
  }

  public async replaceSlideFrames(
    recordingId: string,
    frames: Array<{
      timestampSeconds: number;
      storageKey: string | null;
      perceptualHash: string | null;
      ocrText: string;
      visualSummary: string;
      sourcePage: number | null;
      modelUsed: string | null;
    }>,
  ): Promise<RecordingSlideFrameEntity[]> {
    const created = await this.prisma.$transaction(async (tx) => {
      await tx.recordingSlideFrame.deleteMany({ where: { recordingId } });
      const results = [];
      for (const frame of frames) {
        const item = await tx.recordingSlideFrame.create({
          data: {
            recordingId,
            timestampSeconds: frame.timestampSeconds,
            storageKey: frame.storageKey,
            perceptualHash: frame.perceptualHash,
            ocrText: frame.ocrText,
            visualSummary: frame.visualSummary,
            sourcePage: frame.sourcePage,
            modelUsed: frame.modelUsed,
          },
        });
        results.push(item);
      }
      return results;
    });

    return created.map((r) => this.mapSlideFrame(r));
  }

  public async listSlideFrames(recordingId: string): Promise<RecordingSlideFrameEntity[]> {
    const rows = await this.prisma.recordingSlideFrame.findMany({
      where: { recordingId },
      orderBy: { timestampSeconds: 'asc' },
    });
    return rows.map((r) => this.mapSlideFrame(r));
  }

  public async replaceChapters(
    recordingId: string,
    chapters: Array<{
      orderIndex: number;
      title: string;
      summary: string;
      startSeconds: number;
      endSeconds: number;
      keyConcepts: string[];
      slideFrameId?: string | null;
      sourcePage?: number | null;
    }>,
  ): Promise<RecordingChapterEntity[]> {
    const created = await this.prisma.$transaction(async (tx) => {
      await tx.recordingChapter.deleteMany({ where: { recordingId } });
      const results = [];
      for (const ch of chapters) {
        const item = await tx.recordingChapter.create({
          data: {
            recordingId,
            orderIndex: ch.orderIndex,
            title: ch.title,
            summary: ch.summary,
            startSeconds: ch.startSeconds,
            endSeconds: ch.endSeconds,
            keyConcepts: ch.keyConcepts,
            slideFrameId: ch.slideFrameId ?? null,
            sourcePage: ch.sourcePage ?? null,
          },
        });
        results.push(item);
      }
      return results;
    });
    return created.map((r) => this.mapChapter(r));
  }

  public async updateChapter(
    chapterId: string,
    patch: {
      title?: string;
      summary?: string;
      startSeconds?: number;
      endSeconds?: number;
      keyConcepts?: string[];
    },
  ): Promise<RecordingChapterEntity | null> {
    const existing = await this.prisma.recordingChapter.findUnique({ where: { id: chapterId } });
    if (!existing) return null;
    const data: Prisma.RecordingChapterUpdateInput = {};
    if (patch.title !== undefined) data.title = patch.title;
    if (patch.summary !== undefined) data.summary = patch.summary;
    if (patch.startSeconds !== undefined) data.startSeconds = patch.startSeconds;
    if (patch.endSeconds !== undefined) data.endSeconds = patch.endSeconds;
    if (patch.keyConcepts !== undefined) {
      data.keyConcepts = patch.keyConcepts;
    }
    const updated = await this.prisma.recordingChapter.update({
      where: { id: chapterId },
      data,
    });
    return this.mapChapter(updated);
  }

  public async listChapters(recordingId: string): Promise<RecordingChapterEntity[]> {
    const rows = await this.prisma.recordingChapter.findMany({
      where: { recordingId },
      orderBy: { orderIndex: 'asc' },
    });
    return rows.map((r) => this.mapChapter(r));
  }

  public async saveLessonPackage(
    recordingId: string,
    data: Omit<LessonPackageEntity, 'id' | 'recordingId' | 'createdAt' | 'updatedAt'>,
    versionMeta?: { editedById?: string | null; changeSummary?: string },
  ): Promise<LessonPackageEntity> {
    const saved = await this.prisma.$transaction(async (tx) => {
      const pkg = await tx.lessonPackage.upsert({
        where: { recordingId },
        create: {
          recordingId,
          version: data.version,
          structuredNotes: data.structuredNotes,
          generalSummary: data.generalSummary,
          keyConcepts: data.keyConcepts as unknown as Prisma.InputJsonValue,
          definitions: data.definitions as unknown as Prisma.InputJsonValue,
          importantExamples: data.importantExamples as unknown as Prisma.InputJsonValue,
          learningObjectives: data.learningObjectives,
          formulasAndRules: data.formulasAndRules,
          importantMoments: data.importantMoments as unknown as Prisma.InputJsonValue,
          revisionSheet: data.revisionSheet,
          mindMapMermaid: data.mindMapMermaid,
          suggestedStudyOrder: data.suggestedStudyOrder,
          flashcards: data.flashcards as unknown as Prisma.InputJsonValue,
          quizzes: data.quizzes as unknown as Prisma.InputJsonValue,
          qualityReport: data.qualityReport as unknown as Prisma.InputJsonValue,
          primaryModel: data.primaryModel,
          secondaryModel: data.secondaryModel,
          approvedById: data.approvedById,
          approvedAt: data.approvedAt,
          publishedAt: data.publishedAt,
        },
        update: {
          version: data.version,
          structuredNotes: data.structuredNotes,
          generalSummary: data.generalSummary,
          keyConcepts: data.keyConcepts as unknown as Prisma.InputJsonValue,
          definitions: data.definitions as unknown as Prisma.InputJsonValue,
          importantExamples: data.importantExamples as unknown as Prisma.InputJsonValue,
          learningObjectives: data.learningObjectives,
          formulasAndRules: data.formulasAndRules,
          importantMoments: data.importantMoments as unknown as Prisma.InputJsonValue,
          revisionSheet: data.revisionSheet,
          mindMapMermaid: data.mindMapMermaid,
          suggestedStudyOrder: data.suggestedStudyOrder,
          flashcards: data.flashcards as unknown as Prisma.InputJsonValue,
          quizzes: data.quizzes as unknown as Prisma.InputJsonValue,
          qualityReport: data.qualityReport as unknown as Prisma.InputJsonValue,
          primaryModel: data.primaryModel,
          secondaryModel: data.secondaryModel,
          approvedById: data.approvedById,
          approvedAt: data.approvedAt,
          publishedAt: data.publishedAt,
        },
      });

      await tx.lessonPackageVersion.create({
        data: {
          lessonPackageId: pkg.id,
          version: pkg.version,
          snapshot: {
            structuredNotes: data.structuredNotes,
            generalSummary: data.generalSummary,
            keyConcepts: data.keyConcepts,
            definitions: data.definitions,
            importantExamples: data.importantExamples,
            learningObjectives: data.learningObjectives,
            formulasAndRules: data.formulasAndRules,
            importantMoments: data.importantMoments,
            revisionSheet: data.revisionSheet,
            mindMapMermaid: data.mindMapMermaid,
            suggestedStudyOrder: data.suggestedStudyOrder,
            flashcards: data.flashcards,
            quizzes: data.quizzes,
          } as unknown as Prisma.InputJsonValue,
          editedById: versionMeta?.editedById ?? null,
          changeSummary: versionMeta?.changeSummary ?? `Version ${pkg.version}`,
        },
      });

      return pkg;
    });

    return this.mapLessonPackage(saved);
  }

  public async getLessonPackage(recordingId: string): Promise<LessonPackageEntity | null> {
    const row = await this.prisma.lessonPackage.findUnique({ where: { recordingId } });
    return row ? this.mapLessonPackage(row) : null;
  }

  public async listLessonPackageVersions(
    lessonPackageId: string,
  ): Promise<LessonPackageVersionEntity[]> {
    const rows = await this.prisma.lessonPackageVersion.findMany({
      where: { lessonPackageId },
      orderBy: { version: 'desc' },
    });
    return rows.map((r) => ({
      id: r.id,
      lessonPackageId: r.lessonPackageId,
      version: r.version,
      snapshot:
        r.snapshot && typeof r.snapshot === 'object'
          ? (r.snapshot as Record<string, unknown>)
          : {},
      editedById: r.editedById,
      changeSummary: r.changeSummary,
      createdAt: r.createdAt,
    }));
  }

  public async createStudyArtifact(params: {
    recordingId: string;
    userId: string;
    kind: StudyArtifactKind;
    title: string;
    language: string;
    chapterIds: string[];
    config: Record<string, unknown>;
    content: Record<string, unknown>;
    modelUsed: string | null;
  }): Promise<StudentLessonArtifactEntity> {
    const row = await this.prisma.studentLessonArtifact.create({
      data: {
        recordingId: params.recordingId,
        userId: params.userId,
        kind: params.kind,
        title: params.title,
        language: params.language,
        chapterIds: params.chapterIds,
        config: params.config as unknown as Prisma.InputJsonValue,
        content: params.content as unknown as Prisma.InputJsonValue,
        modelUsed: params.modelUsed,
      },
    });
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      kind: row.kind as StudyArtifactKind,
      title: row.title,
      language: row.language,
      chapterIds: Array.isArray(row.chapterIds) ? (row.chapterIds as string[]) : [],
      config:
        row.config && typeof row.config === 'object' ? (row.config as Record<string, unknown>) : {},
      content:
        row.content && typeof row.content === 'object'
          ? (row.content as Record<string, unknown>)
          : {},
      modelUsed: row.modelUsed,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  public async listStudyArtifacts(
    recordingId: string,
    userId: string,
    kind?: StudyArtifactKind,
  ): Promise<StudentLessonArtifactEntity[]> {
    const rows = await this.prisma.studentLessonArtifact.findMany({
      where: {
        recordingId,
        userId,
        ...(kind ? { kind } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map((row) => ({
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      kind: row.kind as StudyArtifactKind,
      title: row.title,
      language: row.language,
      chapterIds: Array.isArray(row.chapterIds) ? (row.chapterIds as string[]) : [],
      config:
        row.config && typeof row.config === 'object' ? (row.config as Record<string, unknown>) : {},
      content:
        row.content && typeof row.content === 'object'
          ? (row.content as Record<string, unknown>)
          : {},
      modelUsed: row.modelUsed,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    }));
  }

  public async findStudyArtifactById(
    artifactId: string,
  ): Promise<StudentLessonArtifactEntity | null> {
    const row = await this.prisma.studentLessonArtifact.findUnique({ where: { id: artifactId } });
    if (!row) return null;
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      kind: row.kind as StudyArtifactKind,
      title: row.title,
      language: row.language,
      chapterIds: Array.isArray(row.chapterIds) ? (row.chapterIds as string[]) : [],
      config:
        row.config && typeof row.config === 'object' ? (row.config as Record<string, unknown>) : {},
      content:
        row.content && typeof row.content === 'object'
          ? (row.content as Record<string, unknown>)
          : {},
      modelUsed: row.modelUsed,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  public async createQuizAttempt(params: {
    artifactId: string;
    recordingId: string;
    userId: string;
    score: number;
    totalQuestions: number;
    answers: Array<{ questionId: string; answer: string }>;
    results: StudentQuizAttemptEntity['results'];
    weakTopics: string[];
  }): Promise<StudentQuizAttemptEntity> {
    const row = await this.prisma.studentQuizAttempt.create({
      data: {
        artifactId: params.artifactId,
        recordingId: params.recordingId,
        userId: params.userId,
        score: params.score,
        totalQuestions: params.totalQuestions,
        answers: params.answers as unknown as Prisma.InputJsonValue,
        results: params.results as unknown as Prisma.InputJsonValue,
        weakTopics: params.weakTopics,
      },
    });
    return {
      id: row.id,
      artifactId: row.artifactId,
      recordingId: row.recordingId,
      userId: row.userId,
      score: row.score,
      totalQuestions: row.totalQuestions,
      answers: Array.isArray(row.answers)
        ? (row.answers as Array<{ questionId: string; answer: string }>)
        : [],
      results: Array.isArray(row.results)
        ? (row.results as StudentQuizAttemptEntity['results'])
        : [],
      weakTopics: Array.isArray(row.weakTopics) ? (row.weakTopics as string[]) : [],
      completedAt: row.completedAt,
    };
  }

  public async listQuizAttempts(
    recordingId: string,
    userId: string,
  ): Promise<StudentQuizAttemptEntity[]> {
    const rows = await this.prisma.studentQuizAttempt.findMany({
      where: { recordingId, userId },
      orderBy: { completedAt: 'desc' },
    });
    return rows.map((row) => ({
      id: row.id,
      artifactId: row.artifactId,
      recordingId: row.recordingId,
      userId: row.userId,
      score: row.score,
      totalQuestions: row.totalQuestions,
      answers: Array.isArray(row.answers)
        ? (row.answers as Array<{ questionId: string; answer: string }>)
        : [],
      results: Array.isArray(row.results)
        ? (row.results as StudentQuizAttemptEntity['results'])
        : [],
      weakTopics: Array.isArray(row.weakTopics) ? (row.weakTopics as string[]) : [],
      completedAt: row.completedAt,
    }));
  }

  public async upsertProgress(params: {
    recordingId: string;
    userId: string;
    lastPositionSeconds?: number;
    watchedSeconds?: number;
    completedChapters?: string[];
    flashcardKnownIds?: string[];
    flashcardReviewIds?: string[];
  }): Promise<StudentLessonProgressEntity> {
    const row = await this.prisma.studentLessonProgress.upsert({
      where: {
        recordingId_userId: {
          recordingId: params.recordingId,
          userId: params.userId,
        },
      },
      create: {
        recordingId: params.recordingId,
        userId: params.userId,
        lastPositionSeconds: params.lastPositionSeconds ?? 0,
        watchedSeconds: params.watchedSeconds ?? 0,
        completedChapters: params.completedChapters ?? [],
        flashcardKnownIds: params.flashcardKnownIds ?? [],
        flashcardReviewIds: params.flashcardReviewIds ?? [],
      },
      update: {
        ...(params.lastPositionSeconds !== undefined
          ? { lastPositionSeconds: params.lastPositionSeconds }
          : {}),
        ...(params.watchedSeconds !== undefined ? { watchedSeconds: params.watchedSeconds } : {}),
        ...(params.completedChapters !== undefined
          ? { completedChapters: params.completedChapters }
          : {}),
        ...(params.flashcardKnownIds !== undefined
          ? { flashcardKnownIds: params.flashcardKnownIds }
          : {}),
        ...(params.flashcardReviewIds !== undefined
          ? { flashcardReviewIds: params.flashcardReviewIds }
          : {}),
      },
    });
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      lastPositionSeconds: row.lastPositionSeconds,
      watchedSeconds: row.watchedSeconds,
      completedChapters: Array.isArray(row.completedChapters)
        ? (row.completedChapters as string[])
        : [],
      flashcardKnownIds: Array.isArray(row.flashcardKnownIds)
        ? (row.flashcardKnownIds as string[])
        : [],
      flashcardReviewIds: Array.isArray(row.flashcardReviewIds)
        ? (row.flashcardReviewIds as string[])
        : [],
      updatedAt: row.updatedAt,
    };
  }

  public async getProgress(
    recordingId: string,
    userId: string,
  ): Promise<StudentLessonProgressEntity | null> {
    const row = await this.prisma.studentLessonProgress.findUnique({
      where: {
        recordingId_userId: {
          recordingId,
          userId,
        },
      },
    });
    if (!row) return null;
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      lastPositionSeconds: row.lastPositionSeconds,
      watchedSeconds: row.watchedSeconds,
      completedChapters: Array.isArray(row.completedChapters)
        ? (row.completedChapters as string[])
        : [],
      flashcardKnownIds: Array.isArray(row.flashcardKnownIds)
        ? (row.flashcardKnownIds as string[])
        : [],
      flashcardReviewIds: Array.isArray(row.flashcardReviewIds)
        ? (row.flashcardReviewIds as string[])
        : [],
      updatedAt: row.updatedAt,
    };
  }

  public async createBookmark(params: {
    recordingId: string;
    userId: string;
    timestampSeconds: number;
    label: string;
    chapterTitle?: string | null;
  }): Promise<StudentLessonBookmarkEntity> {
    const row = await this.prisma.studentLessonBookmark.create({
      data: {
        recordingId: params.recordingId,
        userId: params.userId,
        timestampSeconds: params.timestampSeconds,
        label: params.label,
        chapterTitle: params.chapterTitle ?? null,
      },
    });
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      timestampSeconds: row.timestampSeconds,
      label: row.label,
      chapterTitle: row.chapterTitle,
      createdAt: row.createdAt,
    };
  }

  public async listBookmarks(
    recordingId: string,
    userId: string,
  ): Promise<StudentLessonBookmarkEntity[]> {
    const rows = await this.prisma.studentLessonBookmark.findMany({
      where: { recordingId, userId },
      orderBy: { timestampSeconds: 'asc' },
    });
    return rows.map((row) => ({
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      timestampSeconds: row.timestampSeconds,
      label: row.label,
      chapterTitle: row.chapterTitle,
      createdAt: row.createdAt,
    }));
  }

  public async deleteBookmark(bookmarkId: string, userId: string): Promise<boolean> {
    const res = await this.prisma.studentLessonBookmark.deleteMany({
      where: { id: bookmarkId, userId },
    });
    return res.count > 0;
  }

  public async createNote(params: {
    recordingId: string;
    userId: string;
    timestampSeconds?: number | null;
    content: string;
    highlightText?: string | null;
    chapterTitle?: string | null;
  }): Promise<StudentLessonNoteEntity> {
    const row = await this.prisma.studentLessonNote.create({
      data: {
        recordingId: params.recordingId,
        userId: params.userId,
        timestampSeconds: params.timestampSeconds ?? null,
        content: params.content,
        highlightText: params.highlightText ?? null,
        chapterTitle: params.chapterTitle ?? null,
      },
    });
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      timestampSeconds: row.timestampSeconds,
      content: row.content,
      highlightText: row.highlightText,
      chapterTitle: row.chapterTitle,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  public async updateNote(
    noteId: string,
    userId: string,
    patch: { content?: string; highlightText?: string | null; timestampSeconds?: number | null },
  ): Promise<StudentLessonNoteEntity | null> {
    const existing = await this.prisma.studentLessonNote.findFirst({
      where: { id: noteId, userId },
    });
    if (!existing) return null;
    const row = await this.prisma.studentLessonNote.update({
      where: { id: noteId },
      data: {
        ...(patch.content !== undefined ? { content: patch.content } : {}),
        ...(patch.highlightText !== undefined ? { highlightText: patch.highlightText } : {}),
        ...(patch.timestampSeconds !== undefined
          ? { timestampSeconds: patch.timestampSeconds }
          : {}),
      },
    });
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      timestampSeconds: row.timestampSeconds,
      content: row.content,
      highlightText: row.highlightText,
      chapterTitle: row.chapterTitle,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  public async listNotes(
    recordingId: string,
    userId: string,
  ): Promise<StudentLessonNoteEntity[]> {
    const rows = await this.prisma.studentLessonNote.findMany({
      where: { recordingId, userId },
      orderBy: [{ timestampSeconds: 'asc' }, { createdAt: 'asc' }],
    });
    return rows.map((row) => ({
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      timestampSeconds: row.timestampSeconds,
      content: row.content,
      highlightText: row.highlightText,
      chapterTitle: row.chapterTitle,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    }));
  }

  public async deleteNote(noteId: string, userId: string): Promise<boolean> {
    const res = await this.prisma.studentLessonNote.deleteMany({
      where: { id: noteId, userId },
    });
    return res.count > 0;
  }

  public async createTutorConversation(params: {
    recordingId: string;
    userId: string;
    title: string;
  }): Promise<LessonTutorConversationEntity> {
    const row = await this.prisma.lessonTutorConversation.create({
      data: {
        recordingId: params.recordingId,
        userId: params.userId,
        title: params.title,
      },
    });
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      title: row.title,
      messages: [],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  public async listTutorConversations(
    recordingId: string,
    userId: string,
  ): Promise<LessonTutorConversationEntity[]> {
    const rows = await this.prisma.lessonTutorConversation.findMany({
      where: { recordingId, userId },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });
    return rows.map((row) => ({
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      title: row.title,
      messages: row.messages.map((m) => ({
        id: m.id,
        conversationId: m.conversationId,
        role: m.role as 'user' | 'assistant',
        content: m.content,
        citations: Array.isArray(m.citations) ? (m.citations as unknown as TutorSourceCitation[]) : [],
        modelUsed: m.modelUsed,
        createdAt: m.createdAt,
      })),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    }));
  }

  public async findTutorConversationById(
    conversationId: string,
    userId: string,
  ): Promise<LessonTutorConversationEntity | null> {
    const row = await this.prisma.lessonTutorConversation.findFirst({
      where: { id: conversationId, userId },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });
    if (!row) return null;
    return {
      id: row.id,
      recordingId: row.recordingId,
      userId: row.userId,
      title: row.title,
      messages: row.messages.map((m) => ({
        id: m.id,
        conversationId: m.conversationId,
        role: m.role as 'user' | 'assistant',
        content: m.content,
        citations: Array.isArray(m.citations) ? (m.citations as unknown as TutorSourceCitation[]) : [],
        modelUsed: m.modelUsed,
        createdAt: m.createdAt,
      })),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  public async appendTutorMessage(params: {
    conversationId: string;
    role: 'user' | 'assistant';
    content: string;
    citations?: TutorSourceCitation[];
    modelUsed?: string | null;
  }): Promise<LessonTutorMessageEntity> {
    const [msg] = await this.prisma.$transaction([
      this.prisma.lessonTutorMessage.create({
        data: {
          conversationId: params.conversationId,
          role: params.role,
          content: params.content,
          citations: (params.citations ?? []) as unknown as Prisma.InputJsonValue,
          modelUsed: params.modelUsed ?? null,
        },
      }),
      this.prisma.lessonTutorConversation.update({
        where: { id: params.conversationId },
        data: { updatedAt: new Date() },
      }),
    ]);

    return {
      id: msg.id,
      conversationId: msg.conversationId,
      role: msg.role as 'user' | 'assistant',
      content: msg.content,
      citations: Array.isArray(msg.citations)
        ? (msg.citations as unknown as TutorSourceCitation[])
        : [],
      modelUsed: msg.modelUsed,
      createdAt: msg.createdAt,
    };
  }
}
