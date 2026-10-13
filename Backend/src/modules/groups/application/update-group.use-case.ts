import { NotFoundError, ValidationError } from '../../../shared/errors/app-error.js';
import type { ClassGroupDetail } from '../domain/class-group.entity.js';
import type {
  GroupRepositoryPort,
  UpdateGroupParams,
} from '../domain/group-repository.port.js';

export interface UpdateGroupResult {
  group: ClassGroupDetail;
}

export class UpdateGroupUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(groupId: string, params: UpdateGroupParams): Promise<UpdateGroupResult> {
    const existing = await this.groups.findGroupDetailById(groupId);
    if (!existing) {
      throw new NotFoundError('Class group not found');
    }

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

    const group = await this.groups.updateGroup(groupId, params);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    return { group };
  }
}
