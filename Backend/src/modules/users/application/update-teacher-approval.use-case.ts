import type { AuthRepositoryPort, SafeUser, TeacherApprovalStatus } from '../../auth/index.js';
import { BadRequestError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';

export interface UpdateTeacherApprovalResult {
  message: string;
  user: SafeUser;
}

export class UpdateTeacherApprovalUseCase {
  constructor(
    private readonly authRepository: AuthRepositoryPort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(
    adminId: string,
    targetUserId: string,
    status: TeacherApprovalStatus,
  ): Promise<UpdateTeacherApprovalResult> {
    const user = await this.authRepository.findUserById(targetUserId);
    if (!user) {
      throw new NotFoundError('User account not found');
    }

    if (user.role !== 'TEACHER') {
      throw new BadRequestError('User is not a teacher');
    }

    const updatedUser = await this.authRepository.updateUser(targetUserId, {
      teacherApprovalStatus: status,
    });

    await this.authRepository.revokeAllUserTokens(targetUserId);

    await this.auditService?.record({
      userId: adminId,
      action: status === 'APPROVED' ? 'TEACHER_APPROVED' : 'TEACHER_REJECTED',
      targetType: 'USER',
      targetId: targetUserId,
      details: {
        teacherEmail: user.email,
        teacherName: `${user.firstName} ${user.lastName}`,
        status,
      },
    });

    return {
      message: `Teacher account ${status.toLowerCase()} successfully`,
      user: updatedUser.toSafeUser(),
    };
  }
}
