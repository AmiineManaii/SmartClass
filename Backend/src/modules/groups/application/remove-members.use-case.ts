import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';

export interface RemoveMembersResult {
  classGroupId: string;
  removed: string[];
  memberCount: number;
}

export class RemoveMembersUseCase {
  constructor(
    private readonly groups: GroupRepositoryPort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(
    groupId: string,
    studentIds: string[],
    actorId?: string,
    actorRole?: string,
  ): Promise<RemoveMembersResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    if (actorRole && actorRole !== 'ADMIN') {
      if (!actorId) {
        throw new ForbiddenError('Authentication required');
      }
      const isAuthorized = await this.groups.isTeacherAuthorizedForGroup(groupId, actorId);
      if (!isAuthorized) {
        throw new ForbiddenError('You are not authorized to remove students from this class');
      }
    }

    const { removed, memberCount } = await this.groups.removeMembers(groupId, studentIds);

    if (actorId) {
      await this.auditService?.record({
        userId: actorId,
        action: 'STUDENTS_REMOVED_FROM_CLASS',
        targetType: 'CLASS_GROUP',
        targetId: groupId,
        details: {
          removedCount: removed.length,
          studentIds: removed,
        },
      });
    }

    return { classGroupId: groupId, removed, memberCount };
  }
}
