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

export const setMyRoleBodySchema = z
  .object({
    // ADMIN passes validation so the use-case rejects it with a documented
    // 403 (rather than a bare 422): Zod is not the security boundary.
    role: z.enum(['TEACHER', 'STUDENT', 'ADMIN']),
  })
  .strict();

export const userIdParamsSchema = z
  .object({ id: z.string().uuid() })
  .strict();

export const setUserRoleBodySchema = z
  .object({
    role: z.enum(['TEACHER', 'STUDENT', 'ADMIN']),
  })
  .strict();

export type SetMyRoleBodyInput = z.infer<typeof setMyRoleBodySchema>;
export type SetUserRoleBodyInput = z.infer<typeof setUserRoleBodySchema>;

export type ListUsersQueryInput = z.infer<typeof listUsersQuerySchema>;
