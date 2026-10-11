import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type { Prisma } from '@prisma/client';
import type {
  ClassGroupDetail,
  ClassGroupSummary,
  ClassLevel,
  ClassStatus,
  TeacherAssignmentView,
} from '../domain/class-group.entity.js';
import type {
  CreateGroupParams,
  GroupMemberUser,
  GroupRepositoryPort,
  ListGroupsQuery,
  TeacherAssignInput,
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
