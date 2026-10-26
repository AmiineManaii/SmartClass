export type VideoSessionStatus = 'SCHEDULED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELED';

export type SessionPhase = 'UPCOMING' | 'JOIN_OPEN' | 'LIVE' | 'ENDED' | 'CANCELED';

export interface VideoSession {
  id: string;
  classGroupId: string;
  hostId: string | null;
  hostName?: string | null;
  subject: string | null;
  title: string;
  description: string | null;
  startsAt: Date;
  endsAt: Date;
  startedAt: Date | null;
  endedAt: Date | null;
  status: VideoSessionStatus;
  roomName: string;
  joinOpensMinutesBefore: number;
  chatEnabled: boolean;
  timetableSlotId: string | null;
  courseId: string | null;
  cancelReason: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface SessionParticipant {
  id: string;
  sessionId: string;
  userId: string;
  userDisplayName?: string | null;
  userRole?: string | null;
  joinedAt: Date;
  leftAt: Date | null;
}

export interface SessionChatMessage {
  id: string;
  sessionId: string;
  senderId: string;
  clientMessageId: string;
  senderDisplayName: string;
  senderRole: string;
  content: string;
  createdAt: Date;
}

export interface SessionParticipantRemoval {
  id: string;
  sessionId: string;
  userId: string;
  removedById: string;
  reason: string | null;
  removedAt: Date;
}
