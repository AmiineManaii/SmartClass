import { Router, type RequestHandler } from 'express';
import type { GroupsController } from './groups.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  assignStudentsBodySchema,
  assignTeachersBodySchema,
  createGroupBodySchema,
  groupIdParamsSchema,
  listGroupsQuerySchema,
} from './groups.validation.js';

export interface GroupsRouterOptions {
  controller: GroupsController;
  authenticateMiddleware: RequestHandler;
  requireAdminMiddleware: RequestHandler;
}

export const createGroupsRouter = (options: GroupsRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireAdminMiddleware } = options;

  router.use(authenticateMiddleware, requireAdminMiddleware);

  router.get('/', validate({ query: listGroupsQuerySchema }), controller.listGroups);

  router.post('/', validate({ body: createGroupBodySchema }), controller.createGroup);

  router.get('/:id', validate({ params: groupIdParamsSchema }), controller.getGroup);

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

  return router;
};
