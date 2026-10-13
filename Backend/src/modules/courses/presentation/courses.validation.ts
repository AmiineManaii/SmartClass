import { z } from 'zod';

const uuidSchema = z.string().uuid();
const levelSchema = z.enum(['concis', 'equilibre', 'detaille']);
const difficultySchema = z.enum(['facile', 'moyen', 'difficile']);
const formatSchema = z.enum(['resume', 'flashcards', 'carte-mentale']);

export const courseIdParamsSchema = z
  .object({ id: uuidSchema })
  .strict();

/** Saves a generated course as DRAFT (validation is a separate step). */
export const saveCourseBodySchema = z
  .object({
    title: z.string().trim().min(1).max(200),
    subject: z.string().trim().max(500).optional(),
    content: z.string().min(1).max(500000),
    level: levelSchema,
    difficulty: difficultySchema.default('moyen'),
    format: formatSchema.default('resume'),
  })
  .strict();

export type SaveCourseBodyInput = z.infer<typeof saveCourseBodySchema>;
