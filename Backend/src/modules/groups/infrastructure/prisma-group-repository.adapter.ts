import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import { Prisma } from '@prisma/client';
import type {
  ClassGroupDetail,
  ClassGroupSummary,
  ClassLevel,
  ClassStatus,
  TeacherAssignmentView,
} from '../domain/class-group.entity.js';
import type {
  CreateGroupParams,
  DepartmentView,
  GroupMemberUser,
  GroupMemberView,
  GroupRepositoryPort,
  ListGroupsQuery,
  MyClassGroup,
  TeacherAssignInput,
  TeacherAssignmentDetail,
  UpdateGroupParams,
} from '../domain/group-repository.port.js';

interface RawGroupRow {
  id: string;
  name: string;
  level: string;
  department: string | null;
  capacity: number;
  description: string | null;
  forumEnabled: boolean;
  entSyncEnabled: boolean;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  referent: { id: string; firstName: string; lastName: string } | null;
  _count: { members: number; teachers: number };
}

export class PrismaGroupRepositoryAdapter implements GroupRepositoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  private toSummary(raw: RawGroupRow): ClassGroupSummary {
    return {
      id: raw.id,
      name: raw.name,
      level: raw.level as ClassLevel,
      department: raw.department,
      capacity: raw.capacity,
      status: raw.status as ClassStatus,
      memberCount: raw._count.members,
      teacherCount: raw._count.teachers,
      referent: raw.referent
        ? {
            id: raw.referent.id,
            firstName: raw.referent.firstName,
            lastName: raw.referent.lastName,
          }
        : null,
      createdAt: raw.createdAt,
    };
  }

  private toDetail(
    raw: RawGroupRow & {
      description: string | null;
      forumEnabled: boolean;
      entSyncEnabled: boolean;
      updatedAt: Date;
    },
  ): ClassGroupDetail {
    return {
      ...this.toSummary(raw),
      description: raw.description,
      forumEnabled: raw.forumEnabled,
      entSyncEnabled: raw.entSyncEnabled,
      updatedAt: raw.updatedAt,
    };
  }

  private readonly detailSelect = {
    id: true,
    name: true,
    level: true,
    department: true,
    capacity: true,
    description: true,
    forumEnabled: true,
    entSyncEnabled: true,
    status: true,
    createdAt: true,
    updatedAt: true,
    referent: { select: { id: true, firstName: true, lastName: true } },
    _count: { select: { members: true, teachers: true } },
  } as const;

  public async listGroups(
    query: ListGroupsQuery,
  ): Promise<{ groups: ClassGroupSummary[]; total: number }> {
    const where: Prisma.ClassGroupWhereInput = {};
    if (query.level) {
      where.level = query.level;
    }
    if (query.search) {
      where.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { department: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const skip = (query.page - 1) * query.limit;
    const orderBy: Prisma.ClassGroupOrderByWithRelationInput = {
      [query.sortField]: query.sortOrder,
    };

    const [rows, total] = await Promise.all([
      this.prisma.classGroup.findMany({
        where,
        orderBy: [orderBy, { id: 'asc' }],
        skip,
        take: query.limit,
        select: this.detailSelect,
      }),
      this.prisma.classGroup.count({ where }),
    ]);

    return { groups: rows.map((row) => this.toSummary(row)), total };
  }

  public async listMyGroups(userId: string): Promise<MyClassGroup[]> {
    const [memberships, assignments, referents] = await Promise.all([
      this.prisma.groupMember.findMany({
        where: { userId },
        orderBy: { joinedAt: 'asc' },
        select: { joinedAt: true, classGroup: { select: this.detailSelect } },
      }),
      this.prisma.teacherAssignment.findMany({
        where: { teacherId: userId },
        orderBy: { assignedAt: 'asc' },
        select: {
          assignedAt: true,
          subject: true,
          classGroup: { select: this.detailSelect },
        },
      }),
      this.prisma.classGroup.findMany({
        where: { referentId: userId },
        orderBy: { createdAt: 'asc' },
        select: this.detailSelect,
      }),
    ]);

    const byId = new Map<string, MyClassGroup>();
    for (const membership of memberships) {
      byId.set(membership.classGroup.id, {
        ...this.toSummary(membership.classGroup),
        myRole: 'STUDENT',
        joinedAt: membership.joinedAt,
        mySubjects: [],
      });
    }
    for (const assignment of assignments) {
      const existing = byId.get(assignment.classGroup.id);
      if (existing) {
        existing.myRole = 'TEACHER';
        existing.joinedAt ??= assignment.assignedAt;
        if (!existing.mySubjects.includes(assignment.subject)) {
          existing.mySubjects.push(assignment.subject);
        }
      } else {
        byId.set(assignment.classGroup.id, {
          ...this.toSummary(assignment.classGroup),
          myRole: 'TEACHER',
          joinedAt: assignment.assignedAt,
          mySubjects: [assignment.subject],
        });
      }
    }
    for (const referent of referents) {
      const existing = byId.get(referent.id);
      if (existing) {
        existing.myRole = 'REFERENT';
      } else {
        byId.set(referent.id, {
          ...this.toSummary(referent),
          myRole: 'REFERENT',
          joinedAt: null,
          mySubjects: [],
        });
      }
    }
    return [...byId.values()];
  }

  public async createGroup(params: CreateGroupParams): Promise<ClassGroupDetail> {
    const row = await this.prisma.classGroup.create({
      data: {
        name: params.name,
        level: params.level,
        department: params.department ?? null,
        capacity: params.capacity,
        description: params.description ?? null,
        forumEnabled: params.forumEnabled,
        entSyncEnabled: params.entSyncEnabled,
        status: params.status,
        referentId: params.referentId ?? null,
      },
      select: this.detailSelect,
    });

    return this.toDetail(row);
  }

  public async findGroupDetailById(id: string): Promise<ClassGroupDetail | null> {
    const row = await this.prisma.classGroup.findUnique({
      where: { id },
      select: this.detailSelect,
    });
    if (!row) return null;

    return this.toDetail(row);
  }

  public async updateGroup(
    id: string,
    params: UpdateGroupParams,
  ): Promise<ClassGroupDetail | null> {
    const data: {
      name?: string;
      level?: 'LICENCE' | 'MASTER' | 'DOCTORAT';
      department?: string | null;
      capacity?: number;
      description?: string | null;
      forumEnabled?: boolean;
      entSyncEnabled?: boolean;
      status?: 'DRAFT' | 'PUBLISHED';
      referentId?: string | null;
    } = {};
    if (params.name !== undefined) data.name = params.name;
    if (params.level !== undefined) data.level = params.level;
    if (params.department !== undefined) data.department = params.department;
    if (params.capacity !== undefined) data.capacity = params.capacity;
    if (params.description !== undefined) data.description = params.description;
    if (params.forumEnabled !== undefined) data.forumEnabled = params.forumEnabled;
    if (params.entSyncEnabled !== undefined) data.entSyncEnabled = params.entSyncEnabled;
    if (params.status !== undefined) data.status = params.status;
    if (params.referentId !== undefined) data.referentId = params.referentId;

    try {
      const row = await this.prisma.classGroup.update({
        where: { id },
        data,
        select: this.detailSelect,
      });
      return this.toDetail(row);
    } catch (error) {
      // Unknown id (P2025) — the use-case maps a null to 404.
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') {
        return null;
      }
      throw error;
    }
  }

  public async deleteGroup(id: string): Promise<boolean> {
    try {
      await this.prisma.classGroup.delete({ where: { id } });
      return true;
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') {
        return false;
      }
      throw error;
    }
  }

  public async listDepartments(): Promise<DepartmentView[]> {
    const groups = await this.prisma.classGroup.groupBy({
      by: ['department'],
      where: { department: { not: null } },
      _count: { department: true },
    });
    return groups
      .filter((group) => group.department !== null && group.department.trim() !== '')
      .map((group) => ({
        name: group.department as string,
        classCount: group._count.department,
      }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  public async listGroupMembers(
    groupId: string,
    page: number,
    limit: number,
  ): Promise<{ members: GroupMemberView[]; total: number }> {
    const skip = (page - 1) * limit;
    const [rows, total] = await Promise.all([
      this.prisma.groupMember.findMany({
        where: { classGroupId: groupId },
        orderBy: [{ joinedAt: 'asc' }, { userId: 'asc' }],
        skip,
        take: limit,
        select: {
          joinedAt: true,
          user: {
            select: { id: true, email: true, firstName: true, lastName: true, role: true },
          },
        },
      }),
      this.prisma.groupMember.count({ where: { classGroupId: groupId } }),
    ]);
    return {
      members: rows.map((row) => ({
        id: row.user.id,
        email: row.user.email,
        firstName: row.user.firstName,
        lastName: row.user.lastName,
        role: row.user.role,
        joinedAt: row.joinedAt,
      })),
      total,
    };
  }

  public async removeMembers(
    groupId: string,
    userIds: string[],
  ): Promise<{ removed: string[]; memberCount: number }> {
    const uniqueIds = [...new Set(userIds)];
    if (uniqueIds.length > 0) {
      await this.prisma.groupMember.deleteMany({
        where: { classGroupId: groupId, userId: { in: uniqueIds } },
      });
    }
    const memberCount = await this.prisma.groupMember.count({
      where: { classGroupId: groupId },
    });
    return { removed: uniqueIds, memberCount };
  }

  public async listTeacherAssignments(groupId: string): Promise<TeacherAssignmentDetail[]> {
    const rows = await this.prisma.teacherAssignment.findMany({
      where: { classGroupId: groupId },
      orderBy: { assignedAt: 'asc' },
      select: {
        teacherId: true,
        subject: true,
        weeklyHours: true,
        teacher: { select: { firstName: true, lastName: true, email: true } },
      },
    });
    return rows.map((row) => ({
      teacherId: row.teacherId,
      firstName: row.teacher.firstName,
      lastName: row.teacher.lastName,
      email: row.teacher.email,
      subject: row.subject,
      weeklyHours: row.weeklyHours,
    }));
  }

  public async removeTeacherAssignments(
    groupId: string,
    teacherIds: string[],
  ): Promise<{ removed: string[]; teacherCount: number }> {
    const uniqueIds = [...new Set(teacherIds)];
    if (uniqueIds.length > 0) {
      await this.prisma.teacherAssignment.deleteMany({
        where: { classGroupId: groupId, teacherId: { in: uniqueIds } },
      });
    }
    const teacherCount = await this.prisma.teacherAssignment.count({
      where: { classGroupId: groupId },
    });
    return { removed: uniqueIds, teacherCount };
  }

  public async findUsersByIds(ids: string[]): Promise<GroupMemberUser[]> {
    if (ids.length === 0) return [];
    const rows = await this.prisma.user.findMany({
      where: { id: { in: [...new Set(ids)] } },
      select: { id: true, role: true },
    });

    return rows.map((row) => ({ id: row.id, role: row.role }));
  }

  public async existingMemberUserIds(groupId: string, userIds: string[]): Promise<string[]> {
    if (userIds.length === 0) return [];
    const rows = await this.prisma.groupMember.findMany({
      where: { classGroupId: groupId, userId: { in: [...new Set(userIds)] } },
      select: { userId: true },
    });

    return rows.map((row) => row.userId);
  }

  public async addMembers(groupId: string, userIds: string[]): Promise<{ memberCount: number }> {
    const uniqueIds = [...new Set(userIds)];
    await this.prisma.$transaction(
      uniqueIds.map((userId) =>
        this.prisma.groupMember.create({
          data: { classGroupId: groupId, userId },
        }),
      ),
    );

    const memberCount = await this.prisma.groupMember.count({
      where: { classGroupId: groupId },
    });

    return { memberCount };
  }

  public async upsertTeacherAssignments(
    groupId: string,
    assignments: TeacherAssignInput[],
  ): Promise<{ assigned: TeacherAssignmentView[]; teacherCount: number }> {
    const seen = new Set<string>();
    const unique = assignments.filter((assignment) => {
      if (seen.has(assignment.teacherId)) return false;
      seen.add(assignment.teacherId);
      return true;
    });

    await this.prisma.$transaction(
      unique.map((assignment) =>
        this.prisma.teacherAssignment.upsert({
          where: {
            classGroupId_teacherId: { classGroupId: groupId, teacherId: assignment.teacherId },
          },
          update: {
            subject: assignment.subject,
            weeklyHours: assignment.weeklyHours ?? null,
          },
          create: {
            classGroupId: groupId,
            teacherId: assignment.teacherId,
            subject: assignment.subject,
            weeklyHours: assignment.weeklyHours ?? null,
          },
        }),
      ),
    );

    const teacherCount = await this.prisma.teacherAssignment.count({
      where: { classGroupId: groupId },
    });

    return {
      assigned: unique.map((assignment) => ({
        teacherId: assignment.teacherId,
        subject: assignment.subject,
        weeklyHours: assignment.weeklyHours ?? null,
      })),
      teacherCount,
    };
  }
}
