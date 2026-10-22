import { Router, type RequestHandler } from 'express';
import type { GroupsController } from './groups.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import { offsetPaginationQuerySchema } from '../../../shared/http/pagination/index.js';
import {
  addMySubjectBodySchema,
  assignStudentsBodySchema,
  assignTeachersBodySchema,
  createGroupBodySchema,
  createVirtualClassroomBodySchema,
  generateInvitationBodySchema,
  groupIdParamsSchema,
  joinClassBodySchema,
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

  // Static routes before '/:id' to avoid route matching conflicts
  router.get('/mine', authenticateMiddleware, controller.listMyGroups);
  router.post('/join', authenticateMiddleware, validate({ body: joinClassBodySchema }), controller.joinClass);
  router.post('/virtual', authenticateMiddleware, validate({ body: createVirtualClassroomBodySchema }), controller.createVirtualClassroom);
  router.get('/departments', authenticateMiddleware, controller.listDepartments);

  // Class group detail and member management accessible to assigned teachers and enrolled students
  router.get('/:id', authenticateMiddleware, validate({ params: groupIdParamsSchema }), controller.getGroup);
  router.post('/:id/leave', authenticateMiddleware, validate({ params: groupIdParamsSchema }), controller.leaveClass);
  // Teachers can declare an additional subject they teach in this class.
  router.post(
    '/:id/subjects',
    authenticateMiddleware,
    validate({ params: groupIdParamsSchema, body: addMySubjectBodySchema }),
    controller.addMySubject,
  );

  // Invitation endpoints (checked in use-cases for ADMIN or assigned TEACHER)
  router.post(
    '/:id/invitations',
    authenticateMiddleware,
    validate({ params: groupIdParamsSchema, body: generateInvitationBodySchema }),
    controller.generateInvitation,
  );
  router.post(
    '/:id/invitations/rotate',
    authenticateMiddleware,
    validate({ params: groupIdParamsSchema, body: generateInvitationBodySchema }),
    controller.rotateInvitation,
  );
  router.post(
    '/:id/invitations/revoke',
    authenticateMiddleware,
    validate({ params: groupIdParamsSchema }),
    controller.revokeInvitation,
  );
  router.get(
    '/:id/invitations/status',
    authenticateMiddleware,
    validate({ params: groupIdParamsSchema }),
    controller.getInvitationStatus,
  );

  // Member viewing and removal (authorized for ADMIN or assigned TEACHER)
  router.get(
    '/:id/members',
    authenticateMiddleware,
    validate({ params: groupIdParamsSchema, query: offsetPaginationQuerySchema }),
    controller.listMembers,
  );
  router.delete(
    '/:id/members',
    authenticateMiddleware,
    validate({ params: groupIdParamsSchema, body: removeMembersBodySchema }),
    controller.removeMembers,
  );

  // Admin-only class management routes
  router.get('/', authenticateMiddleware, requireAdminMiddleware, validate({ query: listGroupsQuerySchema }), controller.listGroups);
  router.post('/', authenticateMiddleware, requireAdminMiddleware, validate({ body: createGroupBodySchema }), controller.createGroup);
  router.patch(
    '/:id',
    authenticateMiddleware,
    requireAdminMiddleware,
    validate({ params: groupIdParamsSchema, body: updateGroupBodySchema }),
    controller.updateGroup,
  );
  router.delete('/:id', authenticateMiddleware, requireAdminMiddleware, validate({ params: groupIdParamsSchema }), controller.deleteGroup);
  router.post(
    '/:id/members',
    authenticateMiddleware,
    requireAdminMiddleware,
    validate({ params: groupIdParamsSchema, body: assignStudentsBodySchema }),
    controller.assignStudents,
  );
  router.post(
    '/:id/teachers',
    authenticateMiddleware,
    requireAdminMiddleware,
    validate({ params: groupIdParamsSchema, body: assignTeachersBodySchema }),
    controller.assignTeachers,
  );
  router.get(
    '/:id/teachers',
    authenticateMiddleware,
    validate({ params: groupIdParamsSchema }),
    controller.listTeachers,
  );
  router.delete(
    '/:id/teachers',
    authenticateMiddleware,
    requireAdminMiddleware,
    validate({ params: groupIdParamsSchema, body: removeTeachersBodySchema }),
    controller.removeTeachers,
  );

  return router;
};
