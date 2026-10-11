import { ConflictError, NotFoundError, ValidationError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface AssignStudentsResult {
  classGroupId: string;
  added: string[];
  memberCount: number;
}

export class AssignStudentsUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(groupId: string, studentIds: string[]): Promise<AssignStudentsResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    const users = await this.groups.findUsersByIds(studentIds);
    const byId = new Map(users.map((user) => [user.id, user]));

    const unknown = studentIds.filter((id) => !byId.has(id));
    if (unknown.length > 0) {
      throw new NotFoundError('One or more users do not exist');
    }

    const nonStudents = studentIds.filter((id) => byId.get(id)?.role !== 'STUDENT');
    if (nonStudents.length > 0) {
      throw new ValidationError(
        'Only STUDENT accounts can be assigned as group members',
        nonStudents.map((id) => ({ path: 'studentIds', message: `User ${id} is not a STUDENT` })),
      );
    }

    const duplicates = await this.groups.existingMemberUserIds(groupId, studentIds);
    if (duplicates.length > 0) {
      throw new ConflictError(
        'One or more users are already members of this group',
        ErrorCodes.ROLE_ALREADY_ASSIGNED,
        duplicates.map((userId) => ({ userId })),
      );
    }

    const { memberCount } = await this.groups.addMembers(groupId, studentIds);

    return { classGroupId: groupId, added: studentIds, memberCount };
  }
}
