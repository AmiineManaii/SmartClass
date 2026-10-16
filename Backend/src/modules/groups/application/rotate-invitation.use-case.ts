import crypto from 'node:crypto';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';
import type { GeneratedInvitation } from '../domain/class-group.entity.js';
import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';

export interface RotateInvitationParams {
  groupId: string;
  actorId: string;
  actorRole: string;
  expiresInHours?: number | null;
  maxUses?: number | null;
}

export class RotateInvitationUseCase {
  constructor(
    private readonly groupRepository: GroupRepositoryPort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(params: RotateInvitationParams): Promise<GeneratedInvitation> {
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

    const randomSuffix = crypto.randomBytes(4).toString('hex').toUpperCase();
    const rawCode = `SC-${randomSuffix}`;
    const codeHash = crypto.createHash('sha256').update(rawCode).digest('hex');
    const codePrefix = rawCode.slice(0, 4);

    const expiresAt = params.expiresInHours
      ? new Date(Date.now() + params.expiresInHours * 3600 * 1000)
      : null;

    const invitation = await this.groupRepository.rotateInvitation({
      groupId: params.groupId,
      creatorId: params.actorId,
      codeHash,
      codePrefix,
      expiresAt,
      maxUses: params.maxUses ?? null,
    });

    await this.auditService?.record({
      userId: params.actorId,
      action: 'INVITATION_ROTATED',
      targetType: 'CLASS_GROUP',
      targetId: params.groupId,
      details: {
        codePrefix,
        expiresAt: expiresAt?.toISOString() ?? null,
        maxUses: params.maxUses ?? null,
      },
    });

    return {
      id: invitation.id,
      classGroupId: invitation.classGroupId,
      rawCode,
      status: invitation.status,
      expiresAt: invitation.expiresAt,
      maxUses: invitation.maxUses,
      createdAt: invitation.createdAt,
    };
  }
}
