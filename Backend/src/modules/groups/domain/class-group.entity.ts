export type ClassLevel = 'LICENCE' | 'MASTER' | 'DOCTORAT';

export type ClassStatus = 'DRAFT' | 'PUBLISHED';

export interface ClassReferent {
  id: string;
  firstName: string;
  lastName: string;
}

export interface ClassGroupSummary {
  id: string;
  name: string;
  level: ClassLevel;
  department: string | null;
  capacity: number;
  status: ClassStatus;
  memberCount: number;
  teacherCount: number;
  referent: ClassReferent | null;
  createdAt: Date;
}

export interface ClassGroupDetail extends ClassGroupSummary {
  description: string | null;
  forumEnabled: boolean;
  entSyncEnabled: boolean;
  updatedAt: Date;
}

export interface TeacherAssignmentView {
  teacherId: string;
  subject: string;
  weeklyHours: string | null;
}
