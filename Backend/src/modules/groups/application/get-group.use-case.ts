import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { ClassGroupDetail } from '../domain/class-group.entity.js';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface GetGroupResult {
  group: ClassGroupDetail;
}

export class GetGroupUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(groupId: string): Promise<GetGroupResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    return { group };
  }
}
