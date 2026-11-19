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

/** Publishing a course while some sections are not yet teacher-validated. */
export class SectionsNotValidatedError extends AppError {
  constructor(message = 'All sections must be validated before publishing', details: unknown[] = []) {
    super(message, 409, ErrorCodes.SECTIONS_NOT_VALIDATED, details);
  }
}

/** Image generation backend (ComfyUI) is not wired up / reachable yet. */
export class ImageServiceUnavailableError extends AppError {
  constructor(message = 'Image generation service is not available yet', details: unknown[] = []) {
    super(message, 503, ErrorCodes.IMAGE_SERVICE_UNAVAILABLE, details);
  }
}

export class SessionNotJoinableError extends AppError {
  constructor(message = 'Session is not joinable at this time', details: unknown[] = []) {
    super(message, 409, ErrorCodes.SESSION_NOT_JOINABLE, details);
  }
}

export class SessionStartTooEarlyError extends AppError {
  constructor(message = 'Session can only be started up to 60 minutes before its scheduled start time', details: unknown[] = []) {
    super(message, 409, ErrorCodes.SESSION_START_TOO_EARLY, details);
  }
}

export class LiveServiceUnavailableError extends AppError {
  constructor(message = 'Live video service is currently unavailable', details: unknown[] = []) {
    super(message, 503, ErrorCodes.LIVE_SERVICE_UNAVAILABLE, details);
  }
}

export class ChatDisabledError extends AppError {
  constructor(message = 'Chat is currently disabled for this session', details: unknown[] = []) {
    super(message, 403, ErrorCodes.CHAT_DISABLED, details);
  }
}

export class RecordingAlreadyActiveError extends AppError {
  constructor(message = 'A recording is already active for this session', details: unknown[] = []) {
    super(message, 409, ErrorCodes.RECORDING_ALREADY_ACTIVE, details);
  }
}

export class RecordingNotActiveError extends AppError {
  constructor(message = 'No active recording is running for this session', details: unknown[] = []) {
    super(message, 409, ErrorCodes.RECORDING_NOT_ACTIVE, details);
  }
}

export class RecordingNotPublishedError extends AppError {
  constructor(message = 'This lesson recording has not been published yet', details: unknown[] = []) {
    super(message, 403, ErrorCodes.RECORDING_NOT_PUBLISHED, details);
  }
}

export class StorageAccessDeniedError extends AppError {
  constructor(message = 'Invalid or unauthorized storage key access', details: unknown[] = []) {
    super(message, 403, ErrorCodes.STORAGE_ACCESS_DENIED, details);
  }
}

/** Exam cannot be started right now (outside its window / not published). */
export class ExamNotAvailableError extends AppError {
  constructor(message = 'Exam is not available right now', details: unknown[] = []) {
    super(message, 409, ErrorCodes.EXAM_NOT_AVAILABLE, details);
  }
}

/** The attempt is already terminal (submitted / auto-submitted / terminated). */
export class ExamAttemptClosedError extends AppError {
  constructor(message = 'This exam attempt is closed and can no longer be modified', details: unknown[] = []) {
    super(message, 409, ErrorCodes.EXAM_ATTEMPT_CLOSED, details);
  }
}

/** Results are not visible until the teacher closes the exam. */
export class ExamResultsNotAvailableError extends AppError {
  constructor(message = 'Results are not available yet', details: unknown[] = []) {
    super(message, 403, ErrorCodes.EXAM_RESULTS_NOT_AVAILABLE, details);
  }
}

/** The configured Ollama model is not installed locally (never auto-pull). */
export class AiModelUnavailableError extends AppError {
  constructor(message = 'The configured local AI model is not available', details: unknown[] = []) {
    super(message, 503, ErrorCodes.AI_MODEL_UNAVAILABLE, details);
  }
}

/** The local model answered with a payload that does not satisfy the schema. */
export class AiInvalidOutputError extends AppError {
  constructor(message = 'The local AI returned an invalid exam payload', details: unknown[] = []) {
    super(message, 502, ErrorCodes.AI_INVALID_OUTPUT, details);
  }
}

/**
 * The local model is reachable but did not finish within `AI_TIMEOUT_MS`.
 * Distinct from an unreachable model: the fix is to retry with fewer
 * questions, not to start Ollama.
 */
export class AiTimeoutError extends AppError {
  constructor(
    message = 'The local AI model took too long to answer. Retry with fewer questions.',
    details: unknown[] = [],
  ) {
    super(message, 504, ErrorCodes.AI_TIMEOUT, details);
  }
}

export class ImportFormatUnsupportedError extends AppError {
  constructor(message = 'Unsupported import format', details: unknown[] = []) {
    super(message, 422, ErrorCodes.IMPORT_FORMAT_UNSUPPORTED, details);
  }
}

export class InternalError extends AppError {
  constructor(message = 'Internal server error', details: unknown[] = []) {
    super(message, 500, ErrorCodes.INTERNAL_ERROR, details, false);
  }
}
