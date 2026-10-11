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
  capacity: number;
  description?: string | null;
  forumEnabled: boolean;
  entSyncEnabled: boolean;
  status: ClassStatus;
}

export interface GroupMemberUser {
  id: string;
  role: string | null;
}

export interface TeacherAssignInput {
  teacherId: string;
  subject: string;
  weeklyHours?: string | null;
}

export interface GroupRepositoryPort {
  listGroups(query: ListGroupsQuery): Promise<{ groups: ClassGroupSummary[]; total: number }>;
  createGroup(params: CreateGroupParams): Promise<ClassGroupDetail>;
  findGroupDetailById(id: string): Promise<ClassGroupDetail | null>;
  findUsersByIds(ids: string[]): Promise<GroupMemberUser[]>;
  existingMemberUserIds(groupId: string, userIds: string[]): Promise<string[]>;
  addMembers(groupId: string, userIds: string[]): Promise<{ memberCount: number }>;
  upsertTeacherAssignments(
    groupId: string,
    assignments: TeacherAssignInput[],
  ): Promise<{ assigned: TeacherAssignmentView[]; teacherCount: number }>;
}
