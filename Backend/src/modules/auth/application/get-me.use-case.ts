import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';
import type { SafeUser } from '../domain/user.entity.js';
import { NotFoundError } from '../../../shared/errors/app-error.js';

export interface GetMeResult {
  user: SafeUser;
}

export class GetMeUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(userId: string): Promise<GetMeResult> {
    const user = await this.authRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User account not found');
    }

    return {
      user: user.toSafeUser(),
    };
  }
}
