import { WebhookReceiver } from 'livekit-server-sdk';
import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { SessionParticipantRepositoryPort } from '../domain/session-participant-repository.port.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { getEnv } from '../../../config/env.js';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';

export class ReceiveLiveKitWebhookUseCase {
  private readonly receiver: WebhookReceiver;
  private readonly processedEventIds = new Set<string>();

  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly participantRepository: SessionParticipantRepositoryPort,
    options?: { apiKey?: string; apiSecret?: string },
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {
    const env = getEnv();
    const apiKey = options?.apiKey ?? env.LIVEKIT_API_KEY ?? 'devkey';
    const apiSecret =
      options?.apiSecret ?? env.LIVEKIT_API_SECRET ?? 'secret-should-be-at-least-32-chars-long';
    this.receiver = new WebhookReceiver(apiKey, apiSecret);
  }

  public async execute(
    body: string | Buffer,
    authHeader?: string,
  ): Promise<{ received: boolean }> {
    if (!authHeader) {
      throw new UnauthorizedError('Missing LiveKit webhook authorization header');
    }

    let event;
    try {
      const bodyStr = typeof body === 'string' ? body : body.toString('utf-8');
      event = await this.receiver.receive(bodyStr, authHeader);
    } catch (err) {
      logger.warn({ err }, 'Failed to verify LiveKit webhook signature');
      throw new UnauthorizedError('Invalid LiveKit webhook signature');
    }

    if (!event || !event.id) {
      return { received: true };
    }

    // Deduplication by event ID
    if (this.processedEventIds.has(event.id)) {
      return { received: true };
    }
    this.processedEventIds.add(event.id);
    if (this.processedEventIds.size > 10000) {
      // Clear oldest entries
      const first = this.processedEventIds.values().next().value;
      if (first) this.processedEventIds.delete(first);
    }

    const roomName = event.room?.name;
    if (!roomName) {
      return { received: true };
    }

    const session = await this.sessionRepository.findByRoomName(roomName);
    if (!session) {
      return { received: true };
    }

    const userId = event.participant?.identity;

    switch (event.event) {
      case 'participant_joined':
        if (userId) {
          const now = new Date();
          await this.participantRepository.recordJoin(session.id, userId, now);
          try {
            await this.eventsPublisher?.publishToClass(session.classGroupId, {
              type: 'session.participant-joined',
              sessionId: session.id,
              classGroupId: session.classGroupId,
              status: session.status,
              at: now.toISOString(),
              data: { userId },
            });
          } catch {
            // ignore SSE publish error
          }
        }
        break;

      case 'participant_left':
        if (userId) {
          const now = new Date();
          await this.participantRepository.recordLeave(session.id, userId, now);
          try {
            await this.eventsPublisher?.publishToClass(session.classGroupId, {
              type: 'session.participant-left',
              sessionId: session.id,
              classGroupId: session.classGroupId,
              status: session.status,
              at: now.toISOString(),
              data: { userId },
            });
          } catch {
            // ignore SSE publish error
          }
        }
        break;

      case 'room_finished':
        // ADR-0008: LiveKit room empty/finished does NOT terminate logical business session
        logger.info(
          { sessionId: session.id, roomName },
          'LiveKit media room finished/empty; session remains IN_PROGRESS until host explicitly ends it',
        );
        break;

      default:
        break;
    }

    return { received: true };
  }
}
