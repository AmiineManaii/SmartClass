import * as jose from 'jose';
import crypto from 'node:crypto';
import type { TokenServicePort } from '../domain/token-service.port.js';
import type { TokenPayload } from '../domain/auth-tokens.js';
import type { Role, UserStatus } from '../domain/user.entity.js';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface JoseTokenServiceOptions {
  jwtSecret: string;
  accessExpiration?: string; // e.g. '15m'
}

export class JoseTokenServiceAdapter implements TokenServicePort {
  private readonly secretKey: Uint8Array;
  private readonly accessExpiration: string;

  constructor(options: JoseTokenServiceOptions) {
    this.secretKey = new TextEncoder().encode(options.jwtSecret);
    this.accessExpiration = options.accessExpiration ?? '15m';
  }

  public async generateAccessToken(
    payload: TokenPayload,
  ): Promise<{ token: string; expiresIn: number }> {
    const expiresInSeconds = 15 * 60; // 15 minutes default

    const token = await new jose.SignJWT({
      email: payload.email,
      role: payload.role,
      status: payload.status,
    })
      .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
      .setSubject(payload.sub)
      .setIssuedAt()
      .setExpirationTime(this.accessExpiration)
      .sign(this.secretKey);

    return { token, expiresIn: expiresInSeconds };
  }

  public generateRefreshToken(): string {
    return crypto.randomBytes(40).toString('hex');
  }

  public async verifyAccessToken(token: string): Promise<TokenPayload> {
    try {
      const { payload } = await jose.jwtVerify(token, this.secretKey, {
        algorithms: ['HS256'],
      });

      if (!payload.sub || typeof payload.email !== 'string') {
        throw new UnauthorizedError('Invalid token payload', ErrorCodes.AUTH_TOKEN_INVALID);
      }

      return {
        sub: payload.sub,
        email: payload.email,
        role: (payload.role as Role) || null,
        status: (payload.status as UserStatus) || 'ACTIVE',
      };
    } catch (err: unknown) {
      if (err instanceof jose.errors.JWTExpired) {
        throw new UnauthorizedError('Access token has expired', ErrorCodes.AUTH_TOKEN_EXPIRED);
      }
      if (err instanceof UnauthorizedError) {
        throw err;
      }
      throw new UnauthorizedError('Invalid access token', ErrorCodes.AUTH_TOKEN_INVALID);
    }
  }

  public hashRefreshToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
