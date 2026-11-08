import type {
  LessonPackageEntity,
  LessonPackageVersionEntity,
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
} from './recording.entity.js';

export interface UpsertRecordingInput {
  sessionId: string;
  classGroupId: string;
  hostId: string | null;
  status: RecordingStatus;
  egressId?: string | null;
  storageKey?: string | null;
  mimeType?: string;
  sizeBytes?: number | null;
  durationSeconds?: number | null;
  width?: number | null;
  height?: number | null;
  thumbnailKey?: string | null;
  sourceDocKey?: string | null;
  sourceDocTitle?: string | null;
  sourceDocText?: string | null;
  errorCode?: string | null;
  errorMessage?: string | null;
  startedAt?: Date | null;
  stoppedAt?: Date | null;
  publishedAt?: Date | null;
  processingVersion?: number;
  aiModelUsed?: string | null;
}

export interface RecordingRepositoryPort {
  findBySessionId(sessionId: string): Promise<RecordingEntity | null>;
  findById(recordingId: string): Promise<RecordingEntity | null>;
  findByEgressId(egressId: string): Promise<RecordingEntity | null>;
  listByClassGroups(params: {
    classGroupIds?: string[];
    hostId?: string;
    status?: RecordingStatus;
    publishedOnly?: boolean;
  }): Promise<RecordingEntity[]>;
  upsertBySessionId(input: UpsertRecordingInput): Promise<RecordingEntity>;
  updateRecording(
    recordingId: string,
    patch: Partial<Omit<UpsertRecordingInput, 'sessionId' | 'classGroupId'>>,
  ): Promise<RecordingEntity>;

  // Processing jobs
  createProcessingJob(recordingId: string): Promise<RecordingProcessingJobEntity>;
  findLatestJobByRecordingId(recordingId: string): Promise<RecordingProcessingJobEntity | null>;
  listJobsByRecordingId(recordingId: string): Promise<RecordingProcessingJobEntity[]>;
  updateProcessingJob(
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
  ): Promise<RecordingProcessingJobEntity>;

  // Transcript & segments
  saveTranscript(params: {
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
  }): Promise<RecordingTranscriptEntity>;
  getTranscript(recordingId: string): Promise<RecordingTranscriptEntity | null>;

  // Slide frames
  replaceSlideFrames(
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
  ): Promise<RecordingSlideFrameEntity[]>;
  listSlideFrames(recordingId: string): Promise<RecordingSlideFrameEntity[]>;

  // Chapters
  replaceChapters(
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
  ): Promise<RecordingChapterEntity[]>;
  updateChapter(
    chapterId: string,
    patch: {
      title?: string;
      summary?: string;
      startSeconds?: number;
      endSeconds?: number;
      keyConcepts?: string[];
    },
  ): Promise<RecordingChapterEntity | null>;
  listChapters(recordingId: string): Promise<RecordingChapterEntity[]>;

  // Lesson Package & Version History
  saveLessonPackage(
    recordingId: string,
    data: Omit<LessonPackageEntity, 'id' | 'recordingId' | 'createdAt' | 'updatedAt'>,
    versionMeta?: { editedById?: string | null; changeSummary?: string },
  ): Promise<LessonPackageEntity>;
  getLessonPackage(recordingId: string): Promise<LessonPackageEntity | null>;
  listLessonPackageVersions(lessonPackageId: string): Promise<LessonPackageVersionEntity[]>;

  // Student Study Artifacts & Quiz Attempts
  createStudyArtifact(params: {
    recordingId: string;
    userId: string;
    kind: StudyArtifactKind;
    title: string;
    language: string;
    chapterIds: string[];
    config: Record<string, unknown>;
    content: Record<string, unknown>;
    modelUsed: string | null;
  }): Promise<StudentLessonArtifactEntity>;
  listStudyArtifacts(
    recordingId: string,
    userId: string,
    kind?: StudyArtifactKind,
  ): Promise<StudentLessonArtifactEntity[]>;
  findStudyArtifactById(artifactId: string): Promise<StudentLessonArtifactEntity | null>;
  createQuizAttempt(params: {
    artifactId: string;
    recordingId: string;
    userId: string;
    score: number;
    totalQuestions: number;
    answers: Array<{ questionId: string; answer: string }>;
    results: StudentQuizAttemptEntity['results'];
    weakTopics: string[];
  }): Promise<StudentQuizAttemptEntity>;
  listQuizAttempts(recordingId: string, userId: string): Promise<StudentQuizAttemptEntity[]>;

  // Student Progress, Bookmarks, Notes
  upsertProgress(params: {
    recordingId: string;
    userId: string;
    lastPositionSeconds?: number;
    watchedSeconds?: number;
    completedChapters?: string[];
    flashcardKnownIds?: string[];
    flashcardReviewIds?: string[];
  }): Promise<StudentLessonProgressEntity>;
  getProgress(recordingId: string, userId: string): Promise<StudentLessonProgressEntity | null>;

  createBookmark(params: {
    recordingId: string;
    userId: string;
    timestampSeconds: number;
    label: string;
    chapterTitle?: string | null;
  }): Promise<StudentLessonBookmarkEntity>;
  listBookmarks(recordingId: string, userId: string): Promise<StudentLessonBookmarkEntity[]>;
  deleteBookmark(bookmarkId: string, userId: string): Promise<boolean>;

  createNote(params: {
    recordingId: string;
    userId: string;
    timestampSeconds?: number | null;
    content: string;
    highlightText?: string | null;
    chapterTitle?: string | null;
  }): Promise<StudentLessonNoteEntity>;
  updateNote(
    noteId: string,
    userId: string,
    patch: { content?: string; highlightText?: string | null; timestampSeconds?: number | null },
  ): Promise<StudentLessonNoteEntity | null>;
  listNotes(recordingId: string, userId: string): Promise<StudentLessonNoteEntity[]>;
  deleteNote(noteId: string, userId: string): Promise<boolean>;

  // AI Tutor Conversations
  createTutorConversation(params: {
    recordingId: string;
    userId: string;
    title: string;
  }): Promise<LessonTutorConversationEntity>;
  listTutorConversations(
    recordingId: string,
    userId: string,
  ): Promise<LessonTutorConversationEntity[]>;
  findTutorConversationById(
    conversationId: string,
    userId: string,
  ): Promise<LessonTutorConversationEntity | null>;
  appendTutorMessage(params: {
    conversationId: string;
    role: 'user' | 'assistant';
    content: string;
    citations?: TutorSourceCitation[];
    modelUsed?: string | null;
  }): Promise<LessonTutorMessageEntity>;
}

