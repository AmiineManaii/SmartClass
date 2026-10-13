import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';

export class DeleteGroupUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(groupId: string): Promise<void> {
    const deleted = await this.groups.deleteGroup(groupId);
    if (!deleted) {
      throw new NotFoundError('Class group not found');
    }
  }
}
