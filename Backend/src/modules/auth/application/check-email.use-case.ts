import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';

export interface CheckEmailResult {
  available: boolean;
  email: string;
}

export class CheckEmailUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(email: string): Promise<CheckEmailResult> {
    // Mirrors the register duplicate condition exactly: any existing
    // account (verified or not) makes the address unavailable.
    const existingUser = await this.authRepository.findUserByEmail(email);

    return {
      available: existingUser === null,
      email,
    };
  }
}
