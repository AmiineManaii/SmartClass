import type { GroupRepositoryPort } from '../domain/group-repository.port.js';
import { BadRequestError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';

export interface LeaveClassParams {
  groupId: string;
  studentId: string;
}

export class LeaveClassUseCase {
  constructor(
    private readonly groupRepository: GroupRepositoryPort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(params: LeaveClassParams): Promise<{ message: string }> {
    const group = await this.groupRepository.findGroupDetailById(params.groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    const removed = await this.groupRepository.leaveGroup(params.groupId, params.studentId);
    if (!removed) {
      throw new BadRequestError('You are not enrolled in this class');
    }

    await this.auditService?.record({
      userId: params.studentId,
      action: 'STUDENT_LEFT_CLASS',
      targetType: 'CLASS_GROUP',
      targetId: params.groupId,
      details: {
        className: group.name,
      },
    });

    return { message: `Successfully left ${group.name}` };
  }
}
