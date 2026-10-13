import { NotFoundError, ValidationError } from '../../../shared/errors/app-error.js';
import type { ClassGroupDetail } from '../domain/class-group.entity.js';
import type { CreateGroupParams, GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface CreateGroupResult {
  group: ClassGroupDetail;
}

export class CreateGroupUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(params: CreateGroupParams): Promise<CreateGroupResult> {
    if (params.referentId !== undefined && params.referentId !== null) {
      const users = await this.groups.findUsersByIds([params.referentId]);
      const referent = users.find((user) => user.id === params.referentId);
      if (!referent) {
        throw new NotFoundError('Referent user not found');
      }
      if (referent.role !== 'TEACHER') {
        throw new ValidationError('Only TEACHER accounts can be class referents', [
          { path: 'referentId', message: `User ${params.referentId} is not a TEACHER` },
        ]);
      }
    }

    const group = await this.groups.createGroup(params);

    return { group };
  }
}
