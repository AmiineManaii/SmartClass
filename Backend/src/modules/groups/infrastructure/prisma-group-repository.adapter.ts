import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import { Prisma } from '@prisma/client';
import { BadRequestError, ConflictError, NotFoundError } from '../../../shared/errors/app-error.js';
import type {
  ClassGroupDetail,
  ClassGroupSummary,
  ClassInvitationView,
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
  academicYear?: string | null;
  capacity: number;
  description: string | null;
  forumEnabled: boolean;
  entSyncEnabled: boolean;
  status: string;
  isVirtual?: boolean;
  ownerId?: string | null;
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
      academicYear: raw.academicYear ?? null,
      capacity: raw.capacity,
      status: raw.status as ClassStatus,
      isVirtual: raw.isVirtual ?? false,
      ownerId: raw.ownerId ?? null,
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
    academicYear: true,
    capacity: true,
    description: true,
    forumEnabled: true,
    entSyncEnabled: true,
    status: true,
    isVirtual: true,
    ownerId: true,
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
    const [memberships, assignments, referents, owned] = await Promise.all([
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
      this.prisma.classGroup.findMany({
        where: { ownerId: userId },
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
    for (const own of owned) {
      const existing = byId.get(own.id);
      if (existing) {
        existing.myRole = 'TEACHER';
      } else {
        byId.set(own.id, {
          ...this.toSummary(own),
          myRole: 'TEACHER',
          joinedAt: null,
          mySubjects: ['Enseignement virtuel'],
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
        academicYear: params.academicYear ?? null,
        capacity: params.capacity,
        description: params.description ?? null,
        forumEnabled: params.forumEnabled,
        entSyncEnabled: params.entSyncEnabled,
        status: params.status,
        isVirtual: params.isVirtual ?? false,
        ownerId: params.ownerId ?? null,
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
      academicYear?: string | null;
      capacity?: number;
      description?: string | null;
      forumEnabled?: boolean;
      entSyncEnabled?: boolean;
      status?: ClassStatus;
      referentId?: string | null;
    } = {};
    if (params.name !== undefined) data.name = params.name;
    if (params.level !== undefined) data.level = params.level;
    if (params.department !== undefined) data.department = params.department;
    if (params.academicYear !== undefined) data.academicYear = params.academicYear;
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

  public async isTeacherAuthorizedForGroup(groupId: string, teacherId: string): Promise<boolean> {
    const group = await this.prisma.classGroup.findUnique({
      where: { id: groupId },
      select: { referentId: true, ownerId: true },
    });
    if (!group) return false;
    if (group.referentId === teacherId || group.ownerId === teacherId) return true;

    const assignment = await this.prisma.teacherAssignment.findUnique({
      where: { classGroupId_teacherId: { classGroupId: groupId, teacherId } },
    });
    return !!assignment;
  }

  public async findUserClassMembership(
    groupId: string,
    userId: string,
  ): Promise<{ isMember: boolean; isTeacher: boolean; isReferent: boolean; isOwner: boolean }> {
    const group = await this.prisma.classGroup.findUnique({
      where: { id: groupId },
      select: { referentId: true, ownerId: true },
    });
    const [member, teacher] = await Promise.all([
      this.prisma.groupMember.findUnique({
        where: { classGroupId_userId: { classGroupId: groupId, userId } },
      }),
      this.prisma.teacherAssignment.findUnique({
        where: { classGroupId_teacherId: { classGroupId: groupId, teacherId: userId } },
      }),
    ]);
    return {
      isMember: !!member,
      isTeacher: !!teacher,
      isReferent: group?.referentId === userId,
      isOwner: group?.ownerId === userId,
    };
  }

  public async createInvitation(params: {
    groupId: string;
    creatorId: string;
    codeHash: string;
    codePrefix?: string | null;
    expiresAt?: Date | null;
    maxUses?: number | null;
  }): Promise<ClassInvitationView> {
    await this.prisma.classInvitation.updateMany({
      where: { classGroupId: params.groupId, status: 'ACTIVE' },
      data: { status: 'REVOKED' },
    });

    const record = await this.prisma.classInvitation.create({
      data: {
        classGroupId: params.groupId,
        creatorId: params.creatorId,
        codeHash: params.codeHash,
        codePrefix: params.codePrefix ?? null,
        status: 'ACTIVE',
        expiresAt: params.expiresAt ?? null,
        maxUses: params.maxUses ?? null,
      },
    });

    return {
      id: record.id,
      classGroupId: record.classGroupId,
      codePrefix: record.codePrefix,
      creatorId: record.creatorId,
      status: record.status as any,
      expiresAt: record.expiresAt,
      maxUses: record.maxUses,
      usedCount: record.usedCount,
      createdAt: record.createdAt,
    };
  }

  public async rotateInvitation(params: {
    groupId: string;
    creatorId: string;
    codeHash: string;
    codePrefix?: string | null;
    expiresAt?: Date | null;
    maxUses?: number | null;
  }): Promise<ClassInvitationView> {
    return this.createInvitation(params);
  }

  public async revokeInvitation(groupId: string): Promise<boolean> {
    const res = await this.prisma.classInvitation.updateMany({
      where: { classGroupId: groupId, status: 'ACTIVE' },
      data: { status: 'REVOKED' },
    });
    return res.count > 0;
  }

  public async findActiveInvitationByGroupId(groupId: string): Promise<ClassInvitationView | null> {
    const record = await this.prisma.classInvitation.findFirst({
      where: { classGroupId: groupId, status: 'ACTIVE' },
      orderBy: { createdAt: 'desc' },
    });
    if (!record) return null;
    if (record.expiresAt && record.expiresAt < new Date()) {
      await this.prisma.classInvitation.update({
        where: { id: record.id },
        data: { status: 'EXPIRED' },
      });
      return {
        id: record.id,
        classGroupId: record.classGroupId,
        codePrefix: record.codePrefix,
        creatorId: record.creatorId,
        status: 'EXPIRED',
        expiresAt: record.expiresAt,
        maxUses: record.maxUses,
        usedCount: record.usedCount,
        createdAt: record.createdAt,
      };
    }
    return {
      id: record.id,
      classGroupId: record.classGroupId,
      codePrefix: record.codePrefix,
      creatorId: record.creatorId,
      status: record.status as any,
      expiresAt: record.expiresAt,
      maxUses: record.maxUses,
      usedCount: record.usedCount,
      createdAt: record.createdAt,
    };
  }

  public async findInvitationByCodeHash(
    codeHash: string,
  ): Promise<(ClassInvitationView & { classGroup: ClassGroupSummary }) | null> {
    const record = await this.prisma.classInvitation.findUnique({
      where: { codeHash },
      include: {
        classGroup: {
          select: this.detailSelect,
        },
      },
    });
    if (!record) return null;
    return {
      id: record.id,
      classGroupId: record.classGroupId,
      codePrefix: record.codePrefix,
      creatorId: record.creatorId,
      status: record.status as any,
      expiresAt: record.expiresAt,
      maxUses: record.maxUses,
      usedCount: record.usedCount,
      createdAt: record.createdAt,
      classGroup: this.toSummary(record.classGroup as any),
    };
  }

  public async joinGroupWithInvitation(
    invitationId: string,
    groupId: string,
    studentId: string,
  ): Promise<{ classGroup: ClassGroupDetail }> {
    return await this.prisma.$transaction(async (tx) => {
      const group = await tx.classGroup.findUnique({
        where: { id: groupId },
        select: this.detailSelect,
      });
      if (!group) {
        throw new NotFoundError('Class group not found');
      }
      if (group.status !== 'PUBLISHED') {
        throw new BadRequestError('Class is not open for enrollment');
      }
      if (group._count.members >= group.capacity) {
        throw new ConflictError('Class has reached its maximum capacity');
      }

      const existing = await tx.groupMember.findUnique({
        where: { classGroupId_userId: { classGroupId: groupId, userId: studentId } },
      });
      if (existing) {
        throw new ConflictError('Student is already enrolled in this class');
      }

      const invitation = await tx.classInvitation.findUnique({
        where: { id: invitationId },
      });
      if (!invitation || invitation.status !== 'ACTIVE') {
        throw new BadRequestError('Invitation code is no longer active');
      }
      if (invitation.expiresAt && invitation.expiresAt < new Date()) {
        await tx.classInvitation.update({
          where: { id: invitationId },
          data: { status: 'EXPIRED' },
        });
        throw new BadRequestError('Invitation code has expired');
      }
      if (invitation.maxUses !== null && invitation.usedCount >= invitation.maxUses) {
        throw new BadRequestError('Invitation code usage limit has been reached');
      }

      await tx.classInvitation.update({
        where: { id: invitationId },
        data: { usedCount: { increment: 1 } },
      });

      await tx.groupMember.create({
        data: {
          classGroupId: groupId,
          userId: studentId,
        },
      });

      const updatedCount = await tx.groupMember.count({ where: { classGroupId: groupId } });
      const rawWithCount = {
        ...group,
        _count: {
          members: updatedCount,
          teachers: group._count.teachers,
        },
      };

      return {
        classGroup: this.toDetail(rawWithCount as any),
      };
    });
  }

  public async leaveGroup(groupId: string, studentId: string): Promise<boolean> {
    const existing = await this.prisma.groupMember.findUnique({
      where: { classGroupId_userId: { classGroupId: groupId, userId: studentId } },
    });
    if (!existing) {
      return false;
    }
    await this.prisma.groupMember.delete({
      where: { classGroupId_userId: { classGroupId: groupId, userId: studentId } },
    });
    return true;
  }
}
