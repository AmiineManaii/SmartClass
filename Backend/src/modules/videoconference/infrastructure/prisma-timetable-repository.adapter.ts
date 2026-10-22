import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type { TimetableEventView, TimetableKind } from '../domain/timetable.entity.js';
import type {
  TimetableRepositoryPort,
  TimetableSlotInput,
} from '../domain/timetable-repository.port.js';

const pad2 = (value: number): string => String(value).padStart(2, '0');

const toISODate = (date: Date): string => date.toISOString().slice(0, 10);

const toHHMM = (date: Date): string => `${pad2(date.getUTCHours())}:${pad2(date.getUTCMinutes())}`;

export class PrismaTimetableRepositoryAdapter implements TimetableRepositoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  public async classGroupExists(id: string): Promise<boolean> {
    const row = await this.prisma.classGroup.findUnique({
      where: { id },
      select: { id: true },
    });

    return row !== null;
  }

  public async userCanReadClass(userId: string, classGroupId: string): Promise<boolean> {
    const [member, assignment, referent] = await Promise.all([
      this.prisma.groupMember.findUnique({
        where: { classGroupId_userId: { classGroupId, userId } },
        select: { userId: true },
      }),
      this.prisma.teacherAssignment.findFirst({
        where: { classGroupId, teacherId: userId },
        select: { teacherId: true },
      }),
      this.prisma.classGroup.findFirst({
        where: { id: classGroupId, referentId: userId },
        select: { id: true },
      }),
    ]);

    return member !== null || assignment !== null || referent !== null;
  }

  public async weekSlots(input: TimetableSlotInput): Promise<TimetableEventView[]> {
    const rows = await this.prisma.timetableSlot.findMany({
      where: {
        classGroupId: input.classGroupId,
        startsAt: { gte: input.weekStart, lt: input.weekEndExclusive },
      },
      orderBy: [{ startsAt: 'asc' }, { id: 'asc' }],
      select: {
        id: true,
        title: true,
        subtitle: true,
        kind: true,
        startsAt: true,
        endsAt: true,
        room: true,
        statusNotes: true,
        teacher: { select: { id: true, firstName: true, lastName: true } },
      },
    });

    return rows.map((row) => ({
      id: row.id,
      date: toISODate(row.startsAt),
      start: toHHMM(row.startsAt),
      end: toHHMM(row.endsAt),
      kind: row.kind as TimetableKind,
      title: row.title,
      subtitle: row.subtitle,
      teacher: row.teacher
        ? {
            id: row.teacher.id,
            name: `${row.teacher.firstName} ${row.teacher.lastName}`.trim(),
          }
        : null,
      room: row.room,
      statusNotes: Array.isArray(row.statusNotes)
        ? row.statusNotes.filter((note): note is string => typeof note === 'string')
        : [],
    }));
  }
}
