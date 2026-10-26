export interface JoinTokenPermissions {
  canPublish: boolean;
  canPublishData: boolean;
  canSubscribe: boolean;
  hidden: boolean;
  canPublishSources: string[];
}

export interface JoinTokenResult {
  token: string;
  url: string;
  expiresAt: Date;
  role: 'host' | 'student' | 'admin';
  permissions: JoinTokenPermissions;
}

export interface RoomServicePort {
  createRoom(roomName: string, emptyTimeoutMinutes: number): Promise<void>;
  issueJoinToken(params: {
    roomName: string;
    identity: string;
    name: string;
    isHost: boolean;
    isAdmin: boolean;
    ttlSeconds: number;
  }): Promise<JoinTokenResult>;
  muteParticipant(roomName: string, identity: string): Promise<void>;
  muteAll(roomName: string): Promise<void>;
  removeParticipant(roomName: string, identity: string): Promise<void>;
  closeRoom(roomName: string): Promise<void>;
  getParticipantCount?(roomName: string): Promise<number>;
}
