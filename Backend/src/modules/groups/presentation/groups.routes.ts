import { Router, type RequestHandler } from 'express';
import type { GroupsController } from './groups.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import { offsetPaginationQuerySchema } from '../../../shared/http/pagination/index.js';
import {
  assignStudentsBodySchema,
  assignTeachersBodySchema,
  createGroupBodySchema,
  groupIdParamsSchema,
  listGroupsQuerySchema,
  removeMembersBodySchema,
  removeTeachersBodySchema,
  updateGroupBodySchema,
} from './groups.validation.js';

export interface GroupsRouterOptions {
  controller: GroupsController;
  authenticateMiddleware: RequestHandler;
  requireAdminMiddleware: RequestHandler;
}

export const createGroupsRouter = (options: GroupsRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireAdminMiddleware } = options;

  // NOTE: static segment before '/:id' AND before the admin guard below,
  // so 'mine' never matches the uuid param and any authenticated user
  // (student/teacher, not just admin) can read their own classes.
  router.get('/mine', authenticateMiddleware, controller.listMyGroups);

  router.use(authenticateMiddleware, requireAdminMiddleware);

  router.get('/', validate({ query: listGroupsQuerySchema }), controller.listGroups);

  router.post('/', validate({ body: createGroupBodySchema }), controller.createGroup);

  // NOTE: static segment before '/:id' so 'departments' never matches
  // the uuid param (same rationale as '/me/role' in the users module).
  router.get('/departments', controller.listDepartments);

  router.get('/:id', validate({ params: groupIdParamsSchema }), controller.getGroup);

  router.patch(
    '/:id',
    validate({ params: groupIdParamsSchema, body: updateGroupBodySchema }),
    controller.updateGroup,
  );

  router.delete('/:id', validate({ params: groupIdParamsSchema }), controller.deleteGroup);

  router.get(
    '/:id/members',
    validate({ params: groupIdParamsSchema, query: offsetPaginationQuerySchema }),
    controller.listMembers,
  );

  router.delete(
    '/:id/members',
    validate({ params: groupIdParamsSchema, body: removeMembersBodySchema }),
    controller.removeMembers,
  );

  router.post(
    '/:id/members',
    validate({ params: groupIdParamsSchema, body: assignStudentsBodySchema }),
    controller.assignStudents,
  );

  router.post(
    '/:id/teachers',
    validate({ params: groupIdParamsSchema, body: assignTeachersBodySchema }),
    controller.assignTeachers,
  );

  router.get(
    '/:id/teachers',
    validate({ params: groupIdParamsSchema }),
    controller.listTeachers,
  );

  router.delete(
    '/:id/teachers',
    validate({ params: groupIdParamsSchema, body: removeTeachersBodySchema }),
    controller.removeTeachers,
  );

  return router;
};
