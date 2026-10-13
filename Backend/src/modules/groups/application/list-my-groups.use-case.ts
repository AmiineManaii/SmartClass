import type {
  GroupRepositoryPort,
  MyClassGroup,
} from '../domain/group-repository.port.js';

export interface ListMyGroupsResult {
  groups: MyClassGroup[];
}

export class ListMyGroupsUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(userId: string): Promise<ListMyGroupsResult> {
    const groups = await this.groups.listMyGroups(userId);

    return { groups };
  }
}
