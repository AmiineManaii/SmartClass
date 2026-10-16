import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
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
    actorId?: string,
    actorRole?: string,
  ): Promise<ListGroupMembersResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    if (actorRole && actorRole !== 'ADMIN') {
      if (!actorId) {
        throw new ForbiddenError('Authentication required');
      }
      const membership = await this.groups.findUserClassMembership(groupId, actorId);
      if (!membership.isMember && !membership.isTeacher && !membership.isReferent && !membership.isOwner) {
        throw new ForbiddenError('You are not authorized to view members of this class');
      }
    }

    const { members, total } = await this.groups.listGroupMembers(groupId, page, limit);

    return {
      members,
      meta: buildOffsetPaginationMeta({ page, limit, total }),
    };
  }
}
