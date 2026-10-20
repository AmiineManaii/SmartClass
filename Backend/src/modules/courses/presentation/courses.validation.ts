import { z } from 'zod';

const uuidSchema = z.string().uuid();
const levelSchema = z.enum(['concis', 'equilibre', 'detaille']);
const difficultySchema = z.enum(['facile', 'moyen', 'difficile']);
const formatSchema = z.enum(['resume', 'flashcards', 'carte-mentale']);

const outlineSectionSchema = z
  .object({
    id: z.string().max(120).optional(),
    title: z.string().min(1).max(300),
    description: z.string().max(4000).optional(),
    keyTopics: z.array(z.string().max(300)).max(40).optional(),
    estimatedMinutes: z.number().int().min(1).max(600).optional(),
  })
  .passthrough();

/** Teacher-validated plan stored on the course (drives the build). */
export const outlineBodySchema = z
  .object({
    title: z.string().trim().min(1).max(300),
    targetAudience: z.string().max(300).optional(),
    prerequisites: z.array(z.string().max(300)).max(30).optional(),
    description: z.string().max(4000).optional(),
    sections: z.array(outlineSectionSchema).min(1).max(30),
  })
  .passthrough();

export const courseIdParamsSchema = z
  .object({ id: uuidSchema })
  .strict();

export const saveCourseBodySchema = z
  .object({
    title: z.string().trim().min(1).max(200),
    subject: z.string().trim().max(500).optional(),
    content: z.string().min(1).max(500000),
    level: levelSchema,
    difficulty: difficultySchema.default('moyen'),
    format: formatSchema.default('resume'),
    classGroupIds: z.array(uuidSchema).max(50).optional(),
    outline: outlineBodySchema.optional(),
  })
  .strict();

export const updateCourseBodySchema = z
  .object({
    title: z.string().trim().min(1).max(200).optional(),
    subject: z.string().trim().max(500).optional(),
    content: z.string().min(1).max(500000).optional(),
    level: levelSchema.optional(),
    difficulty: difficultySchema.optional(),
    format: formatSchema.optional(),
    classGroupIds: z.array(uuidSchema).max(50).optional(),
  })
  .strict();

export type SaveCourseBodyInput = z.infer<typeof saveCourseBodySchema>;
export type UpdateCourseBodyInput = z.infer<typeof updateCourseBodySchema>;

