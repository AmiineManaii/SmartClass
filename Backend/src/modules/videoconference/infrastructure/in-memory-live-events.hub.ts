import type { Request, Response } from 'express';
import { randomUUID } from 'node:crypto';
import type {
  LiveEventsPublisherPort,
  SessionEventPayload,
} from '../domain/live-events-publisher.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import { logger } from '../../../shared/infrastructure/logger.js';

export interface SSEClientConnection {
  id: string;
  userId: string;
  sessionId?: string;
  res: Response;
  connectedAt: Date;
  cleanup: () => void;
}

export class InMemoryLiveEventsHub implements LiveEventsPublisherPort {
  private static readonly MAX_CONNECTIONS_PER_USER = 3;
  private readonly connections = new Map<string, Set<SSEClientConnection>>();

  constructor(private readonly classAccess: ClassAccessPort) {}

  public subscribe(
    userId: string,
    res: Response,
    req: Request,
    sessionId?: string,
  ): () => void {
    let userConns = this.connections.get(userId);
    if (!userConns) {
      userConns = new Set<SSEClientConnection>();
      this.connections.set(userId, userConns);
    }

    // Enforce max 3 connections per user by dropping oldest connection gracefully
    if (userConns.size >= InMemoryLiveEventsHub.MAX_CONNECTIONS_PER_USER) {
      const oldest = Array.from(userConns).sort(
        (a, b) => a.connectedAt.getTime() - b.connectedAt.getTime(),
      )[0];
      if (oldest) {
        oldest.cleanup();
      }
    }

    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-store',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no',
    });

    res.write(': connected\n\n');

    let closed = false;
    let heartbeat: NodeJS.Timeout | null = null;

    const cleanup = (): void => {
      if (closed) return;
      closed = true;
      if (heartbeat) {
        clearInterval(heartbeat);
        heartbeat = null;
      }

      const currentSet = this.connections.get(userId);
      if (currentSet) {
        currentSet.delete(clientConn);
        if (currentSet.size === 0) {
          this.connections.delete(userId);
        }
      }

      try {
        if (!res.writableEnded) {
          res.end();
        }
      } catch {
        // ignore connection end error
      }
    };

    const clientConn: SSEClientConnection = {
      id: randomUUID(),
      userId,
      sessionId,
      res,
      connectedAt: new Date(),
      cleanup,
    };

    userConns.add(clientConn);

    heartbeat = setInterval(() => {
      if (closed) return;
      try {
        res.write(': ping\n\n');
      } catch {
        cleanup();
      }
    }, 10_000);

    req.on('close', cleanup);
    req.on('error', cleanup);
    res.on('error', cleanup);
    res.on('finish', cleanup);

    return cleanup;
  }

  public async publishToAudience(
    audienceUserIds: string[],
    event: SessionEventPayload,
  ): Promise<void> {
    const rawData = `event: ${event.type}\ndata: ${JSON.stringify(event)}\n\n`;

    for (const userId of audienceUserIds) {
      const conns = this.connections.get(userId);
      if (!conns || conns.size === 0) continue;

      for (const conn of Array.from(conns)) {
        // If client requested filter for a specific session, respect it
        if (conn.sessionId && event.sessionId && conn.sessionId !== event.sessionId) {
          continue;
        }

        try {
          conn.res.write(rawData);
        } catch (error) {
          logger.warn({ error, userId, connId: conn.id }, 'Error writing to SSE connection, closing');
          conn.cleanup();
        }
      }
    }
  }

  public async publishToClass(classGroupId: string, event: SessionEventPayload): Promise<void> {
    try {
      const audience = await this.classAccess.getClassMemberUserIds(classGroupId);
      await this.publishToAudience(audience, event);
    } catch (error) {
      logger.warn({ error, classGroupId, eventType: event.type }, 'Failed to publish event to class');
    }
  }

  public getActiveConnectionCount(): number {
    let count = 0;
    for (const set of this.connections.values()) {
      count += set.size;
    }
    return count;
  }

  public getUserConnectionCount(userId: string): number {
    return this.connections.get(userId)?.size ?? 0;
  }

  public destroy(): void {
    for (const set of this.connections.values()) {
      for (const conn of Array.from(set)) {
        conn.cleanup();
      }
    }
    this.connections.clear();
  }
}
