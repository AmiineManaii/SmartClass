import type { Role, SafeUser } from '../../auth/index.js';

export type UserRoleFilter = Extract<Role, 'TEACHER' | 'STUDENT' | 'ADMIN'>;

export interface ListUsersQuery {
  role?: UserRoleFilter;
  search?: string;
  page: number;
  limit: number;
  sortField: 'createdAt' | 'email' | 'firstName' | 'lastName';
  sortOrder: 'asc' | 'desc';
}

export interface ListUsersResult {
  users: SafeUser[];
  total: number;
}

export interface UserDirectoryPort {
  listUsers(query: ListUsersQuery): Promise<ListUsersResult>;
}
