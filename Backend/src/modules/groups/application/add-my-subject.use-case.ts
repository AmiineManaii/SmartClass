import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { TeacherAssignmentView } from '../domain/class-group.entity.js';
import type { GroupRepositoryPort } from '../domain/group-repository.port.js';

export interface AddMySubjectParams {
  groupId: string;
  teacherId: string;
  actorRole: string;
  subject: string;
  weeklyHours?: string | null;
}

export interface AddMySubjectResult {
  assignment: TeacherAssignmentView;
}

export class AddMySubjectUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(params: AddMySubjectParams): Promise<AddMySubjectResult> {
    if (params.actorRole !== 'TEACHER') {
      throw new ForbiddenError('Only teachers can add subjects to their classes');
    }

    const group = await this.groups.findGroupDetailById(params.groupId);
    if (!group) {
      throw new NotFoundError('Class group not found');
    }

    const membership = await this.groups.findUserClassMembership(
      params.groupId,
      params.teacherId,
    );
    if (!membership.isTeacher && !membership.isReferent && !membership.isOwner) {
      throw new ForbiddenError('You are not authorized to teach in this class');
    }

    const assignment = await this.groups.addTeacherSubject(params.groupId, params.teacherId, {
      subject: params.subject.trim(),
      weeklyHours: params.weeklyHours?.trim() || null,
    });

    return { assignment };
  }
}
