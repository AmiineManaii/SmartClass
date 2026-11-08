import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { StorageAccessDeniedError } from '../../src/shared/errors/app-error.js';
import { LocalStorageAdapter } from '../../src/shared/storage/local-storage.adapter.js';
import { parseHttpRangeHeader } from '../../src/shared/storage/storage.port.js';
import {
  computeDeterministicLexicalVector,
  GpuTaskSemaphore,
  SmartModelRouterAdapter,
  type AiGatewayPort,
  type ChatCompletionInput,
  type ChatCompletionResult,
} from '../../src/modules/ai-assistant/index.js';
import {
  ApproveLessonPackageUseCase,
  AskLessonAiTutorUseCase,
  buildSrtFromSegments,
  buildVttFromSegments,
  computeFramePerceptualHash,
  GenerateStudentStudyArtifactUseCase,
  GetLessonReviewPackageUseCase,
  GetPublishedLessonWorkspaceUseCase,
  GetRecordingUseCase,
  hammingDistanceHex64,
  InMemoryLiveEventsHub,
  ManageStudentBookmarksUseCase,
  ManageStudentNotesUseCase,
  MediaProcessingWorker,
  PublishLessonPackageUseCase,
  RegenerateLessonSectionUseCase,
  ResolveRecordingMediaStreamUseCase,
  SearchLessonContentUseCase,
  StartRecordingUseCase,
  StopRecordingUseCase,
  SubmitStudentQuizAttemptUseCase,
  UnpublishLessonPackageUseCase,
  UpdateLessonReviewPackageUseCase,
  UpdateStudentProgressUseCase,
  type ClassAccessPort,
  type EgressServicePort,
  type LessonPackageEntity,
  type LessonPackageVersionEntity,
  type LessonTutorConversationEntity,
  type LessonTutorMessageEntity,
  type RecordingChapterEntity,
  type RecordingEntity,
  type RecordingProcessingJobEntity,
  type RecordingRepositoryPort,
  type RecordingSlideFrameEntity,
  type RecordingTranscriptEntity,
  type SessionChatRepositoryPort,
  type StudentLessonArtifactEntity,
  type StudentLessonBookmarkEntity,
  type StudentLessonNoteEntity,
  type StudentLessonProgressEntity,
  type StudentQuizAttemptEntity,
  type UpsertRecordingInput,
  type VideoSession,
  type VideoSessionRepositoryPort,
} from '../../src/modules/videoconference/index.js';

class InMemoryRecordingRepository implements RecordingRepositoryPort {
  private recordings = new Map<string, RecordingEntity>();
  private jobs = new Map<string, RecordingProcessingJobEntity>();
  private transcripts = new Map<string, RecordingTranscriptEntity>();
  private slides = new Map<string, RecordingSlideFrameEntity[]>();
  private chapters = new Map<string, RecordingChapterEntity[]>();
  private packages = new Map<string, LessonPackageEntity>();
  private versions = new Map<string, LessonPackageVersionEntity[]>();
  private artifacts = new Map<string, StudentLessonArtifactEntity>();
  private quizAttempts = new Map<string, StudentQuizAttemptEntity[]>();
  private progress = new Map<string, StudentLessonProgressEntity>();
  private bookmarks = new Map<string, StudentLessonBookmarkEntity>();
  private notes = new Map<string, StudentLessonNoteEntity>();
  private conversations = new Map<string, LessonTutorConversationEntity>();
  private seq = 1;

  private nextId(prefix: string): string {
    return `${prefix}_${this.seq++}`;
  }

  public async findBySessionId(sessionId: string): Promise<RecordingEntity | null> {
    for (const r of this.recordings.values()) {
      if (r.sessionId === sessionId) return r;
    }
    return null;
  }

  public async findById(recordingId: string): Promise<RecordingEntity | null> {
    return this.recordings.get(recordingId) ?? null;
  }

  public async findByEgressId(egressId: string): Promise<RecordingEntity | null> {
    for (const r of this.recordings.values()) {
      if (r.egressId === egressId) return r;
    }
    return null;
  }

  public async listByClassGroups(params: {
    classGroupIds?: string[];
    hostId?: string;
    status?: RecordingEntity['status'];
    publishedOnly?: boolean;
  }): Promise<RecordingEntity[]> {
    return Array.from(this.recordings.values()).filter((r) => {
      if (r.status === 'DELETED') return false;
      if (params.classGroupIds && !params.classGroupIds.includes(r.classGroupId)) return false;
      if (params.hostId && r.hostId !== params.hostId) return false;
      if (params.status && r.status !== params.status) return false;
      if (params.publishedOnly && r.status !== 'PUBLISHED') return false;
      return true;
    });
  }

  public async upsertBySessionId(input: UpsertRecordingInput): Promise<RecordingEntity> {
    const existing = await this.findBySessionId(input.sessionId);
    const now = new Date();
    const entity: RecordingEntity = {
      id: existing?.id ?? this.nextId('rec'),
      sessionId: input.sessionId,
      classGroupId: input.classGroupId,
      hostId: input.hostId,
      status: input.status,
      egressId: input.egressId !== undefined ? input.egressId : (existing?.egressId ?? null),
      storageKey:
        input.storageKey !== undefined ? input.storageKey : (existing?.storageKey ?? null),
      mimeType: input.mimeType ?? existing?.mimeType ?? 'video/mp4',
      sizeBytes: input.sizeBytes !== undefined ? input.sizeBytes : (existing?.sizeBytes ?? null),
      durationSeconds:
        input.durationSeconds !== undefined
          ? input.durationSeconds
          : (existing?.durationSeconds ?? null),
      width: input.width !== undefined ? input.width : (existing?.width ?? null),
      height: input.height !== undefined ? input.height : (existing?.height ?? null),
      thumbnailKey:
        input.thumbnailKey !== undefined ? input.thumbnailKey : (existing?.thumbnailKey ?? null),
      sourceDocKey:
        input.sourceDocKey !== undefined ? input.sourceDocKey : (existing?.sourceDocKey ?? null),
      sourceDocTitle:
        input.sourceDocTitle !== undefined
          ? input.sourceDocTitle
          : (existing?.sourceDocTitle ?? null),
      sourceDocText:
        input.sourceDocText !== undefined ? input.sourceDocText : (existing?.sourceDocText ?? null),
      errorCode: input.errorCode !== undefined ? input.errorCode : (existing?.errorCode ?? null),
      errorMessage:
        input.errorMessage !== undefined ? input.errorMessage : (existing?.errorMessage ?? null),
      startedAt: input.startedAt !== undefined ? input.startedAt : (existing?.startedAt ?? null),
      stoppedAt: input.stoppedAt !== undefined ? input.stoppedAt : (existing?.stoppedAt ?? null),
      publishedAt:
        input.publishedAt !== undefined ? input.publishedAt : (existing?.publishedAt ?? null),
      processingVersion: input.processingVersion ?? existing?.processingVersion ?? 1,
      aiModelUsed:
        input.aiModelUsed !== undefined ? input.aiModelUsed : (existing?.aiModelUsed ?? null),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    };
    this.recordings.set(entity.id, entity);
    return entity;
  }

  public async updateRecording(
    recordingId: string,
    patch: Partial<Omit<UpsertRecordingInput, 'sessionId' | 'classGroupId'>>,
  ): Promise<RecordingEntity> {
    const existing = this.recordings.get(recordingId);
    if (!existing) throw new Error('Recording not found');
    const updated: RecordingEntity = {
      ...existing,
      ...(patch.status !== undefined ? { status: patch.status } : {}),
      ...(patch.egressId !== undefined ? { egressId: patch.egressId } : {}),
      ...(patch.storageKey !== undefined ? { storageKey: patch.storageKey } : {}),
      ...(patch.sizeBytes !== undefined ? { sizeBytes: patch.sizeBytes } : {}),
      ...(patch.durationSeconds !== undefined ? { durationSeconds: patch.durationSeconds } : {}),
      ...(patch.width !== undefined ? { width: patch.width } : {}),
      ...(patch.height !== undefined ? { height: patch.height } : {}),
      ...(patch.thumbnailKey !== undefined ? { thumbnailKey: patch.thumbnailKey } : {}),
      ...(patch.sourceDocKey !== undefined ? { sourceDocKey: patch.sourceDocKey } : {}),
      ...(patch.sourceDocTitle !== undefined ? { sourceDocTitle: patch.sourceDocTitle } : {}),
      ...(patch.sourceDocText !== undefined ? { sourceDocText: patch.sourceDocText } : {}),
      ...(patch.errorCode !== undefined ? { errorCode: patch.errorCode } : {}),
      ...(patch.errorMessage !== undefined ? { errorMessage: patch.errorMessage } : {}),
      ...(patch.startedAt !== undefined ? { startedAt: patch.startedAt } : {}),
      ...(patch.stoppedAt !== undefined ? { stoppedAt: patch.stoppedAt } : {}),
      ...(patch.publishedAt !== undefined ? { publishedAt: patch.publishedAt } : {}),
      ...(patch.processingVersion !== undefined
        ? { processingVersion: patch.processingVersion }
        : {}),
      ...(patch.aiModelUsed !== undefined ? { aiModelUsed: patch.aiModelUsed } : {}),
      updatedAt: new Date(),
    };
    this.recordings.set(recordingId, updated);
    return updated;
  }

  public async createProcessingJob(recordingId: string): Promise<RecordingProcessingJobEntity> {
    const now = new Date();
    const job: RecordingProcessingJobEntity = {
      id: this.nextId('job'),
      recordingId,
      status: 'QUEUED',
      stage: 'VALIDATION',
      progress: 0,
      attempts: 0,
      maxAttempts: 3,
      lockedAt: null,
      workerId: null,
      errorMessage: null,
      stageLogs: [],
      startedAt: null,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    };
    this.jobs.set(job.id, job);
    return job;
  }

  public async findLatestJobByRecordingId(
    recordingId: string,
  ): Promise<RecordingProcessingJobEntity | null> {
    const all = await this.listJobsByRecordingId(recordingId);
    return all[0] ?? null;
  }

  public async listJobsByRecordingId(recordingId: string): Promise<RecordingProcessingJobEntity[]> {
    return Array.from(this.jobs.values())
      .filter((j) => j.recordingId === recordingId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }

  public async updateProcessingJob(
    jobId: string,
    patch: Partial<RecordingProcessingJobEntity>,
  ): Promise<RecordingProcessingJobEntity> {
    const existing = this.jobs.get(jobId);
    if (!existing) throw new Error('Job not found');
    const updated: RecordingProcessingJobEntity = {
      ...existing,
      ...patch,
      updatedAt: new Date(),
    };
    this.jobs.set(jobId, updated);
    return updated;
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
    const transcriptId = this.nextId('tr');
    const now = new Date();
    const entity: RecordingTranscriptEntity = {
      id: transcriptId,
      recordingId: params.recordingId,
      language: params.language,
      fullText: params.fullText,
      vttContent: params.vttContent,
      srtContent: params.srtContent,
      qualityScore: params.qualityScore,
      modelUsed: params.modelUsed,
      updatedById: params.updatedById ?? null,
      segments: params.segments.map((s) => ({
        id: this.nextId('seg'),
        transcriptId,
        recordingId: params.recordingId,
        orderIndex: s.orderIndex,
        startSeconds: s.startSeconds,
        endSeconds: s.endSeconds,
        text: s.text,
        speaker: s.speaker ?? 'Enseignant',
        confidence: s.confidence ?? 0.95,
      })),
      createdAt: now,
      updatedAt: now,
    };
    this.transcripts.set(params.recordingId, entity);
    return entity;
  }

  public async getTranscript(recordingId: string): Promise<RecordingTranscriptEntity | null> {
    return this.transcripts.get(recordingId) ?? null;
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
    const list: RecordingSlideFrameEntity[] = frames.map((f) => ({
      id: this.nextId('slide'),
      recordingId,
      ...f,
      createdAt: new Date(),
    }));
    this.slides.set(recordingId, list);
    return list;
  }

  public async listSlideFrames(recordingId: string): Promise<RecordingSlideFrameEntity[]> {
    return this.slides.get(recordingId) ?? [];
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
    const list: RecordingChapterEntity[] = chapters.map((c) => ({
      id: this.nextId('ch'),
      recordingId,
      orderIndex: c.orderIndex,
      title: c.title,
      summary: c.summary,
      startSeconds: c.startSeconds,
      endSeconds: c.endSeconds,
      keyConcepts: c.keyConcepts,
      slideFrameId: c.slideFrameId ?? null,
      sourcePage: c.sourcePage ?? null,
    }));
    this.chapters.set(recordingId, list);
    return list;
  }

  public async updateChapter(
    chapterId: string,
    patch: Partial<RecordingChapterEntity>,
  ): Promise<RecordingChapterEntity | null> {
    for (const [recId, list] of this.chapters.entries()) {
      const idx = list.findIndex((c) => c.id === chapterId);
      if (idx !== -1) {
        const updated = { ...list[idx]!, ...patch };
        list[idx] = updated;
        this.chapters.set(recId, list);
        return updated;
      }
    }
    return null;
  }

  public async listChapters(recordingId: string): Promise<RecordingChapterEntity[]> {
    return this.chapters.get(recordingId) ?? [];
  }

  public async saveLessonPackage(
    recordingId: string,
    data: Omit<LessonPackageEntity, 'id' | 'recordingId' | 'createdAt' | 'updatedAt'>,
    versionMeta?: { editedById?: string | null; changeSummary?: string },
  ): Promise<LessonPackageEntity> {
    const existing = this.packages.get(recordingId);
    const now = new Date();
    const pkg: LessonPackageEntity = {
      id: existing?.id ?? this.nextId('pkg'),
      recordingId,
      ...data,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    };
    this.packages.set(recordingId, pkg);

    const verList = this.versions.get(pkg.id) ?? [];
    verList.unshift({
      id: this.nextId('ver'),
      lessonPackageId: pkg.id,
      version: pkg.version,
      snapshot: { generalSummary: pkg.generalSummary, structuredNotes: pkg.structuredNotes },
      editedById: versionMeta?.editedById ?? null,
      changeSummary: versionMeta?.changeSummary ?? `v${pkg.version}`,
      createdAt: now,
    });
    this.versions.set(pkg.id, verList);
    return pkg;
  }

  public async getLessonPackage(recordingId: string): Promise<LessonPackageEntity | null> {
    return this.packages.get(recordingId) ?? null;
  }

  public async listLessonPackageVersions(
    lessonPackageId: string,
  ): Promise<LessonPackageVersionEntity[]> {
    return this.versions.get(lessonPackageId) ?? [];
  }

  public async createStudyArtifact(params: {
    recordingId: string;
    userId: string;
    kind: StudentLessonArtifactEntity['kind'];
    title: string;
    language: string;
    chapterIds: string[];
    config: Record<string, unknown>;
    content: Record<string, unknown>;
    modelUsed: string | null;
  }): Promise<StudentLessonArtifactEntity> {
    const now = new Date();
    const art: StudentLessonArtifactEntity = {
      id: this.nextId('art'),
      ...params,
      createdAt: now,
      updatedAt: now,
    };
    this.artifacts.set(art.id, art);
    return art;
  }

  public async listStudyArtifacts(
    recordingId: string,
    userId: string,
    kind?: StudentLessonArtifactEntity['kind'],
  ): Promise<StudentLessonArtifactEntity[]> {
    return Array.from(this.artifacts.values()).filter(
      (a) => a.recordingId === recordingId && a.userId === userId && (!kind || a.kind === kind),
    );
  }

  public async findStudyArtifactById(
    artifactId: string,
  ): Promise<StudentLessonArtifactEntity | null> {
    return this.artifacts.get(artifactId) ?? null;
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
    const attempt: StudentQuizAttemptEntity = {
      id: this.nextId('attempt'),
      ...params,
      completedAt: new Date(),
    };
    const key = `${params.recordingId}:${params.userId}`;
    const list = this.quizAttempts.get(key) ?? [];
    list.unshift(attempt);
    this.quizAttempts.set(key, list);
    return attempt;
  }

  public async listQuizAttempts(
    recordingId: string,
    userId: string,
  ): Promise<StudentQuizAttemptEntity[]> {
    return this.quizAttempts.get(`${recordingId}:${userId}`) ?? [];
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
    const key = `${params.recordingId}:${params.userId}`;
    const existing = this.progress.get(key);
    const updated: StudentLessonProgressEntity = {
      id: existing?.id ?? this.nextId('prog'),
      recordingId: params.recordingId,
      userId: params.userId,
      lastPositionSeconds: params.lastPositionSeconds ?? existing?.lastPositionSeconds ?? 0,
      watchedSeconds: params.watchedSeconds ?? existing?.watchedSeconds ?? 0,
      completedChapters: params.completedChapters ?? existing?.completedChapters ?? [],
      flashcardKnownIds: params.flashcardKnownIds ?? existing?.flashcardKnownIds ?? [],
      flashcardReviewIds: params.flashcardReviewIds ?? existing?.flashcardReviewIds ?? [],
      updatedAt: new Date(),
    };
    this.progress.set(key, updated);
    return updated;
  }

  public async getProgress(
    recordingId: string,
    userId: string,
  ): Promise<StudentLessonProgressEntity | null> {
    return this.progress.get(`${recordingId}:${userId}`) ?? null;
  }

  public async createBookmark(params: {
    recordingId: string;
    userId: string;
    timestampSeconds: number;
    label: string;
    chapterTitle?: string | null;
  }): Promise<StudentLessonBookmarkEntity> {
    const bm: StudentLessonBookmarkEntity = {
      id: this.nextId('bm'),
      recordingId: params.recordingId,
      userId: params.userId,
      timestampSeconds: params.timestampSeconds,
      label: params.label,
      chapterTitle: params.chapterTitle ?? null,
      createdAt: new Date(),
    };
    this.bookmarks.set(bm.id, bm);
    return bm;
  }

  public async listBookmarks(
    recordingId: string,
    userId: string,
  ): Promise<StudentLessonBookmarkEntity[]> {
    return Array.from(this.bookmarks.values()).filter(
      (b) => b.recordingId === recordingId && b.userId === userId,
    );
  }

  public async deleteBookmark(bookmarkId: string, userId: string): Promise<boolean> {
    const existing = this.bookmarks.get(bookmarkId);
    if (!existing || existing.userId !== userId) return false;
    this.bookmarks.delete(bookmarkId);
    return true;
  }

  public async createNote(params: {
    recordingId: string;
    userId: string;
    timestampSeconds?: number | null;
    content: string;
    highlightText?: string | null;
    chapterTitle?: string | null;
  }): Promise<StudentLessonNoteEntity> {
    const now = new Date();
    const note: StudentLessonNoteEntity = {
      id: this.nextId('note'),
      recordingId: params.recordingId,
      userId: params.userId,
      timestampSeconds: params.timestampSeconds ?? null,
      content: params.content,
      highlightText: params.highlightText ?? null,
      chapterTitle: params.chapterTitle ?? null,
      createdAt: now,
      updatedAt: now,
    };
    this.notes.set(note.id, note);
    return note;
  }

  public async updateNote(
    noteId: string,
    userId: string,
    patch: { content?: string; highlightText?: string | null; timestampSeconds?: number | null },
  ): Promise<StudentLessonNoteEntity | null> {
    const existing = this.notes.get(noteId);
    if (!existing || existing.userId !== userId) return null;
    const updated: StudentLessonNoteEntity = {
      ...existing,
      ...(patch.content !== undefined ? { content: patch.content } : {}),
      ...(patch.highlightText !== undefined ? { highlightText: patch.highlightText } : {}),
      ...(patch.timestampSeconds !== undefined ? { timestampSeconds: patch.timestampSeconds } : {}),
      updatedAt: new Date(),
    };
    this.notes.set(noteId, updated);
    return updated;
  }

  public async listNotes(
    recordingId: string,
    userId: string,
  ): Promise<StudentLessonNoteEntity[]> {
    return Array.from(this.notes.values()).filter(
      (n) => n.recordingId === recordingId && n.userId === userId,
    );
  }

  public async deleteNote(noteId: string, userId: string): Promise<boolean> {
    const existing = this.notes.get(noteId);
    if (!existing || existing.userId !== userId) return false;
    this.notes.delete(noteId);
    return true;
  }

  public async createTutorConversation(params: {
    recordingId: string;
    userId: string;
    title: string;
  }): Promise<LessonTutorConversationEntity> {
    const now = new Date();
    const conv: LessonTutorConversationEntity = {
      id: this.nextId('conv'),
      ...params,
      messages: [],
      createdAt: now,
      updatedAt: now,
    };
    this.conversations.set(conv.id, conv);
    return conv;
  }

  public async listTutorConversations(
    recordingId: string,
    userId: string,
  ): Promise<LessonTutorConversationEntity[]> {
    return Array.from(this.conversations.values()).filter(
      (c) => c.recordingId === recordingId && c.userId === userId,
    );
  }

  public async findTutorConversationById(
    conversationId: string,
    userId: string,
  ): Promise<LessonTutorConversationEntity | null> {
    const conv = this.conversations.get(conversationId);
    if (!conv || conv.userId !== userId) return null;
    return conv;
  }

  public async appendTutorMessage(params: {
    conversationId: string;
    role: 'user' | 'assistant';
    content: string;
    citations?: LessonTutorMessageEntity['citations'];
    modelUsed?: string | null;
  }): Promise<LessonTutorMessageEntity> {
    const conv = this.conversations.get(params.conversationId);
    if (!conv) throw new Error('Conversation not found');
    const msg: LessonTutorMessageEntity = {
      id: this.nextId('msg'),
      conversationId: params.conversationId,
      role: params.role,
      content: params.content,
      citations: params.citations ?? [],
      modelUsed: params.modelUsed ?? null,
      createdAt: new Date(),
    };
    conv.messages.push(msg);
    conv.updatedAt = new Date();
    return msg;
  }
}

describe('SmartClass Lecture Recording, 7-Stage AI Pipeline, Review Studio & Student Learning Ecosystem', () => {
  let tempRoot: string;
  let storage: LocalStorageAdapter;

  beforeEach(async () => {
    tempRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'smartclass-storage-test-'));
    storage = new LocalStorageAdapter(tempRoot);
  });

  afterEach(async () => {
    await fs.rm(tempRoot, { recursive: true, force: true });
  });

  describe('1. LocalStorageAdapter & HTTP Range Streaming', () => {
    it('prevents path traversal, drive letters, null bytes, and backslashes', () => {
      expect(() => storage.resolveSafeKey('../secret.env')).toThrow(StorageAccessDeniedError);
      expect(() => storage.resolveSafeKey('recordings/../../etc/passwd')).toThrow(
        StorageAccessDeniedError,
      );
      expect(() => storage.resolveSafeKey('C:/Windows/System32/cmd.exe')).toThrow(
        StorageAccessDeniedError,
      );
      expect(() => storage.resolveSafeKey('recordings\\session\\file.mp4')).toThrow(
        StorageAccessDeniedError,
      );
      expect(() => storage.resolveSafeKey('recordings/file\0.mp4')).toThrow(
        StorageAccessDeniedError,
      );
    });

    it('writes, stats, streams byte ranges (HTTP 206), and deletes media files cleanly', async () => {
      const payload = Buffer.from('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'utf8');
      const key = 'recordings/session-1/lecture.mp4';
      const stat = await storage.putBuffer(key, payload);
      expect(stat.sizeBytes).toBe(36);
      expect(stat.mimeType).toBe('video/mp4');

      const range = parseHttpRangeHeader('bytes=10-19', stat.sizeBytes);
      expect(range).toEqual({ start: 10, end: 19 });

      const stream = await storage.createReadStream(key, range!);
      const chunks: Buffer[] = [];
      for await (const chunk of stream) {
        chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
      }
      expect(Buffer.concat(chunks).toString('utf8')).toBe('ABCDEFGHIJ');

      // Invalid out-of-bounds range returns null (HTTP 416)
      expect(parseHttpRangeHeader('bytes=50-60', stat.sizeBytes)).toBeNull();

      await storage.delete(key);
      expect(await storage.exists(key)).toBe(false);
    });
  });

  describe('2. Two-Model SmartModelRouter, Fallback & GPU Concurrency Semaphore', () => {
    it('serializes concurrent GPU tasks via GpuTaskSemaphore', async () => {
      const semaphore = new GpuTaskSemaphore(1);
      const order: number[] = [];

      await Promise.all([
        semaphore.runExclusive(async () => {
          order.push(1);
          await new Promise((r) => setTimeout(r, 20));
          order.push(2);
        }),
        semaphore.runExclusive(async () => {
          order.push(3);
        }),
      ]);

      expect(order).toEqual([1, 2, 3]);
    });

    it('routes roles across primary (gemma4:e4b) and secondary (Qwen3.5-4B) models and falls back on failure', async () => {
      const invokedModels: string[] = [];
      const router = new SmartModelRouterAdapter(
        (model: string): AiGatewayPort => ({
          async chatCompletion(input: ChatCompletionInput): Promise<ChatCompletionResult> {
            invokedModels.push(model);
            if (model === 'gemma4:e4b' && input.user.includes('FORCE_PRIMARY_FAILURE')) {
              throw new Error('Simulated primary VRAM spike');
            }
            return {
              content: `Réponse générée par ${model}`,
              model,
              promptTokens: 20,
              completionTokens: 15,
              toolsUsed: false,
            };
          },
          async streamCompletion() {
            return { model, promptTokens: 10, completionTokens: 10 };
          },
          async checkHealth() {
            return { available: true, model, latencyMs: 12 };
          },
        }),
        {
          primaryModel: 'gemma4:e4b',
          fallbackModel: 'hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1',
          maxConcurrentGpu: 1,
        },
      );

      // Fast role routes to secondary model first
      const fastRes = await router.generateForRole('QUIZ_FLASHCARDS', {
        systemPrompt: 'System',
        messages: [{ role: 'user', content: 'Generate quiz' }],
      });
      expect(fastRes.modelUsed).toBe('hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1');
      expect(fastRes.fallbackUsed).toBe(false);

      // Deep reasoning role routes to primary, and falls back to secondary on failure
      const fallbackRes = await router.generateForRole('LESSON_PACKAGE_GENERATION', {
        systemPrompt: 'System',
        messages: [{ role: 'user', content: 'FORCE_PRIMARY_FAILURE' }],
      });
      expect(fallbackRes.modelUsed).toBe('hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1');
      expect(fallbackRes.fallbackUsed).toBe(true);
    });

    it('computes L2-normalized 768-dim lexical vectors and valid VTT/SRT subtitles', () => {
      const vec = computeDeterministicLexicalVector('Algèbre linéaire et valeurs propres');
      expect(vec).toHaveLength(768);
      const norm = Math.sqrt(vec.reduce((acc, v) => acc + v * v, 0));
      expect(norm).toBeCloseTo(1.0, 3);

      const vtt = buildVttFromSegments([
        { startSeconds: 0, endSeconds: 12.5, text: 'Bienvenue au cours.' },
      ]);
      const srt = buildSrtFromSegments([
        { startSeconds: 0, endSeconds: 12.5, text: 'Bienvenue au cours.' },
      ]);
      expect(vtt).toContain('WEBVTT');
      expect(vtt).toContain('00:00:00.000 --> 00:00:12.500');
      expect(srt).toContain('00:00:00,000 --> 00:00:12,500');

      const hashA = computeFramePerceptualHash(Buffer.from('slide-content-1'));
      const hashB = computeFramePerceptualHash(Buffer.from('slide-content-1'));
      expect(hammingDistanceHex64(hashA, hashB)).toBe(0);
    });
  });

  describe('3. End-to-End Recording, 7-Stage Pipeline, Teacher Review Studio & Student Learning Workspace', () => {
    it('executes the complete teacher -> AI pipeline -> review/publish -> student replay, quiz & AI Tutor workflow', async () => {
      const sessionId = '550e8400-e29b-41d4-a716-446655440000';
      const classGroupId = '550e8400-e29b-41d4-a716-446655440010';
      const teacherUser = { id: 'teacher-1', role: 'TEACHER' as const };
      const studentUser = { id: 'student-1', role: 'STUDENT' as const };

      const liveSession: VideoSession = {
        id: sessionId,
        classGroupId,
        hostId: teacherUser.id,
        hostName: 'Prof. Amine Manai',
        subject: 'Architecture Logicielle & IA',
        title: 'Systèmes Distribués et Consensus Raft',
        description: 'Étude approfondie de l’élection de leader et de la réplication de journal.',
        startsAt: new Date(Date.now() - 1800_000),
        endsAt: new Date(Date.now() + 1800_000),
        startedAt: new Date(Date.now() - 1200_000),
        endedAt: null,
        status: 'IN_PROGRESS',
        roomName: `room-${sessionId}`,
        joinOpensMinutesBefore: 10,
        chatEnabled: true,
        timetableSlotId: null,
        courseId: null,
        cancelReason: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const sessionRepository: VideoSessionRepositoryPort = {
        create: async (s) => s,
        findById: async (id) => (id === sessionId ? liveSession : null),
        findByRoomName: async () => liveSession,
        update: async () => liveSession,
        updateStatusAtomic: async () => liveSession,
        list: async () => ({ items: [liveSession], total: 1 }),
        findOverlappingForClass: async () => [],
        findNextForClasses: async () => ({ liveSession, upcomingSession: null }),
      };

      const classAccessPort: ClassAccessPort = {
        getClassAccess: async (userId) => ({
          isMember: userId === studentUser.id || userId === teacherUser.id,
          isTeacherAssigned: userId === teacherUser.id,
          isReferent: userId === teacherUser.id,
          isApprovedTeacher: userId === teacherUser.id,
        }),
        getUserClassGroupIds: async () => [classGroupId],
        getClassMemberUserIds: async () => [teacherUser.id, studentUser.id],
      };

      const chatRepository: SessionChatRepositoryPort = {
        createMessage: async (m) => ({ ...m, id: 'msg-1', createdAt: new Date() }),
        findByClientMessageId: async () => null,
        listBySession: async () => ({
          items: [
            {
              id: 'chat-1',
              sessionId,
              senderId: studentUser.id,
              senderDisplayName: 'Salma Étudiante',
              senderRole: 'STUDENT',
              content: 'Que se passe-t-il en cas de partition réseau pendant l’élection Raft ?',
              clientMessageId: 'cid-1',
              createdAt: new Date(),
            },
          ],
          total: 1,
        }),
      };

      const egressService: EgressServicePort = {
        startRoomRecording: async () => ({
          egressId: 'egress_local_test_1',
          mode: 'local-composite',
        }),
        stopRoomRecording: async ({ storageKey }) => {
          const fakeMp4 = Buffer.from(
            '00000018667479706d703432000000006d70343269736f6d000000086d646174',
            'hex',
          );
          await storage.putBuffer(storageKey, fakeMp4);
          await storage.putBuffer(
            `recordings/${sessionId}/subtitles/live_capture.json`,
            Buffer.from(
              JSON.stringify({
                spokenTranscript:
                  "Bienvenue au cours d'informatique. Nous abordons aujourd'hui l'architecture et les algorithmes.",
                detectedLanguage: 'fr',
                capturedSegments: [
                  {
                    startSeconds: 0,
                    endSeconds: 15,
                    text: 'Introduction et objectifs du cours en informatique et science des données.',
                  },
                  {
                    startSeconds: 15,
                    endSeconds: 30,
                    text: 'Définition rigoureuse des concepts fondamentaux et analyse de la complexité.',
                  },
                  {
                    startSeconds: 30,
                    endSeconds: 45,
                    text: 'Démonstration pratique avec implémentation concrète et étude de cas.',
                  },
                  {
                    startSeconds: 45,
                    endSeconds: 60,
                    text: 'Synthèse générale, questions réponses et points essentiels pour les examens.',
                  },
                ],
              }),
            ),
          );
          return {
            egressId: 'egress_local_test_1',
            sizeBytes: fakeMp4.length,
            durationSeconds: 180,
          };
        },
      };

      const modelRouter = new SmartModelRouterAdapter(
        (model: string): AiGatewayPort => ({
          async chatCompletion(): Promise<ChatCompletionResult> {
            return {
              content: '',
              model,
              promptTokens: 50,
              completionTokens: 100,
              toolsUsed: false,
            };
          },
          async streamCompletion() {
            return { model, promptTokens: 10, completionTokens: 20 };
          },
          async checkHealth() {
            return { available: true, model, latencyMs: 10 };
          },
        }),
      );

      const recordingRepository = new InMemoryRecordingRepository();
      const liveEventsHub = new InMemoryLiveEventsHub(classAccessPort);
      const mediaWorker = new MediaProcessingWorker({
        recordingRepository,
        sessionRepository,
        chatRepository,
        storage,
        modelRouter,
        liveEventsPublisher: liveEventsHub,
      });

      const startRecording = new StartRecordingUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
        egressService,
        undefined,
        liveEventsHub,
      );
      const stopRecording = new StopRecordingUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
        egressService,
        mediaWorker,
        undefined,
        liveEventsHub,
      );

      // Step 1: Student cannot start recording
      await expect(startRecording.execute(studentUser, sessionId)).rejects.toThrow();

      // Step 2: Teacher starts recording (and idempotent second call returns same active recording)
      const started = await startRecording.execute(teacherUser, sessionId);
      expect(started.status).toBe('RECORDING');
      const startedAgain = await startRecording.execute(teacherUser, sessionId);
      expect(startedAgain.id).toBe(started.id);

      // Step 3: Teacher stops recording and awaits 7-stage AI processing pipeline
      const processed = await stopRecording.execute(teacherUser, sessionId, {
        awaitProcessing: true,
      });
      expect(processed.status).toBe('READY_FOR_REVIEW');
      expect(processed.latestJob?.status).toBe('SUCCEEDED');
      expect(processed.latestJob?.progress).toBe(100);

      // Step 4: Student cannot access unpublished workspace or stream video yet
      const getStudentWorkspace = new GetPublishedLessonWorkspaceUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const resolveStream = new ResolveRecordingMediaStreamUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      await expect(getStudentWorkspace.execute(studentUser, sessionId)).rejects.toThrow();
      await expect(resolveStream.execute(studentUser, sessionId, 'video')).rejects.toThrow();

      // Step 5: Teacher inspects Review Studio, edits summary & transcript, regenerates quiz, approves & publishes
      const getReview = new GetLessonReviewPackageUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
        modelRouter,
      );
      const reviewInitial = await getReview.execute(teacherUser, sessionId);
      expect(reviewInitial.chapters).toHaveLength(4);
      expect(reviewInitial.transcript?.segments.length).toBeGreaterThanOrEqual(4);
      expect(reviewInitial.lessonPackage?.mindMapMermaid).toContain('flowchart TD');
      expect(reviewInitial.lessonPackage?.mindMapMermaid).not.toContain('mindmap');

      const updateReview = new UpdateLessonReviewPackageUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
        storage,
        modelRouter,
      );
      const updatedReview = await updateReview.execute(teacherUser, sessionId, {
        changeSummary: 'Précision sur le quorum Raft',
        generalSummary:
          'Résumé validé par le Prof. Amine Manai : Le consensus Raft repose sur un leader unique et un quorum majoritaire.',
      });
      expect(updatedReview.lessonPackage?.version).toBe(2);
      expect(updatedReview.versions).toHaveLength(2);

      const regenerateSection = new RegenerateLessonSectionUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
        modelRouter,
      );
      const afterRegen = await regenerateSection.execute(teacherUser, sessionId, {
        section: 'quiz',
        instructions: 'Ajouter une question sur le split-vote',
      });
      expect(afterRegen.lessonPackage?.quizzes.length).toBeGreaterThan(
        reviewInitial.lessonPackage!.quizzes.length,
      );

      const approveUseCase = new ApproveLessonPackageUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const approved = await approveUseCase.execute(teacherUser, sessionId);
      expect(approved.status).toBe('APPROVED');

      const publishUseCase = new PublishLessonPackageUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
        undefined,
        liveEventsHub,
      );
      const published = await publishUseCase.execute(teacherUser, sessionId);
      expect(published.status).toBe('PUBLISHED');
      expect(published.publishedAt).toBeTruthy();

      // Step 6: Student accesses published workspace, searches content, saves progress/bookmarks/notes
      const workspace = await getStudentWorkspace.execute(studentUser, sessionId);
      expect(workspace.recording.status).toBe('PUBLISHED');
      expect(workspace.chapters).toHaveLength(4);
      expect(workspace.lessonPackage?.flashcards.length).toBeGreaterThanOrEqual(4);

      const searchUseCase = new SearchLessonContentUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const searchHits = await searchUseCase.execute(studentUser, sessionId, 'Raft');
      expect(searchHits.length).toBeGreaterThan(0);
      expect(searchHits[0]?.formattedTimestamp).toMatch(/^\d{2}:\d{2}/);

      const progressUseCase = new UpdateStudentProgressUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const prog = await progressUseCase.execute(studentUser, sessionId, {
        lastPositionSeconds: 75,
        watchedSeconds: 90,
        completedChapters: [workspace.chapters[0]!.id],
      });
      expect(prog.lastPositionSeconds).toBe(75);

      const bookmarksUseCase = new ManageStudentBookmarksUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const bm = await bookmarksUseCase.create(studentUser, sessionId, {
        timestampSeconds: 60,
        label: 'Démonstration élection leader',
      });
      expect(bm.timestampSeconds).toBe(60);

      const notesUseCase = new ManageStudentNotesUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const note = await notesUseCase.create(studentUser, sessionId, {
        timestampSeconds: 60,
        content: 'Important : un candidat doit avoir un journal au moins aussi à jour que la majorité.',
      });
      expect(note.content).toContain('majorité');

      // Step 7: Student generates personalized Summary, Quiz & Flashcards, and submits a Quiz Attempt
      const generateArtifact = new GenerateStudentStudyArtifactUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
        modelRouter,
      );
      const examSummary = await generateArtifact.execute(studentUser, sessionId, {
        kind: 'SUMMARY',
        summaryMode: 'exam',
      });
      expect(examSummary.kind).toBe('SUMMARY');
      expect(String(examSummary.content.markdown)).toContain('Systèmes Distribués');

      const customQuiz = await generateArtifact.execute(studentUser, sessionId, {
        kind: 'QUIZ',
        difficulty: 'moyen',
        questionCount: 4,
      });
      expect(customQuiz.kind).toBe('QUIZ');

      const customFlashcards = await generateArtifact.execute(studentUser, sessionId, {
        kind: 'FLASHCARDS',
        flashcardCount: 5,
      });
      expect(customFlashcards.kind).toBe('FLASHCARDS');

      const submitQuiz = new SubmitStudentQuizAttemptUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const quizQuestions = workspace.lessonPackage!.quizzes;
      const attempt = await submitQuiz.execute(studentUser, sessionId, {
        artifactId: 'teacher_default',
        answers: [
          { questionId: quizQuestions[0]!.id, answer: quizQuestions[0]!.correctAnswer },
          { questionId: quizQuestions[1]!.id, answer: 'Mauvaise réponse' },
        ],
      });
      expect(attempt.totalQuestions).toBe(quizQuestions.length);
      expect(attempt.weakTopics.length).toBeGreaterThan(0);

      // Step 8: Student interacts with the Source-Grounded Lesson AI Tutor
      const askTutor = new AskLessonAiTutorUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
        modelRouter,
      );
      const tutorTurn = await askTutor.execute(studentUser, sessionId, {
        question: 'Peux-tu m’expliquer ce que l’enseignant démontre à 01:00 sur Raft ?',
        currentTimestampSeconds: 60,
        responseStyle: 'step-by-step',
      });
      expect(tutorTurn.assistantMessage.content).toContain('Systèmes Distribués');
      expect(tutorTurn.assistantMessage.citations.length).toBeGreaterThan(0);
      expect(tutorTurn.assistantMessage.citations[0]?.timestampSeconds).toBeTypeOf('number');

      // Step 9: Unpublish and verify GetRecordingUseCase
      const unpublish = new UnpublishLessonPackageUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const unpublished = await unpublish.execute(teacherUser, sessionId);
      expect(unpublished.status).toBe('READY_FOR_REVIEW');

      const getRec = new GetRecordingUseCase(
        sessionRepository,
        recordingRepository,
        classAccessPort,
      );
      const recOverview = await getRec.execute(teacherUser, sessionId);
      expect(recOverview.id).toBe(started.id);
    });
  });
});

