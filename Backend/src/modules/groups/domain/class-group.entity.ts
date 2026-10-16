export type ClassLevel = 'LICENCE' | 'MASTER' | 'DOCTORAT';

export type ClassStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export type InvitationStatus = 'ACTIVE' | 'REVOKED' | 'EXPIRED';

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
  academicYear?: string | null;
  capacity: number;
  status: ClassStatus;
  isVirtual?: boolean;
  ownerId?: string | null;
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

export interface ClassInvitationView {
  id: string;
  classGroupId: string;
  codePrefix?: string | null;
  creatorId: string;
  status: InvitationStatus;
  expiresAt: Date | null;
  maxUses: number | null;
  usedCount: number;
  createdAt: Date;
}

export interface GeneratedInvitation {
  id: string;
  classGroupId: string;
  rawCode: string;
  status: InvitationStatus;
  expiresAt: Date | null;
  maxUses: number | null;
  createdAt: Date;
}
