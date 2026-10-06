import type { Role, UserStatus } from './user.entity.js';

export interface TokenPayload {
  sub: string;
  email: string;
  role: Role | null;
  status: UserStatus;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresIn: number; // in seconds
}
