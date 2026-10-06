import argon2 from 'argon2';
import type { PasswordHasherPort } from '../domain/password-hasher.port.js';

export class Argon2PasswordHasherAdapter implements PasswordHasherPort {
  public async hash(password: string): Promise<string> {
    return argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 65536, // 64 MB
      timeCost: 3,
      parallelism: 4,
    });
  }

  public async verify(password: string, hash: string): Promise<boolean> {
    try {
      return await argon2.verify(hash, password);
    } catch {
      return false;
    }
  }
}
