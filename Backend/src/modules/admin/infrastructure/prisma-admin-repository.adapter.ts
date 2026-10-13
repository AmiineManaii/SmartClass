import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type { AdminOverview } from '../domain/admin-overview.entity.js';
import type { AdminRepositoryPort } from '../domain/admin-repository.port.js';

export class PrismaAdminRepositoryAdapter implements AdminRepositoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  public async getOverview(monthStart: Date): Promise<AdminOverview> {
    const [
      totalStudents,
      newStudents,
      totalTeachers,
      activeTeachers,
      newTeachers,
      totalClasses,
      newClasses,
      enrollments,
      untreated,
      inProgress,
      closed,
      resolvedThisMonth,
    ] = await Promise.all([
      this.prisma.user.count({ where: { role: 'STUDENT' } }),
      this.prisma.user.count({ where: { role: 'STUDENT', createdAt: { gte: monthStart } } }),
      this.prisma.user.count({ where: { role: 'TEACHER' } }),
      this.prisma.user.count({ where: { role: 'TEACHER', status: 'ACTIVE' } }),
      this.prisma.user.count({ where: { role: 'TEACHER', createdAt: { gte: monthStart } } }),
      this.prisma.classGroup.count(),
      this.prisma.classGroup.count({ where: { createdAt: { gte: monthStart } } }),
      this.prisma.groupMember.count(),
      this.prisma.fraudReport.count({ where: { status: 'UNTREATED' } }),
      this.prisma.fraudReport.count({ where: { status: 'IN_PROGRESS' } }),
      this.prisma.fraudReport.count({ where: { status: 'CLOSED' } }),
      this.prisma.fraudReport.count({
        where: { status: 'CLOSED', closedAt: { gte: monthStart } },
      }),
    ]);

    return {
      students: { total: totalStudents, newThisMonth: newStudents },
      teachers: {
        total: totalTeachers,
        newThisMonth: newTeachers,
        activePct: totalTeachers === 0 ? 100 : Math.round((activeTeachers / totalTeachers) * 100),
      },
      classes: { total: totalClasses, newThisMonth: newClasses },
      enrollments,
      frauds: { untreated, inProgress, closed, resolvedThisMonth },
    };
  }
}
