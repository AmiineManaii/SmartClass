import type { SessionChatMessage } from '../domain/video-session.entity.js';
import type { SessionChatRepositoryPort } from '../domain/session-chat-repository.port.js';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';

export class PrismaSessionChatRepositoryAdapter implements SessionChatRepositoryPort {
  constructor(private readonly prisma = getPrismaClient()) {}

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapToDomain(row: any): SessionChatMessage {
    const senderDisplayName =
      row.sender &&
      typeof row.sender.firstName === 'string' &&
      typeof row.sender.lastName === 'string'
        ? `${row.sender.firstName} ${row.sender.lastName}`
        : 'Utilisateur';

    return {
      id: row.id,
      sessionId: row.sessionId,
      senderId: row.senderId,
      clientMessageId: row.clientMessageId,
      senderDisplayName,
      senderRole: row.sender?.role ?? 'STUDENT',
      content: row.content,
      createdAt: row.createdAt,
    };
  }

  public async createMessage(
    message: Omit<SessionChatMessage, 'id' | 'createdAt'>,
  ): Promise<SessionChatMessage> {
    const row = await this.prisma.sessionChatMessage.create({
      data: {
        sessionId: message.sessionId,
        senderId: message.senderId,
        clientMessageId: message.clientMessageId,
        content: message.content,
      },
      include: {
        sender: {
          select: { firstName: true, lastName: true, role: true },
        },
      },
    });

    return this.mapToDomain(row);
  }

  public async findByClientMessageId(
    sessionId: string,
    senderId: string,
    clientMessageId: string,
  ): Promise<SessionChatMessage | null> {
    const row = await this.prisma.sessionChatMessage.findUnique({
      where: {
        sessionId_senderId_clientMessageId: {
          sessionId,
          senderId,
          clientMessageId,
        },
      },
      include: {
        sender: {
          select: { firstName: true, lastName: true, role: true },
        },
      },
    });

    return row ? this.mapToDomain(row) : null;
  }

  public async listBySession(
    sessionId: string,
    offset: number,
    limit: number,
  ): Promise<{ items: SessionChatMessage[]; total: number }> {
    const where = { sessionId };

    const [rows, total] = await Promise.all([
      this.prisma.sessionChatMessage.findMany({
        where,
        include: {
          sender: {
            select: { firstName: true, lastName: true, role: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: offset,
        take: limit,
      }),
      this.prisma.sessionChatMessage.count({ where }),
    ]);

    return {
      items: rows.map((r) => this.mapToDomain(r)),
      total,
    };
  }
}
