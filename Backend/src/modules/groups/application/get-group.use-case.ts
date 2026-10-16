import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { ClassGroupDetail } from '../domain/class-group.entity.js';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface GetGroupResult {
  group: ClassGroupDetail;
}

export class GetGroupUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(groupId: string, actorId?: string, actorRole?: string): Promise<GetGroupResult> {
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
        throw new ForbiddenError('You are not authorized to view this class');
      }
    }

    return { group };
  }
}
