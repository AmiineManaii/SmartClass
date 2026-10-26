import { SessionValidationDomainError } from './domain-errors.js';

export interface ScheduleValidationParams {
  startsAt: Date;
  endsAt?: Date;
  durationMinutes?: number;
  joinOpensMinutesBefore?: number;
  now: Date;
  isStartNow?: boolean;
}

export interface ValidatedSchedule {
  startsAt: Date;
  endsAt: Date;
  durationMinutes: number;
  joinOpensMinutesBefore: number;
}

export const validateSessionSchedule = (
  params: ScheduleValidationParams,
): ValidatedSchedule => {
  const joinOpensMinutesBefore = params.joinOpensMinutesBefore ?? 5;
  if (joinOpensMinutesBefore < 0 || joinOpensMinutesBefore > 30) {
    throw new SessionValidationDomainError(
      'joinOpensMinutesBefore must be between 0 and 30 minutes',
      'joinOpensMinutesBefore',
    );
  }

  let durationMinutes = params.durationMinutes;
  let endsAt = params.endsAt;
  const startsAt = params.startsAt;

  if (endsAt) {
    if (endsAt.getTime() <= startsAt.getTime()) {
      throw new SessionValidationDomainError('endsAt must be strictly after startsAt', 'endsAt');
    }
    const computedDuration = Math.round((endsAt.getTime() - startsAt.getTime()) / (60 * 1000));
    durationMinutes = computedDuration;
  } else {
    durationMinutes = durationMinutes ?? 60;
    endsAt = new Date(startsAt.getTime() + durationMinutes * 60 * 1000);
  }

  if (durationMinutes < 5 || durationMinutes > 480) {
    throw new SessionValidationDomainError(
      'Session duration must be between 5 and 480 minutes (8 hours)',
      'durationMinutes',
    );
  }

  const nowMs = params.now.getTime();
  const startsAtMs = startsAt.getTime();

  if (!params.isStartNow) {
    // Cannot schedule in the past (allow 1 minute grace period for network latency)
    if (startsAtMs < nowMs - 60 * 1000) {
      throw new SessionValidationDomainError(
        'Scheduled session start time cannot be in the past',
        'startsAt',
      );
    }

    // Horizon max 365 days
    const maxHorizonMs = nowMs + 365 * 24 * 60 * 60 * 1000;
    if (startsAtMs > maxHorizonMs) {
      throw new SessionValidationDomainError(
        'Scheduled session start time cannot exceed 365 days into the future',
        'startsAt',
      );
    }
  }

  return {
    startsAt,
    endsAt,
    durationMinutes,
    joinOpensMinutesBefore,
  };
};

export const validateSessionTitle = (title: string): string => {
  const trimmed = title.trim();
  if (trimmed.length < 3 || trimmed.length > 200) {
    throw new SessionValidationDomainError(
      'Session title must be between 3 and 200 characters',
      'title',
    );
  }
  return trimmed;
};

export const validateChatMessageContent = (content: string): string => {
  const trimmed = content.trim();
  if (trimmed.length < 1 || trimmed.length > 2000) {
    throw new SessionValidationDomainError(
      'Chat message content must be between 1 and 2000 characters',
      'content',
    );
  }
  return trimmed;
};
