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
