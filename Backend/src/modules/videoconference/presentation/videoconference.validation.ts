import { z } from 'zod';

const uuidSchema = z.string().uuid();

const isoDateSchema = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Expected ISO date YYYY-MM-DD')
  .refine(
    (value) => {
      const [year, month, day] = value.split('-').map(Number);
      const date = new Date(Date.UTC(year as number, (month as number) - 1, day as number));
      return (
        date.getUTCFullYear() === year &&
        date.getUTCMonth() === (month as number) - 1 &&
        date.getUTCDate() === day
      );
    },
    { message: 'Invalid calendar date' },
  );

const isoDateTimeSchema = z
  .string()
  .datetime({ offset: true, message: 'Expected ISO 8601 date-time string (e.g. 2026-10-26T10:00:00.000Z)' });

export const sessionIdParamsSchema = z
  .object({
    id: uuidSchema,
  })
  .strict();

export type SessionIdParamsInput = z.infer<typeof sessionIdParamsSchema>;

export const timetableQuerySchema = z
  .object({
    classGroupId: uuidSchema,
    weekStart: isoDateSchema.optional(),
  })
  .strict();

export type TimetableQueryInput = z.infer<typeof timetableQuerySchema>;

export const createVideoSessionBodySchema = z
  .object({
    classGroupId: uuidSchema,
    title: z.string().trim().min(3).max(200),
    description: z.string().trim().max(1000).nullable().optional(),
    subject: z.string().trim().max(100).nullable().optional(),
    mode: z.enum(['NOW', 'SCHEDULED']),
    startsAt: isoDateTimeSchema.optional(),
    endsAt: isoDateTimeSchema.optional(),
    durationMinutes: z.number().int().min(5).max(480).optional(),
    joinOpensMinutesBefore: z.number().int().min(0).max(30).optional(),
    chatEnabled: z.boolean().optional(),
    timetableSlotId: uuidSchema.nullable().optional(),
    courseId: uuidSchema.nullable().optional(),
  })
  .strict();

export type CreateVideoSessionBodyInput = z.infer<typeof createVideoSessionBodySchema>;

export const updateVideoSessionBodySchema = z
  .object({
    title: z.string().trim().min(3).max(200).optional(),
    description: z.string().trim().max(1000).nullable().optional(),
    subject: z.string().trim().max(100).nullable().optional(),
    startsAt: isoDateTimeSchema.optional(),
    endsAt: isoDateTimeSchema.optional(),
    durationMinutes: z.number().int().min(5).max(480).optional(),
    joinOpensMinutesBefore: z.number().int().min(0).max(30).optional(),
    chatEnabled: z.boolean().optional(),
  })
  .strict();

export type UpdateVideoSessionBodyInput = z.infer<typeof updateVideoSessionBodySchema>;

export const cancelVideoSessionBodySchema = z
  .object({
    reason: z.string().trim().max(500).nullable().optional(),
    cancelReason: z.string().trim().max(500).nullable().optional(),
  })
  .strict();

export type CancelVideoSessionBodyInput = z.infer<typeof cancelVideoSessionBodySchema>;

export const listVideoSessionsQuerySchema = z
  .object({
    classGroupId: uuidSchema.optional(),
    status: z.enum(['SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELED']).optional(),
    page: z.coerce.number().int().min(1).optional(),
    limit: z.coerce.number().int().min(1).max(100).optional(),
    scope: z.enum(['all', 'mine']).optional(),
  })
  .strict();

export type ListVideoSessionsQueryInput = z.infer<typeof listVideoSessionsQuerySchema>;

export const muteParticipantBodySchema = z
  .object({
    targetUserId: uuidSchema,
  })
  .strict();

export type MuteParticipantBodyInput = z.infer<typeof muteParticipantBodySchema>;

export const removeParticipantBodySchema = z
  .object({
    targetUserId: uuidSchema,
    reason: z.string().trim().max(500).nullable().optional(),
  })
  .strict();

export type RemoveParticipantBodyInput = z.infer<typeof removeParticipantBodySchema>;

export const createChatMessageBodySchema = z
  .object({
    clientMessageId: uuidSchema.optional(),
    content: z.string().trim().min(1).max(2000),
  })
  .strict();

export type CreateChatMessageBodyInput = z.infer<typeof createChatMessageBodySchema>;

export const listChatMessagesQuerySchema = z
  .object({
    page: z.coerce.number().int().min(1).optional(),
    limit: z.coerce.number().int().min(1).max(100).optional(),
  })
  .strict();

export type ListChatMessagesQueryInput = z.infer<typeof listChatMessagesQuerySchema>;

export const participantIdParamsSchema = z
  .object({
    id: uuidSchema,
    userId: uuidSchema,
  })
  .strict();

export type ParticipantIdParamsInput = z.infer<typeof participantIdParamsSchema>;

export const chatSettingsBodySchema = z
  .object({
    enabled: z.boolean(),
  })
  .strict();

export type ChatSettingsBodyInput = z.infer<typeof chatSettingsBodySchema>;

export const nextSessionQuerySchema = z
  .object({
    horizonHours: z.coerce.number().int().min(1).max(72).optional(),
  })
  .strict();

export type NextSessionQueryInput = z.infer<typeof nextSessionQuerySchema>;

export const sseEventsQuerySchema = z
  .object({
    sessionId: uuidSchema.optional(),
  })
  .strict();

export type SSEEventsQueryInput = z.infer<typeof sseEventsQuerySchema>;


