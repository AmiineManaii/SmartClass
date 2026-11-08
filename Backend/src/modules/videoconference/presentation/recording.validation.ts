import { z } from 'zod';

const uuidSchema = z.string().uuid();

export const recordingStatusEnum = z.enum([
  'NOT_STARTED',
  'STARTING',
  'RECORDING',
  'FINALIZING',
  'RECORDED',
  'PROCESSING',
  'READY_FOR_REVIEW',
  'APPROVED',
  'PUBLISHED',
  'FAILED',
  'DELETED',
]);

export const listRecordingsQuerySchema = z
  .object({
    classGroupId: uuidSchema.optional(),
    status: recordingStatusEnum.optional(),
  })
  .strict();

export type ListRecordingsQueryInput = z.infer<typeof listRecordingsQuerySchema>;

export const subtitlesQuerySchema = z
  .object({
    format: z.enum(['vtt', 'srt']).optional(),
    token: z.string().optional(),
  })
  .strict();

export const mediaStreamQuerySchema = z
  .object({
    token: z.string().optional(),
  });

export const frameParamsSchema = z.object({
  id: uuidSchema,
  frameIndex: z.coerce.number().int().min(0).max(50),
});

export const stopRecordingBodySchema = z
  .object({
    spokenTranscript: z.string().max(200_000).optional(),
    detectedLanguage: z.string().max(32).optional(),
    capturedSegments: z
      .array(
        z.object({
          startSeconds: z.number().min(0),
          endSeconds: z.number().min(0),
          text: z.string().max(4000),
          speaker: z.string().max(120).optional(),
          language: z.string().max(32).optional(),
        }),
      )
      .optional(),
    mediaBase64: z.string().max(40_000_000).optional(),
    mimeType: z.string().max(100).optional(),
  })
  .optional();

export type StopRecordingBodyInput = z.infer<typeof stopRecordingBodySchema>;

export const uploadSourceDocBodySchema = z
  .object({
    title: z.string().trim().min(2).max(200),
    mimeType: z.string().trim().max(100).optional(),
    contentText: z.string().max(100_000).optional(),
    fileBase64: z.string().max(15_000_000).optional(),
  });

export type UploadSourceDocBodyInput = z.infer<typeof uploadSourceDocBodySchema>;

export const updateLessonReviewBodySchema = z
  .object({
    title: z.string().trim().max(250).optional(),
    shortSummary: z.string().max(25_000).optional(),
    detailedSummary: z.string().max(25_000).optional(),
    structuredMarkdown: z.string().max(100_000).optional(),
    changeSummary: z.string().trim().max(300).optional(),
    transcriptSegments: z
      .array(
        z.object({
          orderIndex: z.number().int().min(0).optional(),
          startSeconds: z.number().min(0),
          endSeconds: z.number().min(0),
          text: z.string().trim().min(1).max(4000),
          speaker: z.string().trim().max(120).nullable().optional(),
        }),
      )
      .optional(),
    chapters: z
      .array(
        z.object({
          orderIndex: z.number().int().min(0).optional(),
          title: z.string().trim().min(1).max(200),
          summary: z.string().trim().min(1).max(4000),
          startSeconds: z.number().min(0),
          endSeconds: z.number().min(0),
          keyConcepts: z.array(z.string().trim().min(1).max(160)).optional(),
          slideFrameId: z.string().nullable().optional(),
          sourcePage: z.number().int().min(1).nullable().optional(),
        }),
      )
      .optional(),
    structuredNotes: z.string().max(100_000).optional(),
    generalSummary: z.string().max(25_000).optional(),
    keyConcepts: z
      .array(
        z.object({
          name: z.string().trim().min(1).max(200),
          explanation: z.string().trim().min(1).max(2000),
          chapterOrder: z.number().int().optional(),
          timestampSeconds: z.number().min(0).optional(),
          sourcePage: z.number().int().optional(),
        }),
      )
      .optional(),
    definitions: z
      .array(
        z.object({
          term: z.string().trim().min(1).max(200),
          definition: z.string().trim().min(1).max(2000),
          chapterTitle: z.string().max(200).optional(),
          timestampSeconds: z.number().min(0).optional(),
        }),
      )
      .optional(),
    importantExamples: z
      .array(
        z.object({
          title: z.string().trim().min(1).max(200),
          description: z.string().trim().min(1).max(2000),
          solutionOrWalkthrough: z.string().trim().min(1).max(4000),
          timestampSeconds: z.number().min(0).optional(),
        }),
      )
      .optional(),
    learningObjectives: z.array(z.string().trim().min(1).max(500)).optional(),
    formulasAndRules: z.array(z.string().trim().min(1).max(1000)).optional(),
    importantMoments: z
      .array(
        z.object({
          label: z.string().trim().min(1).max(200),
          timestampSeconds: z.number().min(0),
          reason: z.string().trim().min(1).max(1000),
          chapterTitle: z.string().max(200).optional(),
        }),
      )
      .optional(),
    revisionSheet: z.string().max(50_000).optional(),
    mindMapMermaid: z.string().max(25_000).optional(),
    suggestedStudyOrder: z.array(z.string().trim().min(1).max(500)).optional(),
    flashcards: z
      .array(
        z.object({
          id: z.string().min(1).max(100),
          front: z.string().trim().min(1).max(1000),
          back: z.string().trim().min(1).max(2000),
          chapterTitle: z.string().max(200),
          difficulty: z.enum(['facile', 'moyen', 'difficile']),
          timestampSeconds: z.number().min(0).optional(),
          sourcePage: z.number().int().optional(),
        }),
      )
      .optional(),
    quizzes: z
      .array(
        z.object({
          id: z.string().min(1).max(100),
          type: z.enum([
            'MULTIPLE_CHOICE',
            'TRUE_FALSE',
            'SHORT_ANSWER',
            'CONCEPTUAL',
            'PRACTICAL',
          ]),
          question: z.string().trim().min(2).max(1000),
          options: z.array(z.string().trim().min(1).max(500)),
          correctAnswer: z.string().trim().min(1).max(1000),
          explanation: z.string().trim().min(1).max(2000),
          difficulty: z.enum(['facile', 'moyen', 'difficile']),
          chapterTitle: z.string().max(200),
          timestampSeconds: z.number().min(0).optional(),
          sourcePage: z.number().int().optional(),
        }),
      )
      .optional(),
  });

export type UpdateLessonReviewBodyInput = z.infer<typeof updateLessonReviewBodySchema>;

export const regenerateSectionBodySchema = z
  .object({
    section: z.enum(['summary', 'structuredNotes', 'quiz', 'flashcards', 'mindMap']),
    instructions: z.string().trim().max(1000).optional(),
  })
  .strict();

export type RegenerateSectionBodyInput = z.infer<typeof regenerateSectionBodySchema>;

export const searchLessonQuerySchema = z
  .object({
    q: z.string().trim().min(1).max(200),
  })
  .strict();

export type SearchLessonQueryInput = z.infer<typeof searchLessonQuerySchema>;

export const updateStudentProgressBodySchema = z
  .object({
    lastPositionSeconds: z.number().int().min(0).optional(),
    watchedSeconds: z.number().int().min(0).optional(),
    completedChapters: z.array(z.string()).optional(),
    flashcardKnownIds: z.array(z.string()).optional(),
    flashcardReviewIds: z.array(z.string()).optional(),
  })
  .strict();

export type UpdateStudentProgressBodyInput = z.infer<typeof updateStudentProgressBodySchema>;

export const createBookmarkBodySchema = z
  .object({
    timestampSeconds: z.number().int().min(0),
    label: z.string().trim().min(1).max(200),
    chapterTitle: z.string().trim().max(200).nullable().optional(),
  })
  .strict();

export type CreateBookmarkBodyInput = z.infer<typeof createBookmarkBodySchema>;

export const bookmarkIdParamsSchema = z
  .object({
    id: uuidSchema,
    bookmarkId: uuidSchema,
  })
  .strict();

export const createStudentNoteBodySchema = z
  .object({
    timestampSeconds: z.number().int().min(0).nullable().optional(),
    content: z.string().trim().min(1).max(4000),
    highlightText: z.string().trim().max(1000).nullable().optional(),
    chapterTitle: z.string().trim().max(200).nullable().optional(),
  })
  .strict();

export type CreateStudentNoteBodyInput = z.infer<typeof createStudentNoteBodySchema>;

export const updateStudentNoteBodySchema = z
  .object({
    timestampSeconds: z.number().int().min(0).nullable().optional(),
    content: z.string().trim().min(1).max(4000).optional(),
    highlightText: z.string().trim().max(1000).nullable().optional(),
  })
  .strict();

export const noteIdParamsSchema = z
  .object({
    id: uuidSchema,
    noteId: uuidSchema,
  })
  .strict();

export const generateStudyArtifactBodySchema = z
  .object({
    kind: z.enum(['SUMMARY', 'QUIZ', 'FLASHCARDS']),
    language: z.enum(['fr', 'en', 'ar', 'ar-TN', 'auto']).optional(),
    chapterIds: z.array(z.string()).optional(),
    chapterTitle: z.string().max(200).optional(),
    summaryMode: z
      .enum(['short', 'medium', 'detailed', 'exam', 'eli15', 'concise', 'bullet_points'])
      .optional(),
    difficulty: z
      .enum(['facile', 'moyen', 'difficile', 'easy', 'medium', 'hard'])
      .optional(),
    questionCount: z.number().int().min(1).max(20).optional(),
    questionTypes: z
      .array(
        z.enum(['MULTIPLE_CHOICE', 'TRUE_FALSE', 'SHORT_ANSWER', 'CONCEPTUAL', 'PRACTICAL']),
      )
      .optional(),
    flashcardCount: z.number().int().min(1).max(30).optional(),
    focus: z.string().max(200).optional(),
  });

export type GenerateStudyArtifactBodyInput = z.infer<typeof generateStudyArtifactBodySchema>;

export const submitQuizAttemptBodySchema = z
  .object({
    artifactId: z.string().max(100).optional(),
    answers: z
      .array(
        z.object({
          questionId: z.string().max(100).optional(),
          answer: z.string().max(1000).optional(),
          questionIndex: z.number().int().min(0).optional(),
          selectedIndex: z.number().int().min(-1).optional(),
        }),
      )
      .min(1),
  });

export type SubmitQuizAttemptBodyInput = z.infer<typeof submitQuizAttemptBodySchema>;

export const askLessonTutorBodySchema = z
  .object({
    question: z.string().trim().min(1).max(2000),
    conversationId: uuidSchema.optional(),
    currentTimestampSeconds: z.number().int().min(0).optional(),
    responseStyle: z.enum(['concise', 'detailed', 'step-by-step', 'exam-focused']).optional(),
  });

export type AskLessonTutorBodyInput = z.infer<typeof askLessonTutorBodySchema>;

