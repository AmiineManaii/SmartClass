import { z } from 'zod';

const modeSchema = z.enum(['topic', 'text', 'url']);
const levelSchema = z.enum(['concis', 'equilibre', 'detaille']);
const difficultySchema = z.enum(['facile', 'moyen', 'difficile']);
const formatSchema = z.enum(['resume', 'flashcards', 'carte-mentale']);

const extrasSchema = z.preprocess(
  (val) => {
    // Multipart fields arrive as strings: accept a JSON-encoded object.
    if (typeof val === 'string') {
      try {
        return JSON.parse(val) as unknown;
      } catch {
        return val;
      }
    }
    return val;
  },
  z
    .object({
      examples: z.boolean().optional(),
      mermaid: z.boolean().optional(),
      webImages: z.boolean().optional(),
      webSearch: z.boolean().optional(),
      thinking: z.boolean().optional(),
      generateImages: z.boolean().optional(),
    })
    .strict()
    .optional(),
);

const courseOptions = {
  level: levelSchema.default('equilibre'),
  difficulty: difficultySchema.default('moyen'),
  format: formatSchema.default('resume'),
  extras: extrasSchema,
};

const outlineSectionSchema = z
  .object({
    id: z.string().optional(),
    title: z.string(),
    description: z.string().optional().default(''),
    keyTopics: z.array(z.string()).optional().default([]),
    subtopics: z.array(z.string()).optional().default([]),
    estimatedMinutes: z.number().optional().default(15),
  })
  .passthrough()
  .transform((s) => ({
    id: s.id || `sec-${Math.random().toString(36).substring(2, 7)}`,
    title: s.title,
    description: s.description || '',
    keyTopics:
      s.keyTopics && s.keyTopics.length > 0
        ? s.keyTopics
        : s.subtopics && s.subtopics.length > 0
          ? s.subtopics
          : [],
    estimatedMinutes: s.estimatedMinutes ?? 15,
  }));

export const courseOutlineSchema = z
  .object({
    title: z.string().default('Cours'),
    targetAudience: z.string().optional().default('Étudiants universitaires'),
    prerequisites: z.array(z.string()).optional().default([]),
    description: z.string().optional().default(''),
    sections: z.array(outlineSectionSchema),
  })
  .passthrough();

export const generateOutlineBodySchema = z
  .object({
    topic: z.string().trim().max(500).optional(),
    subject: z.string().trim().max(500).optional(),
    level: levelSchema.default('equilibre'),
    difficulty: difficultySchema.default('moyen'),
    format: formatSchema.optional(),
    mode: modeSchema.optional(),
    sourceContext: z.string().max(200000).optional(),
    sourceText: z.string().max(200000).optional(),
    url: z.string().trim().max(2000).optional(),
    extras: extrasSchema.optional(),
  })
  .passthrough()
  .refine(
    (data) => {
      const main = data.topic || data.subject || data.sourceContext || data.sourceText || data.url;
      return typeof main === 'string' && main.trim().length >= 2;
    },
    {
      message: 'Un sujet ou un contenu source est requis (au moins 2 caractères).',
      path: ['subject'],
    },
  )
  .transform((data) => ({
    topic: (data.topic || data.subject || data.url || 'Cours sans titre').trim(),
    level: data.level,
    difficulty: data.difficulty,
    sourceContext: data.sourceContext || data.sourceText || data.url,
  }));

export const refineSectionBodySchema = z
  .object({
    courseTitle: z.string().trim().max(200).optional(),
    courseId: z.string().uuid().optional(),
    selectedText: z.string().min(1).max(50000),
    instruction: z.string().trim().min(1).max(2000),
    fullContext: z.string().max(200000).optional(),
    courseContent: z.string().max(200000).optional(),
    level: levelSchema.optional(),
    difficulty: difficultySchema.optional(),
  })
  .passthrough()
  .transform((data) => ({
    courseTitle: data.courseTitle,
    courseId: data.courseId,
    selectedText: data.selectedText,
    instruction: data.instruction,
    fullContext: data.fullContext || data.courseContent,
  }));

/** `/ai/courses/:id/build` path params. */
export const courseBuildParamsSchema = z.object({ id: z.string().uuid() }).strict();

/** Identifies one section of a course build. */
const sectionTargetFields = {
  courseId: z.string().uuid(),
  sectionKey: z.string().trim().min(1).max(120),
};

/** POST /ai/courses/sections/generate | /regenerate (SSE). */
export const generateSectionBodySchema = z
  .object({
    ...sectionTargetFields,
    level: levelSchema.optional(),
    difficulty: difficultySchema.optional(),
    extras: z
      .object({ examples: z.boolean().optional(), mermaid: z.boolean().optional() })
      .strict()
      .optional(),
  })
  .strict();

/** POST /ai/courses/sections/validate. */
export const validateSectionBodySchema = z.object(sectionTargetFields).strict();

/** POST /ai/courses/sections/image — illustration for one section. */
export const imageSectionBodySchema = z
  .object({
    ...sectionTargetFields,
    kind: z.enum(['FIGURE', 'ARCHITECTURE', 'FLOWCHART', 'WORKFLOW']),
  })
  .strict();

/** GET /ai/courses/sections/image/jobs/:jobId. */
export const sectionImageJobParamsSchema = z.object({ jobId: z.string().uuid() }).strict();

/** POST /ai/courses/sections/image/search — up to five web candidates. */
export const searchSectionImagesBodySchema = z
  .object({
    ...sectionTargetFields,
    query: z.string().trim().max(200).optional(),
  })
  .strict();

/** POST /ai/courses/sections/image/apply — insert the chosen image. */
export const applySectionImageBodySchema = z
  .object({
    ...sectionTargetFields,
    imageUrl: z.string().trim().url().max(2000),
    caption: z.string().trim().max(300).optional(),
  })
  .strict();

export const generateCourseBodySchema = z
  .object({
    mode: modeSchema,
    ...courseOptions,
    subject: z.string().trim().max(500).optional(),
    sourceText: z.string().max(200000).optional(),
    url: z.string().trim().max(2000).optional(),
    outline: courseOutlineSchema.optional(),
  })
  .strict();

/// One endpoint per teacher-facing method (simpler payloads, no `mode`).
export const fromTopicBodySchema = z
  .object({
    subject: z.string().trim().min(5).max(500),
    ...courseOptions,
    outline: courseOutlineSchema.optional(),
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
export type GenerateOutlineBodyInput = z.infer<typeof generateOutlineBodySchema>;
export type RefineSectionBodyInput = z.infer<typeof refineSectionBodySchema>;
export type GenerateSectionBodyInput = z.infer<typeof generateSectionBodySchema>;
export type ValidateSectionBodyInput = z.infer<typeof validateSectionBodySchema>;
export type ImageSectionBodyInput = z.infer<typeof imageSectionBodySchema>;
export type SearchSectionImagesBodyInput = z.infer<typeof searchSectionImagesBodySchema>;
export type ApplySectionImageBodyInput = z.infer<typeof applySectionImageBodySchema>;
