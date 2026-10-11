export {
  createGroupsModule,
  type GroupsModule,
  type GroupsModuleOptions,
} from './groups.module.js';
export type {
  ClassGroupDetail,
  ClassGroupSummary,
  ClassLevel,
  ClassReferent,
  ClassStatus,
  TeacherAssignmentView,
} from './domain/class-group.entity.js';
export type {
  CreateGroupParams,
  GroupMemberUser,
  GroupRepositoryPort,
  ListGroupsQuery,
  TeacherAssignInput,
} from './domain/group-repository.port.js';
