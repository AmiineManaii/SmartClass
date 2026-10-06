export type Role = 'TEACHER' | 'STUDENT' | 'ADMIN';
export type UserStatus = 'ACTIVE' | 'SUSPENDED';

export interface UserEntityProps {
  id: string;
  email: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  role: Role | null;
  birthDate: Date | null;
  status: UserStatus;
  emailVerified: boolean;
  onboardingCompleted: boolean;
  failedLoginAttempts: number;
  lockedUntil: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface SafeUser {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: Role | null;
  birthDate: string | null;
  status: UserStatus;
  emailVerified: boolean;
  onboardingCompleted: boolean;
  createdAt: string;
  updatedAt: string;
}

export class UserEntity {
  constructor(private readonly props: UserEntityProps) {}

  public get id(): string {
    return this.props.id;
  }

  public get email(): string {
    return this.props.email;
  }

  public get passwordHash(): string {
    return this.props.passwordHash;
  }

  public get firstName(): string {
    return this.props.firstName;
  }

  public get lastName(): string {
    return this.props.lastName;
  }

  public get role(): Role | null {
    return this.props.role;
  }

  public get birthDate(): Date | null {
    return this.props.birthDate;
  }

  public get status(): UserStatus {
    return this.props.status;
  }

  public get emailVerified(): boolean {
    return this.props.emailVerified;
  }

  public get onboardingCompleted(): boolean {
    return this.props.onboardingCompleted;
  }

  public get failedLoginAttempts(): number {
    return this.props.failedLoginAttempts;
  }

  public get lockedUntil(): Date | null {
    return this.props.lockedUntil;
  }

  public get createdAt(): Date {
    return this.props.createdAt;
  }

  public get updatedAt(): Date {
    return this.props.updatedAt;
  }

  public isLocked(): boolean {
    if (!this.props.lockedUntil) return false;
    return this.props.lockedUntil.getTime() > Date.now();
  }

  public getLockoutRemainingSeconds(): number {
    if (!this.isLocked() || !this.props.lockedUntil) return 0;
    return Math.max(0, Math.ceil((this.props.lockedUntil.getTime() - Date.now()) / 1000));
  }

  public toSafeUser(): SafeUser {
    return {
      id: this.props.id,
      email: this.props.email,
      firstName: this.props.firstName,
      lastName: this.props.lastName,
      role: this.props.role,
      birthDate: this.props.birthDate ? this.props.birthDate.toISOString().split('T')[0] ?? null : null,
      status: this.props.status,
      emailVerified: this.props.emailVerified,
      onboardingCompleted: this.props.onboardingCompleted,
      createdAt: this.props.createdAt.toISOString(),
      updatedAt: this.props.updatedAt.toISOString(),
    };
  }
}
