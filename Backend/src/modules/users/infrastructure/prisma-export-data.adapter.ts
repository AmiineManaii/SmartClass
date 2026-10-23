import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type { Role } from '../../auth/index.js';
import type {
  ExportDataPort,
  UserExportData,
  ExportProfile,
  ExportGroupMembership,
  ExportTeacherAssignment,
  ExportCourse,
  ExportAuditEntry,
  ExportTimetableSlot,
} from '../domain/export-data.port.js';

// ──────────────────────────────────────────────────────────────────────
// Prisma Adapter — fetches all export-relevant data for one user
// ──────────────────────────────────────────────────────────────────────

export class PrismaExportDataAdapter implements ExportDataPort {
  private get prisma() {
    return getPrismaClient();
  }

  public async getUserExportData(userId: string, role: Role | null): Promise<UserExportData> {
    const normalizedRole = (role ?? '').toUpperCase();

    // 1. User profile
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        status: true,
        emailVerified: true,
        twoFactorEnabled: true,
        birthDate: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    const profile: ExportProfile = {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      status: user.status,
      emailVerified: user.emailVerified,
      twoFactorEnabled: user.twoFactorEnabled,
      birthDate: user.birthDate ? user.birthDate.toISOString().slice(0, 10) : null,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString(),
    };

    // 2. Group memberships (students + teachers)
    const memberships = await this.prisma.groupMember.findMany({
      where: { userId },
      include: {
        classGroup: {
          select: {
            id: true,
            name: true,
            level: true,
            department: true,
            academicYear: true,
          },
        },
      },
      orderBy: { joinedAt: 'desc' },
    });

    const groups: ExportGroupMembership[] = memberships.map((m) => ({
      groupId: m.classGroup.id,
      groupName: m.classGroup.name,
      level: m.classGroup.level,
      department: m.classGroup.department,
      academicYear: m.classGroup.academicYear,
      joinedAt: m.joinedAt.toISOString(),
    }));

    // 3. Teacher assignments
    let assignments: ExportTeacherAssignment[] | undefined;
    if (normalizedRole === 'TEACHER' || normalizedRole === 'ADMIN') {
      const rawAssignments = await this.prisma.teacherAssignment.findMany({
        where: { teacherId: userId },
        include: {
          classGroup: { select: { id: true, name: true } },
        },
        orderBy: { assignedAt: 'desc' },
      });
      assignments = rawAssignments.map((a) => ({
        groupId: a.classGroup.id,
        groupName: a.classGroup.name,
        subject: a.subject,
        weeklyHours: a.weeklyHours,
        assignedAt: a.assignedAt.toISOString(),
      }));
    }

    // 4. Authored courses (teachers) or enrolled courses (students via group)
    let authoredCourses: ExportCourse[] | undefined;
    let enrolledCourses: ExportCourse[] | undefined;

    if (normalizedRole === 'TEACHER' || normalizedRole === 'ADMIN') {
      const rawCourses = await this.prisma.course.findMany({
        where: { authorId: userId },
        include: { _count: { select: { sections: true } } },
        orderBy: { createdAt: 'desc' },
      });
      authoredCourses = rawCourses.map((c) => ({
        id: c.id,
        title: c.title,
        subject: c.subject,
        level: c.level,
        difficulty: c.difficulty,
        status: c.status,
        sectionsCount: c._count.sections,
        createdAt: c.createdAt.toISOString(),
      }));
    } else {
      // Student: courses from groups
      const groupIds = groups.map((g) => g.groupId);
      if (groupIds.length > 0) {
        const courseLinks = await this.prisma.courseClassGroup.findMany({
          where: { classGroupId: { in: groupIds } },
          include: {
            course: {
              select: {
                id: true,
                title: true,
                subject: true,
                level: true,
                difficulty: true,
                status: true,
                createdAt: true,
                _count: { select: { sections: true } },
              },
            },
          },
        });
        const seen = new Set<string>();
        enrolledCourses = courseLinks
          .filter((cl) => {
            if (seen.has(cl.course.id)) return false;
            seen.add(cl.course.id);
            return true;
          })
          .map((cl) => ({
            id: cl.course.id,
            title: cl.course.title,
            subject: cl.course.subject,
            level: cl.course.level,
            difficulty: cl.course.difficulty,
            status: cl.course.status,
            sectionsCount: cl.course._count.sections,
            createdAt: cl.course.createdAt.toISOString(),
          }));
      }
    }

    // 5. Timetable slots
    const memberGroupIds = groups.map((g) => g.groupId);
    let timetable: ExportTimetableSlot[] = [];
    if (memberGroupIds.length > 0) {
      const slots = await this.prisma.timetableSlot.findMany({
        where: { classGroupId: { in: memberGroupIds } },
        include: { classGroup: { select: { name: true } } },
        orderBy: { startsAt: 'asc' },
        take: 50,
      });
      timetable = slots.map((s) => ({
        title: s.title,
        kind: s.kind,
        startsAt: s.startsAt.toISOString(),
        endsAt: s.endsAt.toISOString(),
        room: s.room,
        groupName: s.classGroup.name,
      }));
    }

    // 6. Recent audit logs (last 50)
    const rawLogs = await this.prisma.auditLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: {
        action: true,
        targetType: true,
        targetId: true,
        createdAt: true,
      },
    });
    const recentAuditLogs: ExportAuditEntry[] = rawLogs.map((l) => ({
      action: l.action,
      targetType: l.targetType,
      targetId: l.targetId,
      createdAt: l.createdAt.toISOString(),
    }));

    // 7. Platform stats (admins only)
    let platformStats: UserExportData['platformStats'];
    if (normalizedRole === 'ADMIN') {
      const [totalUsers, totalStudents, totalTeachers, totalAdmins, totalGroups, totalCourses] =
        await Promise.all([
          this.prisma.user.count(),
          this.prisma.user.count({ where: { role: 'STUDENT' } }),
          this.prisma.user.count({ where: { role: 'TEACHER' } }),
          this.prisma.user.count({ where: { role: 'ADMIN' } }),
          this.prisma.classGroup.count(),
          this.prisma.course.count(),
        ]);
      platformStats = {
        totalUsers,
        totalStudents,
        totalTeachers,
        totalAdmins,
        totalGroups,
        totalCourses,
      };
    }

    return {
      exportedAt: new Date().toISOString(),
      format: 'SmartClass RGPD Art. 20 Export',
      user: profile,
      groups,
      assignments,
      authoredCourses,
      enrolledCourses,
      timetable,
      recentAuditLogs,
      platformStats,
    };
  }
}
