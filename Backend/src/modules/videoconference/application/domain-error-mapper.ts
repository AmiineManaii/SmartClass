import {
  ValidationError,
  ConflictError,
  ForbiddenError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import {
  SessionValidationDomainError,
  SessionConflictDomainError,
  SessionAccessDeniedDomainError,
  InvalidStateTransitionDomainError,
  SessionStartTooEarlyDomainError,
  SessionNotJoinableDomainError,
} from '../domain/domain-errors.js';

export const mapDomainErrorToAppError = (err: unknown): unknown => {
  if (err instanceof SessionValidationDomainError) {
    return new ValidationError(err.message, [
      { path: err.field ?? 'body', message: err.message },
    ]);
  }
  if (err instanceof SessionConflictDomainError) {
    return new ConflictError(err.message, ErrorCodes.CONFLICT);
  }
  if (err instanceof InvalidStateTransitionDomainError) {
    return new ConflictError(err.message, ErrorCodes.CONFLICT);
  }
  if (err instanceof SessionAccessDeniedDomainError) {
    return new ForbiddenError(err.message, ErrorCodes.FORBIDDEN);
  }
  if (err instanceof SessionStartTooEarlyDomainError) {
    return new ConflictError(err.message, ErrorCodes.SESSION_START_TOO_EARLY);
  }
  if (err instanceof SessionNotJoinableDomainError) {
    return new ConflictError(err.message, ErrorCodes.SESSION_NOT_JOINABLE);
  }
  return err;
};
