import type { GroupRepositoryPort } from '../domain/group-repository.port.js';
import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';

export interface RevokeInvitationParams {
  groupId: string;
  actorId: string;
  actorRole: string;
}

export class RevokeInvitationUseCase {
  constructor(
    private readonly groupRepository: GroupRepositoryPort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(params: RevokeInvitationParams): Promise<{ message: string }> {
    const group = await this.groupRepository.findGroupDetailById(params.groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    if (params.actorRole !== 'ADMIN') {
      const isAuthorized = await this.groupRepository.isTeacherAuthorizedForGroup(
        params.groupId,
        params.actorId,
      );
      if (!isAuthorized) {
        throw new ForbiddenError('You are not authorized to manage invitations for this class');
      }
    }

    await this.groupRepository.revokeInvitation(params.groupId);

    await this.auditService?.record({
      userId: params.actorId,
      action: 'INVITATION_REVOKED',
      targetType: 'CLASS_GROUP',
      targetId: params.groupId,
    });

    return { message: 'Invitation code revoked successfully' };
  }
}
