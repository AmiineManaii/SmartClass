import type { Role } from '../../auth/index.js';

// ──────────────────────────────────────────────────────────────────────
// Export Domain Types
// ──────────────────────────────────────────────────────────────────────

export interface ExportProfile {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: string | null;
  status: string;
  emailVerified: boolean;
  twoFactorEnabled: boolean;
  birthDate: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ExportGroupMembership {
  groupId: string;
  groupName: string;
  level: string;
  department: string | null;
  academicYear: string | null;
  joinedAt: string;
}

export interface ExportTeacherAssignment {
  groupId: string;
  groupName: string;
  subject: string;
  weeklyHours: string | null;
  assignedAt: string;
}

export interface ExportCourse {
  id: string;
  title: string;
  subject: string | null;
  level: string;
  difficulty: string;
  status: string;
  sectionsCount: number;
  createdAt: string;
}

export interface ExportAuditEntry {
  action: string;
  targetType: string;
  targetId: string | null;
  createdAt: string;
}

export interface ExportTimetableSlot {
  title: string;
  kind: string;
  startsAt: string;
  endsAt: string;
  room: string | null;
  groupName: string;
}

/** Fully hydrated export payload for one user, tailored to their role. */
export interface UserExportData {
  exportedAt: string;
  format: string;
  user: ExportProfile;
  groups: ExportGroupMembership[];
  /** Teachers only */
  assignments?: ExportTeacherAssignment[];
  /** Teachers only */
  authoredCourses?: ExportCourse[];
  /** Students only */
  enrolledCourses?: ExportCourse[];
  timetable: ExportTimetableSlot[];
  recentAuditLogs: ExportAuditEntry[];
  /** Admins only: platform-wide statistics */
  platformStats?: {
    totalUsers: number;
    totalStudents: number;
    totalTeachers: number;
    totalAdmins: number;
    totalGroups: number;
    totalCourses: number;
  };
}

export interface ExportDataPort {
  getUserExportData(userId: string, role: Role | null): Promise<UserExportData>;
}
