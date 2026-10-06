import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { SafeUser } from '../domain/user.entity.js';
import { NotFoundError } from '../../../shared/errors/app-error.js';

export interface UpdateProfileDTO {
  firstName?: string;
  lastName?: string;
  birthDate?: string | null;
  onboardingCompleted?: boolean;
}

export interface UpdateProfileResult {
  message: string;
  user: SafeUser;
}

export class UpdateProfileUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(userId: string, dto: UpdateProfileDTO): Promise<UpdateProfileResult> {
    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User account not found');
    }

    const updateParams: {
      firstName?: string;
      lastName?: string;
      birthDate?: Date | null;
      onboardingCompleted?: boolean;
    } = {};

    if (dto.firstName !== undefined) updateParams.firstName = dto.firstName;
    if (dto.lastName !== undefined) updateParams.lastName = dto.lastName;
    if (dto.birthDate !== undefined) {
      updateParams.birthDate = dto.birthDate ? new Date(dto.birthDate) : null;
    }
    if (dto.onboardingCompleted !== undefined) {
      updateParams.onboardingCompleted = dto.onboardingCompleted;
    }

    const updatedUser = await this.authRepository.updateUser(userId, updateParams);

    return {
      message: 'Profile updated successfully',
      user: updatedUser.toSafeUser(),
    };
  }
}
