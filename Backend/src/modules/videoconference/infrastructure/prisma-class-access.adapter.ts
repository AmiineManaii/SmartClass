import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { ClassAccessContext } from '../domain/video-session-policy.js';
import type { GroupRepositoryPort } from '../../groups/index.js';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';

export class PrismaClassAccessAdapter implements ClassAccessPort {
  constructor(
    private readonly groupRepository?: GroupRepositoryPort,
    private readonly prisma = getPrismaClient(),
  ) {}

  public async getClassAccess(userId: string, classGroupId: string): Promise<ClassAccessContext> {
    if (this.groupRepository) {
      const membership = await this.groupRepository.findUserClassMembership(classGroupId, userId);
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { role: true, teacherApprovalStatus: true },
      });
      const isApprovedTeacher =
        user?.role === 'TEACHER' &&
        (user?.teacherApprovalStatus === 'APPROVED' || user?.teacherApprovalStatus == null);

      return {
        isMember: membership.isMember,
        isTeacherAssigned: membership.isTeacher,
        isReferent: membership.isReferent || membership.isOwner,
        isApprovedTeacher,
      };
    }

    // Direct Prisma fallback if groupRepository not injected
    const [member, assignment, classGroup, user] = await Promise.all([
      this.prisma.groupMember.findUnique({
        where: { classGroupId_userId: { classGroupId, userId } },
      }),
      this.prisma.teacherAssignment.findFirst({
        where: { classGroupId, teacherId: userId },
      }),
      this.prisma.classGroup.findUnique({
        where: { id: classGroupId },
        select: { referentId: true, ownerId: true },
      }),
      this.prisma.user.findUnique({
        where: { id: userId },
        select: { role: true, teacherApprovalStatus: true },
      }),
    ]);

    const isApprovedTeacher =
      user?.role === 'TEACHER' &&
      (user?.teacherApprovalStatus === 'APPROVED' || user?.teacherApprovalStatus == null);

    return {
      isMember: Boolean(member),
      isTeacherAssigned: Boolean(assignment),
      isReferent: classGroup?.referentId === userId || classGroup?.ownerId === userId,
      isApprovedTeacher,
    };
  }

  public async getUserClassGroupIds(userId: string): Promise<string[]> {
    if (this.groupRepository) {
      const myGroups = await this.groupRepository.listMyGroups(userId);
      return myGroups.map((g) => g.id);
    }

    const [enrolled, assigned, referred] = await Promise.all([
      this.prisma.groupMember.findMany({
        where: { userId },
        select: { classGroupId: true },
      }),
      this.prisma.teacherAssignment.findMany({
        where: { teacherId: userId },
        select: { classGroupId: true },
      }),
      this.prisma.classGroup.findMany({
        where: { OR: [{ referentId: userId }, { ownerId: userId }] },
        select: { id: true },
      }),
    ]);

    const ids = new Set<string>();
    enrolled.forEach((e) => ids.add(e.classGroupId));
    assigned.forEach((a) => ids.add(a.classGroupId));
    referred.forEach((r) => ids.add(r.id));

    return Array.from(ids);
  }

  public async getClassMemberUserIds(classGroupId: string): Promise<string[]> {
    const [members, teachers, classGroup] = await Promise.all([
      this.prisma.groupMember.findMany({
        where: { classGroupId },
        select: { userId: true },
      }),
      this.prisma.teacherAssignment.findMany({
        where: { classGroupId },
        select: { teacherId: true },
      }),
      this.prisma.classGroup.findUnique({
        where: { id: classGroupId },
        select: { referentId: true, ownerId: true },
      }),
    ]);

    const ids = new Set<string>();
    members.forEach((m) => ids.add(m.userId));
    teachers.forEach((t) => ids.add(t.teacherId));
    if (classGroup?.referentId) ids.add(classGroup.referentId);
    if (classGroup?.ownerId) ids.add(classGroup.ownerId);

    return Array.from(ids);
  }
}
