import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface RemoveTeacherAssignmentsResult {
  classGroupId: string;
  removed: string[];
  teacherCount: number;
}

export class RemoveTeacherAssignmentsUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(
    groupId: string,
    teacherIds: string[],
  ): Promise<RemoveTeacherAssignmentsResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    const { removed, teacherCount } = await this.groups.removeTeacherAssignments(
      groupId,
      teacherIds,
    );

    return { classGroupId: groupId, removed, teacherCount };
  }
}
