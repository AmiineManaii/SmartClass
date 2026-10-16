import type { Role, TeacherApprovalStatus, UserStatus } from './user.entity.js';

export interface TokenPayload {
  sub: string;
  email: string;
  role: Role | null;
  status: UserStatus;
  teacherApprovalStatus?: TeacherApprovalStatus | null;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresIn: number; // in seconds
}
