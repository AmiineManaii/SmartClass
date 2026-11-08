export type RecordingStatus =
  | 'NOT_STARTED'
  | 'STARTING'
  | 'RECORDING'
  | 'FINALIZING'
  | 'RECORDED'
  | 'PROCESSING'
  | 'READY_FOR_REVIEW'
  | 'APPROVED'
  | 'PUBLISHED'
  | 'FAILED'
  | 'DELETED';

export type ProcessingJobStatus =
  | 'QUEUED'
  | 'RUNNING'
  | 'SUCCEEDED'
  | 'FAILED'
  | 'CANCELED';

export type ProcessingStage =
  | 'VALIDATION'
  | 'AUDIO_EXTRACTION'
  | 'TRANSCRIPTION'
  | 'VISUAL_ANALYSIS'
  | 'DOCUMENT_ANALYSIS'
  | 'TEMPORAL_ALIGNMENT'
  | 'LESSON_GENERATION'
  | 'QUALITY_VALIDATION'
  | 'COMPLETED';

export type StudyArtifactKind = 'SUMMARY' | 'QUIZ' | 'FLASHCARDS';

export interface RecordingEntity {
  id: string;
  sessionId: string;
  classGroupId: string;
  hostId: string | null;
  status: RecordingStatus;
  egressId: string | null;
  storageKey: string | null;
  mimeType: string;
  sizeBytes: number | null;
  durationSeconds: number | null;
  width: number | null;
  height: number | null;
  thumbnailKey: string | null;
  sourceDocKey: string | null;
  sourceDocTitle: string | null;
  sourceDocText: string | null;
  errorCode: string | null;
  errorMessage: string | null;
  startedAt: Date | null;
  stoppedAt: Date | null;
  publishedAt: Date | null;
  processingVersion: number;
  aiModelUsed: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface StageLogEntry {
  stage: ProcessingStage;
  progress: number;
  message: string;
  at: string;
  modelUsed?: string;
}

export interface RecordingProcessingJobEntity {
  id: string;
  recordingId: string;
  status: ProcessingJobStatus;
  stage: ProcessingStage;
  progress: number;
  attempts: number;
  maxAttempts: number;
  lockedAt: Date | null;
  workerId: string | null;
  errorMessage: string | null;
  stageLogs: StageLogEntry[];
  startedAt: Date | null;
  completedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface RecordingTranscriptSegmentEntity {
  id: string;
  transcriptId: string;
  recordingId: string;
  orderIndex: number;
  startSeconds: number;
  endSeconds: number;
  text: string;
  speaker: string | null;
  confidence: number;
}

export interface RecordingTranscriptEntity {
  id: string;
  recordingId: string;
  language: string;
  fullText: string;
  vttContent: string;
  srtContent: string;
  qualityScore: number;
  modelUsed: string | null;
  updatedById: string | null;
  segments: RecordingTranscriptSegmentEntity[];
  createdAt: Date;
  updatedAt: Date;
}

export interface RecordingSlideFrameEntity {
  id: string;
  recordingId: string;
  timestampSeconds: number;
  storageKey: string | null;
  perceptualHash: string | null;
  ocrText: string;
  visualSummary: string;
  sourcePage: number | null;
  modelUsed: string | null;
  createdAt: Date;
}

export interface RecordingChapterEntity {
  id: string;
  recordingId: string;
  orderIndex: number;
  title: string;
  summary: string;
  startSeconds: number;
  endSeconds: number;
  keyConcepts: string[];
  slideFrameId: string | null;
  sourcePage: number | null;
}

export interface LessonConcept {
  name: string;
  explanation: string;
  chapterOrder?: number;
  timestampSeconds?: number;
  sourcePage?: number;
}

export interface LessonDefinition {
  term: string;
  definition: string;
  chapterTitle?: string;
  timestampSeconds?: number;
}

export interface LessonExample {
  title: string;
  description: string;
  solutionOrWalkthrough: string;
  timestampSeconds?: number;
}

export interface ImportantMoment {
  label: string;
  timestampSeconds: number;
  reason: string;
  chapterTitle?: string;
}

export interface GeneratedFlashcard {
  id: string;
  front: string;
  back: string;
  chapterTitle: string;
  difficulty: 'facile' | 'moyen' | 'difficile';
  timestampSeconds?: number;
  sourcePage?: number;
}

export interface GeneratedQuizQuestion {
  id: string;
  type: 'MULTIPLE_CHOICE' | 'TRUE_FALSE' | 'SHORT_ANSWER' | 'CONCEPTUAL' | 'PRACTICAL';
  question: string;
  options: string[];
  correctAnswer: string;
  explanation: string;
  difficulty: 'facile' | 'moyen' | 'difficile';
  chapterTitle: string;
  timestampSeconds?: number;
  sourcePage?: number;
}

export interface LessonQualityReport {
  isValid: boolean;
  score: number;
  warnings: string[];
  checkedAt: string;
  transcriptCoverageRatio: number;
  chaptersAlignedCount: number;
}

export interface LessonPackageEntity {
  id: string;
  recordingId: string;
  version: number;
  structuredNotes: string;
  generalSummary: string;
  keyConcepts: LessonConcept[];
  definitions: LessonDefinition[];
  importantExamples: LessonExample[];
  learningObjectives: string[];
  formulasAndRules: string[];
  importantMoments: ImportantMoment[];
  revisionSheet: string;
  mindMapMermaid: string;
  suggestedStudyOrder: string[];
  flashcards: GeneratedFlashcard[];
  quizzes: GeneratedQuizQuestion[];
  qualityReport: LessonQualityReport;
  primaryModel: string | null;
  secondaryModel: string | null;
  approvedById: string | null;
  approvedAt: Date | null;
  publishedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface LessonPackageVersionEntity {
  id: string;
  lessonPackageId: string;
  version: number;
  snapshot: Record<string, unknown>;
  editedById: string | null;
  changeSummary: string | null;
  createdAt: Date;
}

export interface StudentLessonArtifactEntity {
  id: string;
  recordingId: string;
  userId: string;
  kind: StudyArtifactKind;
  title: string;
  language: string;
  chapterIds: string[];
  config: Record<string, unknown>;
  content: Record<string, unknown>;
  modelUsed: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface StudentQuizAttemptEntity {
  id: string;
  artifactId: string;
  recordingId: string;
  userId: string;
  score: number;
  totalQuestions: number;
  answers: Array<{ questionId: string; answer: string }>;
  results: Array<{
    questionId: string;
    isCorrect: boolean;
    userAnswer: string;
    correctAnswer: string;
    explanation: string;
    chapterTitle: string;
    timestampSeconds?: number;
  }>;
  weakTopics: string[];
  completedAt: Date;
}

export interface StudentLessonProgressEntity {
  id: string;
  recordingId: string;
  userId: string;
  lastPositionSeconds: number;
  watchedSeconds: number;
  completedChapters: string[];
  flashcardKnownIds: string[];
  flashcardReviewIds: string[];
  updatedAt: Date;
}

export interface StudentLessonBookmarkEntity {
  id: string;
  recordingId: string;
  userId: string;
  timestampSeconds: number;
  label: string;
  chapterTitle: string | null;
  createdAt: Date;
}

export interface StudentLessonNoteEntity {
  id: string;
  recordingId: string;
  userId: string;
  timestampSeconds: number | null;
  content: string;
  highlightText: string | null;
  chapterTitle: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface TutorSourceCitation {
  type: 'TRANSCRIPT' | 'CHAPTER' | 'SLIDE' | 'DOCUMENT';
  label: string;
  excerpt: string;
  timestampSeconds: number | null;
  chapterTitle: string | null;
  slideNumber: number | null;
  sourcePage: number | null;
}

export interface LessonTutorMessageEntity {
  id: string;
  conversationId: string;
  role: 'user' | 'assistant';
  content: string;
  citations: TutorSourceCitation[];
  modelUsed: string | null;
  createdAt: Date;
}

export interface LessonTutorConversationEntity {
  id: string;
  recordingId: string;
  userId: string;
  title: string;
  messages: LessonTutorMessageEntity[];
  createdAt: Date;
  updatedAt: Date;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pure Domain Lifecycle & Subtitle Formatting Helpers
// ─────────────────────────────────────────────────────────────────────────────

export const canStartRecording = (status: RecordingStatus | null | undefined): boolean => {
  if (!status) return true;
  return status === 'NOT_STARTED' || status === 'FAILED';
};

export const canStopRecording = (status: RecordingStatus | null | undefined): boolean => {
  return status === 'STARTING' || status === 'RECORDING';
};

export const canApproveLesson = (status: RecordingStatus): boolean => {
  return status === 'READY_FOR_REVIEW' || status === 'APPROVED' || status === 'PUBLISHED';
};

export const canPublishLesson = (status: RecordingStatus): boolean => {
  return status === 'READY_FOR_REVIEW' || status === 'APPROVED' || status === 'PUBLISHED';
};

export const formatClockTimestamp = (seconds: number): string => {
  const safe = Math.max(0, Math.floor(seconds));
  const hrs = Math.floor(safe / 3600);
  const mins = Math.floor((safe % 3600) / 60);
  const secs = safe % 60;
  if (hrs > 0) {
    return `${String(hrs).padStart(2, '0')}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }
  return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
};

export const formatVttTime = (seconds: number): string => {
  const safe = Math.max(0, seconds);
  const hrs = Math.floor(safe / 3600);
  const mins = Math.floor((safe % 3600) / 60);
  const secs = Math.floor(safe % 60);
  const ms = Math.round((safe - Math.floor(safe)) * 1000);
  return `${String(hrs).padStart(2, '0')}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}.${String(ms).padStart(3, '0')}`;
};

export const formatSrtTime = (seconds: number): string => {
  return formatVttTime(seconds).replace('.', ',');
};

export const buildVttFromSegments = (
  segments: Array<{ startSeconds: number; endSeconds: number; text: string }>,
): string => {
  const lines = ['WEBVTT', ''];
  segments.forEach((seg, idx) => {
    lines.push(`${idx + 1}`);
    lines.push(`${formatVttTime(seg.startSeconds)} --> ${formatVttTime(seg.endSeconds)}`);
    lines.push(seg.text.trim());
    lines.push('');
  });
  return lines.join('\n');
};

export const buildSrtFromSegments = (
  segments: Array<{ startSeconds: number; endSeconds: number; text: string }>,
): string => {
  const lines: string[] = [];
  segments.forEach((seg, idx) => {
    lines.push(`${idx + 1}`);
    lines.push(`${formatSrtTime(seg.startSeconds)} --> ${formatSrtTime(seg.endSeconds)}`);
    lines.push(seg.text.trim());
    lines.push('');
  });
  return lines.join('\n');
};

