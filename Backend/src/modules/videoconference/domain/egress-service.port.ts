export interface StartEgressParams {
  roomName: string;
  sessionId: string;
  storageKey: string;
}

export interface StartEgressResult {
  egressId: string;
  mode: 'livekit-egress' | 'local-composite';
}

export interface StopEgressResult {
  egressId: string;
  sizeBytes: number;
  durationSeconds: number;
}

/**
 * Port for starting and stopping server-side room recordings via LiveKit Egress.
 */
export interface EgressServicePort {
  startRoomRecording(params: StartEgressParams): Promise<StartEgressResult>;
  stopRoomRecording(params: {
    egressId: string;
    storageKey: string;
    startedAt: Date | null;
    sessionTitle?: string;
    subject?: string | null;
    mediaBase64?: string;
    mimeType?: string;
  }): Promise<StopEgressResult>;
}

