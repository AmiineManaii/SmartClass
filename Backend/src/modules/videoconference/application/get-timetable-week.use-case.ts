import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { TimetableDayView, TimetableWeek } from '../domain/timetable.entity.js';
import type { TimetableRepositoryPort } from '../domain/timetable-repository.port.js';

export interface GetTimetableWeekResult {
  week: TimetableWeek;
}

/** Monday (00:00 UTC) of the week containing `date`. */
export const startOfWeekMonday = (date: Date): Date => {
  const monday = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const weekday = monday.getUTCDay(); // 0 = Sunday
  const shift = (weekday + 6) % 7;
  monday.setUTCDate(monday.getUTCDate() - shift);
  return monday;
};

export const toISODate = (date: Date): string => date.toISOString().slice(0, 10);

const TEACHING_KINDS = new Set(['CM', 'TP', 'TD']);

export class GetTimetableWeekUseCase {
  constructor(private readonly timetable: TimetableRepositoryPort) {}

  public async execute(
    classGroupId: string,
    weekStart?: Date,
    reader?: { id: string; role: string | null },
  ): Promise<GetTimetableWeekResult> {
    const exists = await this.timetable.classGroupExists(classGroupId);
    if (!exists) {
      throw new NotFoundError('Class group not found');
    }

    // ADMIN reads every timetable; anyone else must belong to the class
    // (enrolled student, assigned teacher, or referent).
    if (reader && reader.role !== 'ADMIN') {
      const allowed = await this.timetable.userCanReadClass(reader.id, classGroupId);
      if (!allowed) {
        throw new ForbiddenError('You do not belong to this class group');
      }
    }

    const monday = startOfWeekMonday(weekStart ?? new Date());
    // Monday to Saturday display window.
    const weekEndExclusive = new Date(monday.getTime() + 6 * 24 * 60 * 60 * 1000);

    const events = await this.timetable.weekSlots({
      classGroupId,
      weekStart: monday,
      weekEndExclusive,
    });

    const byDate = new Map<string, number>();
    for (const event of events) {
      if (!TEACHING_KINDS.has(event.kind)) continue;
      byDate.set(event.date, (byDate.get(event.date) ?? 0) + 1);
    }

    const days: TimetableDayView[] = [];
    for (let i = 0; i < 6; i++) {
      const date = toISODate(new Date(monday.getTime() + i * 24 * 60 * 60 * 1000));
      days.push({ date, courseCount: byDate.get(date) ?? 0 });
    }

    return {
      week: { weekStart: toISODate(monday), days, events },
    };
  }
}
