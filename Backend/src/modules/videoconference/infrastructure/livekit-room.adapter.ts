import { RoomServiceClient, AccessToken, TrackSource, TrackType } from 'livekit-server-sdk';
import type {
  RoomServicePort,
  JoinTokenResult,
  JoinTokenPermissions,
} from '../domain/room-service.port.js';
import { getEnv } from '../../../config/env.js';

export class LiveKitRoomAdapter implements RoomServicePort {
  private readonly client: RoomServiceClient;
  private readonly apiKey: string;
  private readonly apiSecret: string;
  private readonly publicUrl: string;

  constructor(options?: {
    url?: string;
    publicUrl?: string;
    apiKey?: string;
    apiSecret?: string;
  }) {
    const env = getEnv();
    const url = options?.url || env.LIVEKIT_URL || 'http://livekit:7880';
    this.publicUrl = options?.publicUrl || env.LIVEKIT_PUBLIC_URL || 'ws://localhost:7880';
    this.apiKey = options?.apiKey || env.LIVEKIT_API_KEY || 'devkey';
    this.apiSecret =
      options?.apiSecret ||
      env.LIVEKIT_API_SECRET ||
      'secretsecretsecretsecretsecretsecret32';

    this.client = new RoomServiceClient(url, this.apiKey, this.apiSecret);
  }

  public async createRoom(roomName: string, emptyTimeoutMinutes = 10): Promise<void> {
    try {
      await this.client.createRoom({
        name: roomName,
        emptyTimeout: emptyTimeoutMinutes * 60,
      });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.toLowerCase().includes('already exists')) {
        // Room already exists; idempotent success
        return;
      }
      throw err;
    }
  }

  public async issueJoinToken(params: {
    roomName: string;
    identity: string;
    name: string;
    isHost: boolean;
    isAdmin: boolean;
    ttlSeconds: number;
  }): Promise<JoinTokenResult> {
    const role: 'host' | 'student' | 'admin' = params.isAdmin
      ? 'admin'
      : params.isHost
        ? 'host'
        : 'student';

    const canShareScreen = params.isHost || params.isAdmin;
    const sources = canShareScreen
      ? [
          TrackSource.CAMERA,
          TrackSource.MICROPHONE,
          TrackSource.SCREEN_SHARE,
          TrackSource.SCREEN_SHARE_AUDIO,
        ]
      : [TrackSource.CAMERA, TrackSource.MICROPHONE];

    const permissions: JoinTokenPermissions = {
      canPublish: true,
      canPublishData: true,
      canSubscribe: true,
      hidden: false,
      canPublishSources: canShareScreen
        ? ['camera', 'microphone', 'screen_share', 'screen_share_audio']
        : ['camera', 'microphone'],
    };

    const at = new AccessToken(this.apiKey, this.apiSecret, {
      identity: params.identity,
      name: params.name,
      ttl: params.ttlSeconds,
    });

    at.addGrant({
      roomJoin: true,
      room: params.roomName,
      canPublish: true,
      canPublishData: true,
      canSubscribe: true,
      canPublishSources: sources,
      hidden: permissions.hidden,
      roomAdmin: false, // Security: Never grant roomAdmin to participant client tokens
    });

    const token = await at.toJwt();
    const expiresAt = new Date(Date.now() + params.ttlSeconds * 1000);

    return {
      token,
      url: this.publicUrl,
      expiresAt,
      role,
      permissions,
    };
  }

  public async muteParticipant(roomName: string, identity: string): Promise<void> {
    try {
      const participant = await this.client.getParticipant(roomName, identity);
      for (const track of participant.tracks) {
        if (track.type === TrackType.AUDIO && !track.muted) {
          await this.client.mutePublishedTrack(roomName, identity, track.sid, true);
        }
      }
    } catch (err: unknown) {
      // If participant not found or room closed, ignore gracefully
      const message = err instanceof Error ? err.message : String(err);
      if (message.toLowerCase().includes('not found')) {
        return;
      }
      throw err;
    }
  }

  public async muteAll(roomName: string): Promise<void> {
    try {
      const participants = await this.client.listParticipants(roomName);
      for (const p of participants) {
        for (const track of p.tracks) {
          if (track.type === TrackType.AUDIO && !track.muted) {
            await this.client.mutePublishedTrack(roomName, p.identity, track.sid, true);
          }
        }
      }
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.toLowerCase().includes('not found')) {
        return;
      }
      throw err;
    }
  }

  public async removeParticipant(roomName: string, identity: string): Promise<void> {
    try {
      await this.client.removeParticipant(roomName, identity);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.toLowerCase().includes('not found')) {
        return;
      }
      throw err;
    }
  }

  public async closeRoom(roomName: string): Promise<void> {
    try {
      await this.client.deleteRoom(roomName);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.toLowerCase().includes('not found')) {
        return;
      }
      throw err;
    }
  }

  public async getParticipantCount(roomName: string): Promise<number> {
    try {
      const participants = await this.client.listParticipants(roomName);
      return participants.length;
    } catch {
      return 0;
    }
  }
}
