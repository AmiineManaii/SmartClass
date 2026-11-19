import { z } from 'zod';
import {
  cursorPaginationQuerySchema,
  sortQuerySchema,
} from '../../../shared/http/pagination/index.js';

const uuidSchema = z.string().uuid();

const fraudStatusSchema = z.enum(['UNTREATED', 'IN_PROGRESS', 'CLOSED']);

const fraudSeveritySchema = z.enum(['LOW', 'MEDIUM', 'HIGH']);

export const fraudSortableFields = ['occurredAt', 'createdAt'] as const;

export const listFraudReportsQuerySchema = cursorPaginationQuerySchema
  .extend({
    status: fraudStatusSchema.optional(),
    severity: fraudSeveritySchema.optional(),
    sort: sortQuerySchema(fraudSortableFields),
  })
  .strict();

export const fraudReportIdParamsSchema = z.object({ id: uuidSchema }).strict();

export const updateFraudReportBodySchema = z
  .object({
    status: z.enum(['IN_PROGRESS', 'CLOSED']),
    resolution: z.string().trim().max(2000).nullable().optional(),
  })
  .strict();

export type ListFraudReportsQueryInput = z.infer<typeof listFraudReportsQuerySchema>;
export type UpdateFraudReportBodyInput = z.infer<typeof updateFraudReportBodySchema>;

// ---------------------------------------------------------------------------
// Official exams
// ---------------------------------------------------------------------------

export const examSettingsSchema = z
  .object({
    shuffleQuestions: z.boolean().optional(),
    requireCamera: z.boolean().optional(),
    allowQuestionSkip: z.boolean().optional(),
    showResultsAfterClose: z.boolean().optional(),
    maxViolationCount: z.number().int().min(1).max(20).optional(),
  })
  .strict();

const questionListSchema = z.array(z.record(z.unknown())).min(1).max(200);

export const examIdParamsSchema = z.object({ examId: uuidSchema }).strict();

export const createExamBodySchema = z
  .object({
    title: z.string().trim().min(1).max(300),
    description: z.string().trim().max(5000).nullable().optional(),
    classGroupId: uuidSchema,
    durationMinutes: z.number().int().min(1).max(600),
    startsAt: z.coerce.date(),
    endsAt: z.coerce.date(),
    source: z.enum(['MANUAL', 'IMPORT', 'AI']).optional(),
    settings: examSettingsSchema.optional(),
    questions: questionListSchema,
  })
  .strict();

export const updateExamBodySchema = z
  .object({
    title: z.string().trim().min(1).max(300).optional(),
    description: z.string().trim().max(5000).nullable().optional(),
    durationMinutes: z.number().int().min(1).max(600).optional(),
    startsAt: z.coerce.date().optional(),
    endsAt: z.coerce.date().optional(),
    settings: examSettingsSchema.optional(),
    questions: questionListSchema.optional(),
  })
  .strict();

export const classCoursesParamsSchema = z.object({ classGroupId: uuidSchema }).strict();

export const generateExamAiBodySchema = z
  .object({
    classGroupId: uuidSchema,
    /** Published + validated courses selected by the teacher. */
    courseIds: z.array(uuidSchema).min(1).max(20).optional(),
    title: z.string().trim().max(300).optional(),
    difficulty: z.enum(['facile', 'moyen', 'difficile']).optional(),
    questionCount: z.number().int().min(1).max(30).optional(),
  })
  .strict();

const answerItemSchema = z
  .object({
    questionId: uuidSchema,
    selectedOptionIds: z.array(z.string().trim().min(1).max(8)).max(8),
  })
  .strict();

export const saveAnswersBodySchema = z
  .object({
    answers: z.array(answerItemSchema).max(300),
  })
  .strict();

export const examEventTypeSchema = z.enum([
  'TAB_HIDDEN',
  'FOCUS_LOST',
  'PAGE_LEAVE',
  'PAGE_REFRESH',
  'FULLSCREEN_EXIT',
  'APP_BACKGROUND',
  'COPY_ATTEMPT',
  'PASTE_ATTEMPT',
  'CUT_ATTEMPT',
  'CONTEXT_MENU',
  'SCREENSHOT_ATTEMPT',
  'NETWORK_LOST',
  'NETWORK_RESTORED',
  'CAMERA_DENIED',
  'GAZE_OFF_SCREEN',
  'TECHNICAL_INTERRUPTION',
]);

export const recordEventBodySchema = z
  .object({
    type: examEventTypeSchema,
    durationMs: z.number().int().min(0).max(86_400_000).nullable().optional(),
    source: z.string().trim().max(20).optional(),
    clientOccurredAt: z.string().trim().max(40).nullable().optional(),
    metadata: z
      .record(z.unknown())
      .optional()
      .refine((value) => !value || JSON.stringify(value).length <= 4000, {
        message: 'Event metadata is too large',
      }),
  })
  .strict();

export const monitoringParamsSchema = z
  .object({ examId: uuidSchema, attemptId: uuidSchema })
  .strict();

export const eventStateParamsSchema = z
  .object({ examId: uuidSchema, eventId: uuidSchema })
  .strict();

export const updateEventStateBodySchema = z
  .object({ state: z.enum(['NEW', 'REVIEWED', 'CONFIRMED']) })
  .strict();

export const recordingParamsSchema = z
  .object({ examId: uuidSchema, recordingId: uuidSchema })
  .strict();

export const recordingUploadBodySchema = z
  .object({
    eventId: uuidSchema.optional(),
    durationMs: z.coerce.number().int().min(0).max(3_600_000).optional(),
    kind: z.string().trim().max(40).optional(),
  })
  .strict();
