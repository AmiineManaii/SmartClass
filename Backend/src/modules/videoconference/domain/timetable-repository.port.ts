import type { TimetableEventView } from './timetable.entity.js';

export interface TimetableSlotInput {
  classGroupId: string;
  weekStart: Date;
  weekEndExclusive: Date;
}

export interface TimetableRepositoryPort {
  classGroupExists(id: string): Promise<boolean>;
  weekSlots(input: TimetableSlotInput): Promise<TimetableEventView[]>;
}
