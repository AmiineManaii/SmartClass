import type {
  ClassGroupDetail,
  ClassGroupSummary,
  ClassLevel,
  ClassStatus,
  TeacherAssignmentView,
} from './class-group.entity.js';

export interface ListGroupsQuery {
  level?: ClassLevel;
  search?: string;
  page: number;
  limit: number;
  sortField: 'createdAt' | 'name' | 'capacity';
  sortOrder: 'asc' | 'desc';
}

export interface CreateGroupParams {
  name: string;
  level: ClassLevel;
  department?: string | null;
  academicYear?: string | null;
  capacity: number;
  description?: string | null;
  forumEnabled: boolean;
  entSyncEnabled: boolean;
  status: ClassStatus;
  isVirtual?: boolean;
  ownerId?: string | null;
  referentId?: string | null;
}

export interface UpdateGroupParams {
  name?: string;
  level?: ClassLevel;
  department?: string | null;
  academicYear?: string | null;
  capacity?: number;
  description?: string | null;
  forumEnabled?: boolean;
  entSyncEnabled?: boolean;
  status?: ClassStatus;
  referentId?: string | null;
}

export interface GroupMemberUser {
  id: string;
  role: string | null;
}

export interface GroupMemberView {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: string | null;
  joinedAt: Date;
}

export interface TeacherAssignmentDetail {
  teacherId: string;
  firstName: string;
  lastName: string;
  email: string;
  subject: string;
  weeklyHours: string | null;
}

export interface DepartmentView {
  name: string;
  classCount: number;
}

export type MyClassRole = 'STUDENT' | 'TEACHER' | 'REFERENT';

export interface MyClassGroup extends ClassGroupSummary {
  /** The caller's relation to the class (referent wins over teacher). */
  myRole: MyClassRole;
  /** Enrolment/assignment date, if applicable. */
  joinedAt: Date | null;
  /** Subjects the caller teaches in this class (teachers only). */
  mySubjects: string[];
}

export interface TeacherAssignInput {
  teacherId: string;
  subject: string;
  weeklyHours?: string | null;
}

export interface GroupRepositoryPort {
  listGroups(query: ListGroupsQuery): Promise<{ groups: ClassGroupSummary[]; total: number }>;
  listMyGroups(userId: string): Promise<MyClassGroup[]>;
  createGroup(params: CreateGroupParams): Promise<ClassGroupDetail>;
  findGroupDetailById(id: string): Promise<ClassGroupDetail | null>;
  updateGroup(id: string, params: UpdateGroupParams): Promise<ClassGroupDetail | null>;
  deleteGroup(id: string): Promise<boolean>;
  listDepartments(): Promise<DepartmentView[]>;
  listGroupMembers(
    groupId: string,
    page: number,
    limit: number,
  ): Promise<{ members: GroupMemberView[]; total: number }>;
  removeMembers(groupId: string, userIds: string[]): Promise<{ removed: string[]; memberCount: number }>;
  listTeacherAssignments(groupId: string): Promise<TeacherAssignmentDetail[]>;
  removeTeacherAssignments(groupId: string, teacherIds: string[]): Promise<{ removed: string[]; teacherCount: number }>;
  findUsersByIds(ids: string[]): Promise<GroupMemberUser[]>;
  existingMemberUserIds(groupId: string, userIds: string[]): Promise<string[]>;
  addMembers(groupId: string, userIds: string[]): Promise<{ memberCount: number }>;
  upsertTeacherAssignments(
    groupId: string,
    assignments: TeacherAssignInput[],
  ): Promise<{ assigned: TeacherAssignmentView[]; teacherCount: number }>;
  addTeacherSubject(
    groupId: string,
    teacherId: string,
    input: Omit<TeacherAssignInput, 'teacherId'>,
  ): Promise<TeacherAssignmentView>;
  isTeacherAuthorizedForGroup(groupId: string, teacherId: string): Promise<boolean>;
  findUserClassMembership(groupId: string, userId: string): Promise<{ isMember: boolean; isTeacher: boolean; isReferent: boolean; isOwner: boolean }>;
  createInvitation(params: {
    groupId: string;
    creatorId: string;
    codeHash: string;
    codePrefix?: string | null;
    expiresAt?: Date | null;
    maxUses?: number | null;
  }): Promise<import('./class-group.entity.js').ClassInvitationView>;
  findActiveInvitationByGroupId(groupId: string): Promise<import('./class-group.entity.js').ClassInvitationView | null>;
  findInvitationByCodeHash(codeHash: string): Promise<(import('./class-group.entity.js').ClassInvitationView & { classGroup: ClassGroupSummary }) | null>;
  rotateInvitation(params: {
    groupId: string;
    creatorId: string;
    codeHash: string;
    codePrefix?: string | null;
    expiresAt?: Date | null;
    maxUses?: number | null;
  }): Promise<import('./class-group.entity.js').ClassInvitationView>;
  revokeInvitation(groupId: string): Promise<boolean>;
  joinGroupWithInvitation(invitationId: string, groupId: string, studentId: string): Promise<{ classGroup: ClassGroupDetail }>;
  leaveGroup(groupId: string, studentId: string): Promise<boolean>;
}
