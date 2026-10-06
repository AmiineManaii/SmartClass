import type { TokenPayload } from './auth-tokens.js';

export interface TokenServicePort {
  generateAccessToken(payload: TokenPayload): Promise<{ token: string; expiresIn: number }>;
  generateRefreshToken(): string;
  verifyAccessToken(token: string): Promise<TokenPayload>;
  hashRefreshToken(token: string): string;
}
