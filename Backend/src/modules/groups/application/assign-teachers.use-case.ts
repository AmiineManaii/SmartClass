import { NotFoundError, ValidationError } from '../../../shared/errors/app-error.js';
import type { TeacherAssignmentView } from '../domain/class-group.entity.js';
import type { GroupRepositoryPort, TeacherAssignInput } from '../domain/group-repository.port.js';

export interface AssignTeachersResult {
  classGroupId: string;
  assigned: TeacherAssignmentView[];
  teacherCount: number;
}

export class AssignTeachersUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(
    groupId: string,
    assignments: TeacherAssignInput[],
  ): Promise<AssignTeachersResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    const teacherIds = assignments.map((assignment) => assignment.teacherId);
    const users = await this.groups.findUsersByIds(teacherIds);
    const byId = new Map(users.map((user) => [user.id, user]));

    const unknown = teacherIds.filter((id) => !byId.has(id));
    if (unknown.length > 0) {
      throw new NotFoundError('One or more users do not exist');
    }

    const nonTeachers = teacherIds.filter((id) => byId.get(id)?.role !== 'TEACHER');
    if (nonTeachers.length > 0) {
      throw new ValidationError(
        'Only TEACHER accounts can be assigned as group teachers',
        nonTeachers.map((id) => ({ path: 'assignments', message: `User ${id} is not a TEACHER` })),
      );
    }

    const { assigned, teacherCount } = await this.groups.upsertTeacherAssignments(
      groupId,
      assignments,
    );

    return { classGroupId: groupId, assigned, teacherCount };
  }
}
