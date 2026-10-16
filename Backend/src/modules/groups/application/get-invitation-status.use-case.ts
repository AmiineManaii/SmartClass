import type { GroupRepositoryPort } from '../domain/group-repository.port.js';
import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';

export interface GetInvitationStatusParams {
  groupId: string;
  actorId: string;
  actorRole: string;
}

export interface InvitationStatusResult {
  hasActiveInvitation: boolean;
  invitation: {
    id: string;
    classGroupId: string;
    status: string;
    expiresAt: Date | null;
    maxUses: number | null;
    usedCount: number;
    createdAt: Date;
  } | null;
}

export class GetInvitationStatusUseCase {
  constructor(private readonly groupRepository: GroupRepositoryPort) {}

  public async execute(params: GetInvitationStatusParams): Promise<InvitationStatusResult> {
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
        throw new ForbiddenError('You are not authorized to view invitations for this class');
      }
    }

    const invitation = await this.groupRepository.findActiveInvitationByGroupId(params.groupId);
    if (!invitation || invitation.status !== 'ACTIVE') {
      return {
        hasActiveInvitation: false,
        invitation: null,
      };
    }

    return {
      hasActiveInvitation: true,
      invitation: {
        id: invitation.id,
        classGroupId: invitation.classGroupId,
        status: invitation.status,
        expiresAt: invitation.expiresAt,
        maxUses: invitation.maxUses,
        usedCount: invitation.usedCount,
        createdAt: invitation.createdAt,
      },
    };
  }
}
