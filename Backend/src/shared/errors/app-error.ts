import { ErrorCodes, type ErrorCode } from './error-codes.js';

export interface ErrorDetail {
  path: string;
  message: string;
}

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: ErrorCode;
  public readonly details: unknown[];
  public readonly isOperational: boolean;

  constructor(
    message: string,
    statusCode: number,
    code: ErrorCode,
    details: unknown[] = [],
    isOperational = true,
  ) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = isOperational;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class BadRequestError extends AppError {
  constructor(message = 'Bad request', details: unknown[] = []) {
    super(message, 400, ErrorCodes.BAD_REQUEST, details);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized', code: ErrorCode = ErrorCodes.AUTH_TOKEN_INVALID, details: unknown[] = []) {
    super(message, 401, code, details);
  }
}

export class AccountLockedError extends AppError {
  constructor(
    message = 'Account temporarily locked due to multiple failed login attempts. Please try again later.',
    details: unknown[] = [],
  ) {
    super(message, 423, ErrorCodes.AUTH_ACCOUNT_LOCKED, details);
  }
}

export class ForbiddenError extends AppError {
  constructor(message = 'Forbidden', code: ErrorCode = ErrorCodes.FORBIDDEN, details: unknown[] = []) {
    super(message, 403, code, details);
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'Resource not found', details: unknown[] = []) {
    super(message, 404, ErrorCodes.NOT_FOUND, details);
  }
}

export class ConflictError extends AppError {
  constructor(message = 'Conflict occurred', code: ErrorCode = ErrorCodes.CONFLICT, details: unknown[] = []) {
    super(message, 409, code, details);
  }
}

export class ValidationError extends AppError {
  constructor(message = 'Validation failed', details: ErrorDetail[] = []) {
    super(message, 422, ErrorCodes.VALIDATION_ERROR, details);
  }
}

export class TooManyRequestsError extends AppError {
  constructor(message = 'Too many requests, please try again later', details: unknown[] = []) {
    super(message, 429, ErrorCodes.RATE_LIMITED, details);
  }
}

export class ServiceUnavailableError extends AppError {
  constructor(message = 'Service unavailable', details: unknown[] = []) {
    super(message, 503, ErrorCodes.SERVICE_UNAVAILABLE, details);
  }
}

export class InternalError extends AppError {
  constructor(message = 'Internal server error', details: unknown[] = []) {
    super(message, 500, ErrorCodes.INTERNAL_ERROR, details, false);
  }
}
