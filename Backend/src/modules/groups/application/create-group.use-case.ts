import type { ClassGroupDetail } from '../domain/class-group.entity.js';
import type { CreateGroupParams, GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface CreateGroupResult {
  group: ClassGroupDetail;
}

export class CreateGroupUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(params: CreateGroupParams): Promise<CreateGroupResult> {
    const group = await this.groups.createGroup(params);

    return { group };
  }
}
