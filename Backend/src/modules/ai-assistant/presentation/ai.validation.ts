import { z } from 'zod';

const modeSchema = z.enum(['topic', 'text', 'url']);
const levelSchema = z.enum(['concis', 'equilibre', 'detaille']);
const difficultySchema = z.enum(['facile', 'moyen', 'difficile']);
const formatSchema = z.enum(['resume', 'flashcards', 'carte-mentale']);

const extrasSchema = z
  .preprocess((val) => {
    // Multipart fields arrive as strings: accept a JSON-encoded object.
    if (typeof val === 'string') {
      try {
        return JSON.parse(val) as unknown;
      } catch {
        return val;
      }
    }
    return val;
  }, z
    .object({
      examples: z.boolean().optional(),
      mermaid: z.boolean().optional(),
      webImages: z.boolean().optional(),
      webSearch: z.boolean().optional(),
      thinking: z.boolean().optional(),
    })
    .strict()
    .optional());

const courseOptions = {
  level: levelSchema.default('equilibre'),
  difficulty: difficultySchema.default('moyen'),
  format: formatSchema.default('resume'),
  extras: extrasSchema,
};

export const generateCourseBodySchema = z
  .object({
    mode: modeSchema,
    ...courseOptions,
    subject: z.string().trim().max(500).optional(),
    sourceText: z.string().max(200000).optional(),
    url: z.string().trim().max(2000).optional(),
  })
  .strict();

/// One endpoint per teacher-facing method (simpler payloads, no `mode`).
export const fromTopicBodySchema = z
  .object({
    subject: z.string().trim().min(10).max(500),
    ...courseOptions,
  })
  .strict();

export const fromUrlBodySchema = z
  .object({
    url: z.string().trim().max(2000),
    ...courseOptions,
  })
  .strict();

/// Text fields of the multipart `improve-pdf` body (the file itself is
/// handled by multer, not Zod).
export const improvePdfFieldsSchema = z
  .object({
    level: levelSchema.default('equilibre'),
    difficulty: difficultySchema.default('moyen'),
    format: formatSchema.default('resume'),
    extras: extrasSchema,
  })
  .strict();

export type GenerateCourseBodyInput = z.infer<typeof generateCourseBodySchema>;
export type FromTopicBodyInput = z.infer<typeof fromTopicBodySchema>;
export type FromUrlBodyInput = z.infer<typeof fromUrlBodySchema>;
export type ImprovePdfFieldsInput = z.infer<typeof improvePdfFieldsSchema>;
