import { NotFoundError } from '../../../shared/errors/app-error.js';
import {
  buildOffsetPaginationMeta,
  type OffsetPaginationMeta,
} from '../../../shared/http/pagination/index.js';
import type { GroupMemberView, GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface ListGroupMembersResult {
  members: GroupMemberView[];
  meta: OffsetPaginationMeta;
}

export class ListGroupMembersUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(
    groupId: string,
    page: number,
    limit: number,
  ): Promise<ListGroupMembersResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    const { members, total } = await this.groups.listGroupMembers(groupId, page, limit);

    return {
      members,
      meta: buildOffsetPaginationMeta({ page, limit, total }),
    };
  }
}
