import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface RemoveMembersResult {
  classGroupId: string;
  removed: string[];
  memberCount: number;
}

export class RemoveMembersUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(groupId: string, studentIds: string[]): Promise<RemoveMembersResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    const { removed, memberCount } = await this.groups.removeMembers(groupId, studentIds);

    return { classGroupId: groupId, removed, memberCount };
  }
}
