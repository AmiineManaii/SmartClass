import crypto from 'node:crypto';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';
import type { ClassGroupDetail } from '../domain/class-group.entity.js';
import { BadRequestError, ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';

export interface JoinClassParams {
  rawCode: string;
  studentId: string;
  studentRole: string;
}

export interface JoinClassResult {
  message: string;
  classGroup: ClassGroupDetail;
}

export class JoinClassUseCase {
  constructor(
    private readonly groupRepository: GroupRepositoryPort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(params: JoinClassParams): Promise<JoinClassResult> {
    if (params.studentRole !== 'STUDENT') {
      throw new ForbiddenError('Only students can join classes via invitation code');
    }

    const trimmedCode = params.rawCode.trim().toUpperCase();
    if (!trimmedCode) {
      throw new BadRequestError('Invitation code cannot be empty');
    }

    const codeHash = crypto.createHash('sha256').update(trimmedCode).digest('hex');

    const invitation = await this.groupRepository.findInvitationByCodeHash(codeHash);
    if (!invitation || invitation.status !== 'ACTIVE') {
      throw new NotFoundError('Invalid, expired, or revoked invitation code');
    }

    if (invitation.expiresAt && invitation.expiresAt.getTime() < Date.now()) {
      throw new BadRequestError('Invitation code has expired');
    }

    if (invitation.maxUses !== null && invitation.usedCount >= invitation.maxUses) {
      throw new BadRequestError('Invitation code usage limit has been reached');
    }

    const result = await this.groupRepository.joinGroupWithInvitation(
      invitation.id,
      invitation.classGroupId,
      params.studentId,
    );

    await this.auditService?.record({
      userId: params.studentId,
      action: 'STUDENT_JOINED_CLASS',
      targetType: 'CLASS_GROUP',
      targetId: invitation.classGroupId,
      details: {
        className: result.classGroup.name,
      },
    });

    return {
      message: `Successfully joined ${result.classGroup.name}`,
      classGroup: result.classGroup,
    };
  }
}
