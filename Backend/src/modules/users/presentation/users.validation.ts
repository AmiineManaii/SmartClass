import { z } from 'zod';
import {
  offsetPaginationQuerySchema,
  sortQuerySchema,
} from '../../../shared/http/pagination/index.js';

const userRoleSchema = z.enum(['TEACHER', 'STUDENT', 'ADMIN']);

export const userSortableFields = ['createdAt', 'email', 'firstName', 'lastName'] as const;

export const listUsersQuerySchema = offsetPaginationQuerySchema
  .extend({
    role: userRoleSchema.optional(),
    search: z.string().trim().min(1).max(100).optional(),
    sort: sortQuerySchema(userSortableFields),
  })
  .strict();

export type ListUsersQueryInput = z.infer<typeof listUsersQuerySchema>;
