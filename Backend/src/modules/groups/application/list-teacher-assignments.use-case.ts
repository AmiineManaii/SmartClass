import { NotFoundError } from '../../../shared/errors/app-error.js';
import type {
  GroupRepositoryPort,
  TeacherAssignmentDetail,
} from '../domain/group-repository.port.js';

export interface ListTeacherAssignmentsResult {
  assignments: TeacherAssignmentDetail[];
  teacherCount: number;
}

export class ListTeacherAssignmentsUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(groupId: string): Promise<ListTeacherAssignmentsResult> {
    const group = await this.groups.findGroupDetailById(groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    const assignments = await this.groups.listTeacherAssignments(groupId);

    return { assignments, teacherCount: assignments.length };
  }
}
