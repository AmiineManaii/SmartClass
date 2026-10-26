export class DomainError extends Error {
  constructor(message: string) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class InvalidStateTransitionDomainError extends DomainError {
  constructor(
    public readonly currentStatus: string,
    public readonly targetStatus: string,
  ) {
    super(`Cannot transition video session from ${currentStatus} to ${targetStatus}`);
  }
}

export class SessionValidationDomainError extends DomainError {
  constructor(
    message: string,
    public readonly field?: string,
  ) {
    super(message);
  }
}

export class SessionConflictDomainError extends DomainError {
  constructor(
    message: string,
    public readonly conflictingSessionId?: string,
  ) {
    super(message);
  }
}

export class SessionAccessDeniedDomainError extends DomainError {
  constructor(message = 'Access to this live session is denied') {
    super(message);
  }
}

export class SessionNotJoinableDomainError extends DomainError {
  constructor(
    public readonly reason: 'NOT_STARTED' | 'ENDED' | 'CANCELED' | 'BANNED' | 'NOT_A_MEMBER',
    public readonly joinOpensAt?: Date,
  ) {
    super(`Session is not joinable: ${reason}`);
  }
}

export class SessionStartTooEarlyDomainError extends DomainError {
  constructor(public readonly startsAt: Date) {
    super('Session cannot be started more than 60 minutes before its scheduled start time');
  }
}
