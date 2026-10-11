export type TimetableKind = 'CM' | 'TP' | 'TD' | 'BREAK' | 'LUNCH' | 'FREE';

export interface TimetableTeacher {
  id: string;
  name: string;
}

export interface TimetableEventView {
  id: string;
  date: string;
  start: string;
  end: string;
  kind: TimetableKind;
  title: string;
  subtitle: string | null;
  teacher: TimetableTeacher | null;
  room: string | null;
  statusNotes: string[];
}

export interface TimetableDayView {
  date: string;
  courseCount: number;
}

export interface TimetableWeek {
  weekStart: string;
  days: TimetableDayView[];
  events: TimetableEventView[];
}
