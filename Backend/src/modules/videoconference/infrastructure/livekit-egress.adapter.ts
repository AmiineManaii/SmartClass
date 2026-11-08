import { execFile } from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import { promisify } from 'node:util';
import { EgressClient, EncodedFileOutput, EncodedFileType } from 'livekit-server-sdk';
import { getEnv } from '../../../config/env.js';
import type { StoragePort } from '../../../shared/storage/storage.port.js';
import type {
  EgressServicePort,
  StartEgressParams,
  StartEgressResult,
  StopEgressResult,
} from '../domain/egress-service.port.js';

const execFileAsync = promisify(execFile);

export const sanitizeFfmpegText = (raw: string): string =>
  raw
    .replace(/[\\':%\n\r\t]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 64);

export class LiveKitEgressAdapter implements EgressServicePort {
  private readonly client: EgressClient;
  private readonly ffmpegPath: string;
  private readonly ffprobePath: string;

  constructor(
    private readonly storage: StoragePort,
    options?: {
      url?: string;
      apiKey?: string;
      apiSecret?: string;
      ffmpegPath?: string;
      ffprobePath?: string;
    },
  ) {
    const env = getEnv();
    const url = options?.url || env.LIVEKIT_URL || 'http://livekit:7880';
    const apiKey = options?.apiKey || env.LIVEKIT_API_KEY || 'devkey';
    const apiSecret =
      options?.apiSecret || env.LIVEKIT_API_SECRET || 'secretsecretsecretsecretsecretsecret32';
    this.ffmpegPath = options?.ffmpegPath || env.FFMPEG_PATH || 'ffmpeg';
    this.ffprobePath = options?.ffprobePath || env.FFPROBE_PATH || 'ffprobe';
    this.client = new EgressClient(url, apiKey, apiSecret);
  }

  public async startRoomRecording(params: StartEgressParams): Promise<StartEgressResult> {
    const absoluteTarget = this.storage.resolveSafePath(params.storageKey);
    await fs.mkdir(path.dirname(absoluteTarget), { recursive: true });

    const fileOutput = new EncodedFileOutput({
      fileType: EncodedFileType.MP4,
      filepath: absoluteTarget,
    });

    try {
      const info = await this.client.startRoomCompositeEgress(
        params.roomName,
        { file: fileOutput },
        {
          layout: 'speaker-dark',
        },
      );

      if (info && info.egressId) {
        return {
          egressId: info.egressId,
          mode: 'livekit-egress',
        };
      }
      throw new Error(`LiveKit Egress n'a pas retourné d'identifiant valide`);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`[LiveKitEgressAdapter] Failed to start RoomCompositeEgress: ${msg}`);
      throw new Error(`Impossible de démarrer l'enregistrement LiveKit Egress: ${msg}`);
    }
  }

  public async stopRoomRecording(params: {
    egressId: string;
    storageKey: string;
    startedAt: Date | null;
    sessionTitle?: string;
    subject?: string | null;
    mediaBase64?: string;
    mimeType?: string;
  }): Promise<StopEgressResult> {
    // 1. Send stop command to LiveKit Egress
    if (params.egressId && !params.egressId.startsWith('egress_local_')) {
      try {
        await this.client.stopEgress(params.egressId);
      } catch (err: unknown) {
        console.warn(`[LiveKitEgressAdapter] stopEgress notification: ${err instanceof Error ? err.message : err}`);
      }
    }

    const targetPath = this.storage.resolveSafePath(params.storageKey);
    let fileStat = await this.storage.stat(params.storageKey);

    // 2. Wait up to 12 seconds for the Egress container to flush and close the MP4 file
    let attempts = 0;
    while ((!fileStat || fileStat.sizeBytes < 10_000) && attempts < 12) {
      await new Promise((r) => setTimeout(r, 1000));
      fileStat = await this.storage.stat(params.storageKey);
      attempts++;
    }

    // 3. Fallback: If Egress did not produce a file but the client provided real captured media, transcode it
    if ((!fileStat || fileStat.sizeBytes < 10_000) && params.mediaBase64 && params.mediaBase64.length > 200) {
      await this.tryTranscodeUploadedMedia(
        params.storageKey,
        params.mediaBase64,
        params.sessionTitle ?? 'SmartClass Lecture',
        params.subject ?? 'Cours',
      );
      fileStat = await this.storage.stat(params.storageKey);
    }

    // 4. Strict verification: never pretend recording succeeded if no valid MP4 exists
    if (!fileStat || fileStat.sizeBytes < 10_000) {
      throw new Error(
        `L'enregistrement vidéo n'a pas pu être finalisé sur le serveur (${fileStat?.sizeBytes ?? 0} octets reçus). Vérifiez que le conteneur LiveKit Egress est actif et a les droits d'écriture sur le volume de stockage.`,
      );
    }

    // 5. Probe actual duration and validate stream integrity via FFprobe
    let durationSeconds = 0;
    try {
      const { stdout } = await execFileAsync(this.ffprobePath, [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        targetPath,
      ]);
      const parsed = parseFloat(stdout.trim());
      if (!isNaN(parsed) && parsed > 0) {
        durationSeconds = Math.round(parsed);
      }
    } catch {
      if (params.startedAt) {
        durationSeconds = Math.max(1, Math.round((Date.now() - params.startedAt.getTime()) / 1000));
      }
    }

    return {
      egressId: params.egressId,
      sizeBytes: fileStat.sizeBytes,
      durationSeconds: Math.max(durationSeconds, 1),
    };
  }

  private async tryTranscodeUploadedMedia(
    storageKey: string,
    mediaBase64: string,
    sessionTitle: string,
    subject: string,
  ): Promise<void> {
    const targetPath = this.storage.resolveSafePath(storageKey);
    const rawUploadPath = path.join(path.dirname(targetPath), `raw_capture_${Date.now()}.webm`);
    try {
      await fs.mkdir(path.dirname(targetPath), { recursive: true });
      const buffer = Buffer.from(mediaBase64, 'base64');
      await fs.writeFile(rawUploadPath, buffer);

      // Transcode real captured WebM/MP4 into standard H.264 + AAC MP4 with faststart
      await execFileAsync(
        this.ffmpegPath,
        [
          '-y',
          '-i',
          rawUploadPath,
          '-c:v',
          'libx264',
          '-preset',
          'ultrafast',
          '-pix_fmt',
          'yuv420p',
          '-vf',
          'scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2:color=0x0f172a',
          '-c:a',
          'aac',
          '-b:a',
          '96k',
          '-ar',
          '16000',
          '-ac',
          '1',
          '-movflags',
          '+faststart',
          targetPath,
        ],
        { timeout: 45_000 },
      );
    } catch (err: unknown) {
      console.error(
        `[LiveKitEgressAdapter] Error transcoding uploaded media: ${err instanceof Error ? err.message : err}`,
      );
    } finally {
      await fs.unlink(rawUploadPath).catch(() => {});
    }
  }
}
