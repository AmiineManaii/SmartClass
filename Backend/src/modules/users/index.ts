export { createUsersModule, type UsersModule, type UsersModuleOptions } from './users.module.js';
export type {
  UserDirectoryPort,
  ListUsersQuery,
  ListUsersResult,
} from './domain/user-directory.port.js';
export {
  ListUsersUseCase,
  type ListUsersResult as ListUsersUseCaseResult,
} from './application/list-users.use-case.js';
export {
  SetMyRoleUseCase,
  type SetMyRoleResult,
  type AssignableRole,
} from './application/set-my-role.use-case.js';
export { SetUserRoleUseCase, type SetUserRoleResult } from './application/set-user-role.use-case.js';
export { ExportUserDataUseCase, type ExportUserDataInput } from './application/export-user-data.use-case.js';
export type {
  ExportDataPort,
  UserExportData,
  ExportProfile,
  ExportGroupMembership,
  ExportTeacherAssignment,
  ExportCourse,
  ExportAuditEntry,
  ExportTimetableSlot,
} from './domain/export-data.port.js';
export { PdfExportGenerator } from './infrastructure/pdf-export-generator.js';

