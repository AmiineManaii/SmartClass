import { describe, it, expect } from 'vitest';
import { UpdateGroupUseCase } from '../../src/modules/groups/application/update-group.use-case.js';
import { ListMyGroupsUseCase } from '../../src/modules/groups/application/list-my-groups.use-case.js';
import { DeleteGroupUseCase } from '../../src/modules/groups/application/delete-group.use-case.js';
import { ListDepartmentsUseCase } from '../../src/modules/groups/application/list-departments.use-case.js';
import { ListGroupMembersUseCase } from '../../src/modules/groups/application/list-group-members.use-case.js';
import { RemoveMembersUseCase } from '../../src/modules/groups/application/remove-members.use-case.js';
import { ListTeacherAssignmentsUseCase } from '../../src/modules/groups/application/list-teacher-assignments.use-case.js';
import { RemoveTeacherAssignmentsUseCase } from '../../src/modules/groups/application/remove-teacher-assignments.use-case.js';
import { GetOverviewUseCase } from '../../src/modules/admin/application/get-overview.use-case.js';
import type {
  ClassGroupDetail,
  ClassLevel,
  ClassStatus,
} from '../../src/modules/groups/domain/class-group.entity.js';
import type {
  GroupRepositoryPort,
  ListGroupsQuery,
  TeacherAssignInput,
  UpdateGroupParams,
} from '../../src/modules/groups/domain/group-repository.port.js';
import type {
  AdminOverview,
  AdminRepositoryPort,
} from '../../src/modules/admin/index.js';

const detail = (overrides: Partial<ClassGroupDetail> = {}): ClassGroupDetail => ({
  id: 'group-1',
  name: 'Informatique 3A',
  level: 'LICENCE' as ClassLevel,
  department: 'Informatique',
  capacity: 35,
  status: 'PUBLISHED' as ClassStatus,
  memberCount: 2,
  teacherCount: 1,
  referent: null,
  createdAt: new Date(),
  description: null,
  forumEnabled: true,
  entSyncEnabled: true,
  updatedAt: new Date(),
  ...overrides,
});

class FakeGroups implements GroupRepositoryPort {
  public groups = new Map<string, ClassGroupDetail>([['group-1', detail()]]);
  public members = new Map<string, string[]>([['group-1', ['s1', 's2']]]);
  public teachers = new Map<string, { teacherId: string; subject: string; weeklyHours: string | null }[]>([
    ['group-1', [{ teacherId: 't1', subject: 'Maths', weeklyHours: '4h/semaine' }]],
  ]);
  public roles = new Map<string, string | null>([
    ['s1', 'STUDENT'],
    ['s2', 'STUDENT'],
    ['t1', 'TEACHER'],
    ['t2', 'TEACHER'],
  ]);

  async listGroups(_query: ListGroupsQuery) {
    return { groups: [], total: 0 };
  }
  async listMyGroups() {
    return [
      {
        ...detail(),
        myRole: 'STUDENT' as const,
        joinedAt: new Date(),
        mySubjects: [],
      },
    ];
  }
  async createGroup() {
    return detail();
  }
  async findGroupDetailById(id: string) {
    return this.groups.get(id) ?? null;
  }
  async updateGroup(id: string, params: UpdateGroupParams) {
    const current = this.groups.get(id);
    if (!current) return null;
    const updated = detail({ ...current, ...(params as Partial<ClassGroupDetail>) });
    this.groups.set(id, updated);
    return updated;
  }
  async deleteGroup(id: string) {
    return this.groups.delete(id);
  }
  async listDepartments() {
    return [{ name: 'Informatique', classCount: 1 }];
  }
  async listGroupMembers(groupId: string, _page: number, limit: number) {
    const ids = (this.members.get(groupId) ?? []).slice(0, limit);
    return {
      members: ids.map((id) => ({
        id,
        email: `${id}@test.com`,
        firstName: 'Test',
        lastName: 'User',
        role: this.roles.get(id) ?? null,
        joinedAt: new Date(),
      })),
      total: (this.members.get(groupId) ?? []).length,
    };
  }
  async removeMembers(groupId: string, userIds: string[]) {
    const remaining = (this.members.get(groupId) ?? []).filter((id) => !userIds.includes(id));
    this.members.set(groupId, remaining);
    return { removed: [...new Set(userIds)], memberCount: remaining.length };
  }
  async listTeacherAssignments(groupId: string) {
    return (this.teachers.get(groupId) ?? []).map((assignment) => ({
      ...assignment,
      firstName: 'Prof',
      lastName: 'Test',
      email: `${assignment.teacherId}@test.com`,
    }));
  }
  async removeTeacherAssignments(groupId: string, teacherIds: string[]) {
    const remaining = (this.teachers.get(groupId) ?? []).filter(
      (assignment) => !teacherIds.includes(assignment.teacherId),
    );
    this.teachers.set(groupId, remaining);
    return { removed: [...new Set(teacherIds)], teacherCount: remaining.length };
  }
  async findUsersByIds(ids: string[]) {
    return ids
      .filter((id) => this.roles.has(id))
      .map((id) => ({ id, role: this.roles.get(id) ?? null }));
  }
  async existingMemberUserIds() {
    return [];
  }
  async addMembers() {
    return { memberCount: 0 };
  }
  async upsertTeacherAssignments(
    _groupId: string,
    assignments: TeacherAssignInput[],
  ) {
    return {
      assigned: assignments.map((assignment) => ({ ...assignment, weeklyHours: null })),
      teacherCount: assignments.length,
    };
  }
}

describe('Unit: ListMyGroupsUseCase', () => {
  it('returns the caller classes with roles', async () => {
    const result = await new ListMyGroupsUseCase(new FakeGroups()).execute('s1');
    expect(result.groups).toHaveLength(1);
    expect(result.groups[0]).toMatchObject({ id: 'group-1', myRole: 'STUDENT' });
  });
});

describe('Unit: UpdateGroupUseCase', () => {
  it('updates name and capacity', async () => {
    const useCase = new UpdateGroupUseCase(new FakeGroups());
    const result = await useCase.execute('group-1', { name: 'Info 3B', capacity: 40 });
    expect(result.group.name).toBe('Info 3B');
    expect(result.group.capacity).toBe(40);
  });

  it('returns 404 for an unknown group', async () => {
    const useCase = new UpdateGroupUseCase(new FakeGroups());
    await expect(useCase.execute('ghost', { name: 'X' })).rejects.toMatchObject({
      statusCode: 404,
    });
  });

  it('rejects a non-teacher referent with 422', async () => {
    const useCase = new UpdateGroupUseCase(new FakeGroups());
    await expect(useCase.execute('group-1', { referentId: 's1' })).rejects.toMatchObject({
      statusCode: 422,
    });
  });

  it('accepts a teacher referent', async () => {
    const repo = new FakeGroups();
    const useCase = new UpdateGroupUseCase(repo);
    const result = await useCase.execute('group-1', { referentId: 't2' });
    expect(result.group.id).toBe('group-1');
  });
});

describe('Unit: DeleteGroupUseCase', () => {
  it('deletes an existing group', async () => {
    const repo = new FakeGroups();
    await new DeleteGroupUseCase(repo).execute('group-1');
    expect(repo.groups.has('group-1')).toBe(false);
  });

  it('returns 404 for an unknown group', async () => {
    await expect(new DeleteGroupUseCase(new FakeGroups()).execute('ghost')).rejects.toMatchObject(
      { statusCode: 404 },
    );
  });
});

describe('Unit: ListDepartmentsUseCase', () => {
  it('returns distinct departments with counts', async () => {
    const result = await new ListDepartmentsUseCase(new FakeGroups()).execute();
    expect(result.departments).toEqual([{ name: 'Informatique', classCount: 1 }]);
  });
});

describe('Unit: group members use-cases', () => {
  it('lists members with total', async () => {
    const result = await new ListGroupMembersUseCase(new FakeGroups()).execute('group-1', 1, 20);
    expect(result.members).toHaveLength(2);
    expect(result.meta.total).toBe(2);
  });

  it('returns 404 for members of an unknown group', async () => {
    await expect(
      new ListGroupMembersUseCase(new FakeGroups()).execute('ghost', 1, 20),
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it('removes members and returns the new count', async () => {
    const result = await new RemoveMembersUseCase(new FakeGroups()).execute('group-1', ['s1']);
    expect(result.removed).toEqual(['s1']);
    expect(result.memberCount).toBe(1);
  });
});

describe('Unit: teacher assignment use-cases', () => {
  it('lists assignments with teacher identity', async () => {
    const result = await new ListTeacherAssignmentsUseCase(new FakeGroups()).execute('group-1');
    expect(result.teacherCount).toBe(1);
    expect(result.assignments[0]).toMatchObject({ teacherId: 't1', subject: 'Maths' });
  });

  it('removes assignments and returns the new count', async () => {
    const result = await new RemoveTeacherAssignmentsUseCase(new FakeGroups()).execute(
      'group-1',
      ['t1'],
    );
    expect(result.removed).toEqual(['t1']);
    expect(result.teacherCount).toBe(0);
  });
});

describe('Unit: GetOverviewUseCase', () => {
  it('computes the month start in UTC and delegates aggregation', async () => {
    let seen: Date | null = null;
    const fake: AdminRepositoryPort = {
      getOverview: async (monthStart: Date) => {
        seen = monthStart;
        return {
          students: { total: 3, newThisMonth: 1 },
          teachers: { total: 2, newThisMonth: 0, activePct: 100 },
          classes: { total: 1, newThisMonth: 0 },
          enrollments: 3,
          frauds: { untreated: 1, inProgress: 0, closed: 0, resolvedThisMonth: 0 },
        } satisfies AdminOverview;
      },
    };
    const result = await new GetOverviewUseCase(fake).execute(new Date(Date.UTC(2026, 9, 15)));
    expect(result.overview.students.total).toBe(3);
    expect(seen?.toISOString()).toBe('2026-10-01T00:00:00.000Z');
  });
});
