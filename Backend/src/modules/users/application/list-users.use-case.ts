import type { SafeUser } from '../../auth/index.js';
import {
  buildOffsetPaginationMeta,
  type OffsetPaginationMeta,
} from '../../../shared/http/pagination/index.js';
import type { ListUsersQuery, UserDirectoryPort } from '../domain/user-directory.port.js';

export interface ListUsersResult {
  users: SafeUser[];
  meta: OffsetPaginationMeta;
}

export class ListUsersUseCase {
  constructor(private readonly userDirectory: UserDirectoryPort) {}

  public async execute(query: ListUsersQuery): Promise<ListUsersResult> {
    const { users, total } = await this.userDirectory.listUsers(query);

    return {
      users,
      meta: buildOffsetPaginationMeta({ page: query.page, limit: query.limit, total }),
    };
  }
}
