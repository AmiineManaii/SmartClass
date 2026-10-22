import { z } from 'zod';
import {
  offsetPaginationQuerySchema,
  sortQuerySchema,
} from '../../../shared/http/pagination/index.js';

const uuidSchema = z.string().uuid();

const classLevelSchema = z.enum(['LICENCE', 'MASTER', 'DOCTORAT']);

const classStatusSchema = z.enum(['DRAFT', 'PUBLISHED', 'ARCHIVED']);

export const groupSortableFields = ['createdAt', 'name', 'capacity'] as const;

export const listGroupsQuerySchema = offsetPaginationQuerySchema
  .extend({
    level: classLevelSchema.optional(),
    search: z.string().trim().min(1).max(100).optional(),
    sort: sortQuerySchema(groupSortableFields),
  })
  .strict();

export const groupIdParamsSchema = z.object({ id: uuidSchema }).strict();

export const createGroupBodySchema = z
  .object({
    name: z.string().trim().min(2).max(100),
    level: classLevelSchema,
    department: z.string().trim().max(100).nullable().optional(),
    academicYear: z.string().trim().max(20).nullable().optional(),
    capacity: z.number().int().min(1).max(500),
    description: z.string().trim().max(300).nullable().optional(),
    forumEnabled: z.boolean().default(true),
    entSyncEnabled: z.boolean().default(true),
    status: classStatusSchema.default('PUBLISHED'),
    referentId: uuidSchema.nullable().optional(),
  })
  .strict();

export const updateGroupBodySchema = z
  .object({
    name: z.string().trim().min(2).max(100).optional(),
    level: classLevelSchema.optional(),
    department: z.string().trim().max(100).nullable().optional(),
    academicYear: z.string().trim().max(20).nullable().optional(),
    capacity: z.number().int().min(1).max(500).optional(),
    description: z.string().trim().max(300).nullable().optional(),
    forumEnabled: z.boolean().optional(),
    entSyncEnabled: z.boolean().optional(),
    status: classStatusSchema.optional(),
    referentId: uuidSchema.nullable().optional(),
  })
  .strict();

export const generateInvitationBodySchema = z
  .object({
    expiresInHours: z.number().int().min(1).max(720).nullable().optional(),
    maxUses: z.number().int().min(1).max(1000).nullable().optional(),
  })
  .strict();

export const joinClassBodySchema = z
  .object({
    code: z.string().trim().min(3).max(30),
  })
  .strict();

export const createVirtualClassroomBodySchema = z
  .object({
    name: z.string().trim().min(2).max(100),
    capacity: z.number().int().min(1).max(500).optional(),
    description: z.string().trim().max(300).nullable().optional(),
  })
  .strict();

export const removeMembersBodySchema = z
  .object({
    studentIds: z.array(uuidSchema).min(1).max(100),
  })
  .strict();

export const removeTeachersBodySchema = z
  .object({
    teacherIds: z.array(uuidSchema).min(1).max(100),
  })
  .strict();

export const assignStudentsBodySchema = z
  .object({
    studentIds: z.array(uuidSchema).min(1).max(100),
  })
  .strict();

export const assignTeachersBodySchema = z
  .object({
    assignments: z
      .array(
        z
          .object({
            teacherId: uuidSchema,
            subject: z.string().trim().min(2).max(100),
            weeklyHours: z.string().trim().max(50).nullable().optional(),
          })
          .strict(),
      )
      .min(1)
      .max(50),
  })
  .strict();

export const addMySubjectBodySchema = z
  .object({
    subject: z.string().trim().min(2).max(100),
    weeklyHours: z.string().trim().max(50).nullable().optional(),
  })
  .strict();

export type ListGroupsQueryInput = z.infer<typeof listGroupsQuerySchema>;
export type CreateGroupBodyInput = z.infer<typeof createGroupBodySchema>;
export type UpdateGroupBodyInput = z.infer<typeof updateGroupBodySchema>;
export type GenerateInvitationBodyInput = z.infer<typeof generateInvitationBodySchema>;
export type JoinClassBodyInput = z.infer<typeof joinClassBodySchema>;
export type CreateVirtualClassroomBodyInput = z.infer<typeof createVirtualClassroomBodySchema>;
export type AssignStudentsBodyInput = z.infer<typeof assignStudentsBodySchema>;
export type AssignTeachersBodyInput = z.infer<typeof assignTeachersBodySchema>;
export type AddMySubjectBodyInput = z.infer<typeof addMySubjectBodySchema>;
export type RemoveMembersBodyInput = z.infer<typeof removeMembersBodySchema>;
export type RemoveTeachersBodyInput = z.infer<typeof removeTeachersBodySchema>;
