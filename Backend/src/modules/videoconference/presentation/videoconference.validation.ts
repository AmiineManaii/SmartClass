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

export const timetableQuerySchema = z
  .object({
    classGroupId: uuidSchema,
    weekStart: isoDateSchema.optional(),
  })
  .strict();

export type TimetableQueryInput = z.infer<typeof timetableQuerySchema>;
