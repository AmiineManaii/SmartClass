import { describe, it, expect } from 'vitest';
import { ListUsersUseCase } from '../../src/modules/users/application/list-users.use-case.js';
import type {
  ListUsersQuery,
  UserDirectoryPort,
} from '../../src/modules/users/domain/user-directory.port.js';
import { AssignStudentsUseCase } from '../../src/modules/groups/application/assign-students.use-case.js';
import { AssignTeachersUseCase } from '../../src/modules/groups/application/assign-teachers.use-case.js';
import type {
  GroupRepositoryPort,
  ListGroupsQuery,
} from '../../src/modules/groups/domain/group-repository.port.js';
import type { ClassGroupDetail } from '../../src/modules/groups/domain/class-group.entity.js';
import { UpdateFraudReportUseCase } from '../../src/modules/exams/application/update-fraud-report.use-case.js';
import type { FraudRepositoryPort } from '../../src/modules/exams/domain/fraud-repository.port.js';
import type { FraudReportView } from '../../src/modules/exams/domain/fraud-report.entity.js';
import { startOfWeekMonday } from '../../src/modules/videoconference/index.js';
import { AppError } from '../../src/shared/errors/app-error.js';
import { ErrorCodes } from '../../src/shared/errors/error-codes.js';

const groupDetail = (overrides: Partial<ClassGroupDetail> = {}): ClassGroupDetail => ({
  id: 'group-1',
  name: 'Informatique 3A',
  level: 'LICENCE',
  department: 'Informatique',
  capacity: 35,
  status: 'PUBLISHED',
  memberCount: 0,
  teacherCount: 0,
  referent: null,
  createdAt: new Date('2026-10-01T00:00:00.000Z'),
  description: null,
  forumEnabled: true,
  entSyncEnabled: true,
  updatedAt: new Date('2026-10-01T00:00:00.000Z'),
  ...overrides,
});

const reportView = (overrides: Partial<FraudReportView> = {}): FraudReportView => ({
  id: 'report-1',
  title: 'Suspicion de Fraude',
  context: null,
  severity: 'HIGH',
  status: 'UNTREATED',
  student: null,
  classGroup: null,
  findings: [],
  reason: null,
  resolution: null,
  occurredAt: new Date('2026-10-11T10:45:00.000Z'),
  createdAt: new Date('2026-10-11T10:46:00.000Z'),
  ...overrides,
});

describe('Unit: ListUsersUseCase', () => {
  it('builds offset meta from the repository total', async () => {
    const fake: UserDirectoryPort = {
      listUsers: async (_query: ListUsersQuery) => ({ users: [], total: 42 }),
    };
    const useCase = new ListUsersUseCase(fake);

    const result = await useCase.execute({
      page: 2,
      limit: 20,
      sortField: 'createdAt',
      sortOrder: 'desc',
    });

    expect(result.meta).toMatchObject({
      page: 2,
      limit: 20,
      total: 42,
      totalPages: 3,
      hasNextPage: true,
      hasPreviousPage: true,
    });
  });
});

describe('Unit: AssignStudentsUseCase', () => {
  const baseRepo = (overrides: Partial<GroupRepositoryPort> = {}): GroupRepositoryPort => ({
    listGroups: async (_query: ListGroupsQuery) => ({ groups: [], total: 0 }),
    createGroup: async () => groupDetail(),
    findGroupDetailById: async () => groupDetail(),
    findUsersByIds: async () => [],
    existingMemberUserIds: async () => [],
    addMembers: async () => ({ memberCount: 1 }),
    upsertTeacherAssignments: async () => ({ assigned: [], teacherCount: 0 }),
    ...overrides,
  });

  it('throws NOT_FOUND when the group does not exist', async () => {
    const useCase = new AssignStudentsUseCase(baseRepo({ findGroupDetailById: async () => null }));

    await expect(useCase.execute('missing', ['u1'])).rejects.toMatchObject({
      statusCode: 404,
    });
  });

  it('throws NOT_FOUND when a user id is unknown', async () => {
    const useCase = new AssignStudentsUseCase(baseRepo());

    await expect(useCase.execute('group-1', ['ghost'])).rejects.toMatchObject({
      statusCode: 404,
    });
  });

  it('throws VALIDATION_ERROR when a user is not a STUDENT', async () => {
    const useCase = new AssignStudentsUseCase(
      baseRepo({
        findUsersByIds: async () => [{ id: 't1', role: 'TEACHER' }],
      }),
    );

    await expect(useCase.execute('group-1', ['t1'])).rejects.toMatchObject({
      code: ErrorCodes.VALIDATION_ERROR,
    });
  });

  it('throws ROLE_ALREADY_ASSIGNED on duplicate membership', async () => {
    const useCase = new AssignStudentsUseCase(
      baseRepo({
        findUsersByIds: async () => [{ id: 's1', role: 'STUDENT' }],
        existingMemberUserIds: async () => ['s1'],
      }),
    );

    await expect(useCase.execute('group-1', ['s1'])).rejects.toMatchObject({
      code: ErrorCodes.ROLE_ALREADY_ASSIGNED,
    });
  });

  it('returns added ids and the new member count on success', async () => {
    const useCase = new AssignStudentsUseCase(
      baseRepo({
        findUsersByIds: async () => [{ id: 's1', role: 'STUDENT' }],
        addMembers: async () => ({ memberCount: 18 }),
      }),
    );

    await expect(useCase.execute('group-1', ['s1'])).resolves.toEqual({
      classGroupId: 'group-1',
      added: ['s1'],
      memberCount: 18,
    });
  });
});

describe('Unit: AssignTeachersUseCase', () => {
  it('throws VALIDATION_ERROR when a user is not a TEACHER', async () => {
    const repo: GroupRepositoryPort = {
      listGroups: async (_query: ListGroupsQuery) => ({ groups: [], total: 0 }),
      createGroup: async () => groupDetail(),
      findGroupDetailById: async () => groupDetail(),
      findUsersByIds: async () => [{ id: 's1', role: 'STUDENT' }],
      existingMemberUserIds: async () => [],
      addMembers: async () => ({ memberCount: 0 }),
      upsertTeacherAssignments: async () => ({ assigned: [], teacherCount: 0 }),
    };
    const useCase = new AssignTeachersUseCase(repo);

    await expect(
      useCase.execute('group-1', [{ teacherId: 's1', subject: 'Maths' }]),
    ).rejects.toMatchObject({ code: ErrorCodes.VALIDATION_ERROR });
  });
});

describe('Unit: UpdateFraudReportUseCase', () => {
  const baseRepo = (overrides: Partial<FraudRepositoryPort> = {}): FraudRepositoryPort => ({
    listFraudReports: async () => ({ reports: [], nextCursor: null, hasMore: false }),
    fraudSummary: async () => ({ untreated: 0, inProgress: 0, closed: 0, resolvedThisMonth: 0 }),
    findFraudReportById: async () => reportView(),
    updateFraudReportStatus: async (_id, status) => reportView({ status }),
    ...overrides,
  });

  it('throws NOT_FOUND for an unknown report', async () => {
    const useCase = new UpdateFraudReportUseCase(
      baseRepo({ findFraudReportById: async () => null }),
    );

    await expect(useCase.execute('missing', 'CLOSED')).rejects.toMatchObject({
      statusCode: 404,
    });
  });

  it('refuses to reopen a CLOSED report with CONFLICT', async () => {
    const useCase = new UpdateFraudReportUseCase(
      baseRepo({
        findFraudReportById: async () => reportView({ status: 'CLOSED' }),
      }),
    );

    const error = await useCase.execute('report-1', 'IN_PROGRESS').catch((err: unknown) => err);
    expect(error).toBeInstanceOf(AppError);
    expect((error as AppError).code).toBe(ErrorCodes.CONFLICT);
  });

  it('transitions an untreated report to IN_PROGRESS', async () => {
    const useCase = new UpdateFraudReportUseCase(baseRepo());

    await expect(useCase.execute('report-1', 'IN_PROGRESS')).resolves.toMatchObject({
      report: { status: 'IN_PROGRESS' },
    });
  });
});

describe('Unit: startOfWeekMonday', () => {
  it('returns the same day for a Monday', () => {
    expect(startOfWeekMonday(new Date('2025-05-12T10:00:00.000Z')).toISOString()).toBe(
      '2025-05-12T00:00:00.000Z',
    );
  });

  it('returns the previous Monday for a Sunday', () => {
    expect(startOfWeekMonday(new Date('2025-05-18T10:00:00.000Z')).toISOString()).toBe(
      '2025-05-12T00:00:00.000Z',
    );
  });

  it('returns the Monday of the same week for a Wednesday', () => {
    expect(startOfWeekMonday(new Date('2025-05-14T10:00:00.000Z')).toISOString()).toBe(
      '2025-05-12T00:00:00.000Z',
    );
  });
});
