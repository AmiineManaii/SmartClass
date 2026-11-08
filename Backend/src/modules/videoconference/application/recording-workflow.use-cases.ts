import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import {
  AppError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import type { StoragePort } from '../../../shared/storage/storage.port.js';
import type { PdfTextExtractorPort } from '../../ai-assistant/index.js';
import { UnpdfTextExtractor } from '../../ai-assistant/index.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { EgressServicePort } from '../domain/egress-service.port.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import type {
  RecordingEntity,
  RecordingProcessingJobEntity,
  RecordingStatus,
} from '../domain/recording.entity.js';
import { canStartRecording, canStopRecording } from '../domain/recording.entity.js';
import type { RecordingRepositoryPort } from '../domain/recording-repository.port.js';
import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import { canHost, type UserContext } from '../domain/video-session-policy.js';
import type { MediaProcessingWorker } from '../infrastructure/media-processing.worker.js';

export interface RecordingOverviewDto {
  id: string;
  sessionId: string;
  classGroupId: string;
  hostId: string | null;
  status: RecordingStatus;
  mimeType: string;
  sizeBytes: number | null;
  durationSeconds: number | null;
  width: number | null;
  height: number | null;
  hasSourceDocument: boolean;
  sourceDocTitle: string | null;
  errorCode: string | null;
  errorMessage: string | null;
  startedAt: string | null;
  stoppedAt: string | null;
  publishedAt: string | null;
  processingVersion: number;
  aiModelUsed: string | null;
  streamUrl: string;
  posterUrl: string;
  subtitlesVttUrl: string;
  subtitlesSrtUrl: string;
  latestJob: {
    id: string;
    status: string;
    stage: string;
    progress: number;
    errorMessage: string | null;
    stageLogs: unknown[];
    startedAt: string | null;
    completedAt: string | null;
  } | null;
  createdAt: string;
  updatedAt: string;
}

export const toRecordingOverviewDto = (
  rec: RecordingEntity,
  job?: RecordingProcessingJobEntity | null,
): RecordingOverviewDto => ({
  id: rec.id,
  sessionId: rec.sessionId,
  classGroupId: rec.classGroupId,
  hostId: rec.hostId,
  status: rec.status,
  mimeType: rec.mimeType,
  sizeBytes: rec.sizeBytes,
  durationSeconds: rec.durationSeconds,
  width: rec.width,
  height: rec.height,
  hasSourceDocument: Boolean(rec.sourceDocKey || rec.sourceDocText),
  sourceDocTitle: rec.sourceDocTitle,
  errorCode: rec.errorCode,
  errorMessage: rec.errorMessage,
  startedAt: rec.startedAt ? rec.startedAt.toISOString() : null,
  stoppedAt: rec.stoppedAt ? rec.stoppedAt.toISOString() : null,
  publishedAt: rec.publishedAt ? rec.publishedAt.toISOString() : null,
  processingVersion: rec.processingVersion,
  aiModelUsed: rec.aiModelUsed,
  streamUrl: `/api/v1/videoconference/sessions/${rec.sessionId}/recording/stream`,
  posterUrl: `/api/v1/videoconference/sessions/${rec.sessionId}/recording/poster`,
  subtitlesVttUrl: `/api/v1/videoconference/sessions/${rec.sessionId}/recording/subtitles?format=vtt`,
  subtitlesSrtUrl: `/api/v1/videoconference/sessions/${rec.sessionId}/recording/subtitles?format=srt`,
  latestJob: job
    ? {
        id: job.id,
        status: job.status,
        stage: job.stage,
        progress: job.progress,
        errorMessage: job.errorMessage,
        stageLogs: job.stageLogs,
        startedAt: job.startedAt ? job.startedAt.toISOString() : null,
        completedAt: job.completedAt ? job.completedAt.toISOString() : null,
      }
    : null,
  createdAt: rec.createdAt.toISOString(),
  updatedAt: rec.updatedAt.toISOString(),
});

export class StartRecordingUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly egressService: EgressServicePort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<RecordingOverviewDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    const isHostOrAuthorized = session.hostId === user.id || canHost(user, access);
    if (!isHostOrAuthorized) {
      throw new ForbiddenError('Seul l’enseignant hôte ou un administrateur peut démarrer l’enregistrement');
    }

    if (session.status !== 'IN_PROGRESS') {
      throw new ConflictError(
        `L'enregistrement ne peut démarrer que pendant une séance en direct (statut actuel: ${session.status})`,
      );
    }

    const existing = await this.recordingRepository.findBySessionId(sessionId);
    if (existing && (existing.status === 'RECORDING' || existing.status === 'STARTING')) {
      const latestJob = await this.recordingRepository.findLatestJobByRecordingId(existing.id);
      return toRecordingOverviewDto(existing, latestJob);
    }

    if (existing && !canStartRecording(existing.status)) {
      throw new AppError(
        `Un enregistrement existe déjà pour cette séance (statut: ${existing.status})`,
        409,
        ErrorCodes.RECORDING_ALREADY_ACTIVE,
      );
    }

    const storageKey = `recordings/${session.id}/lecture.mp4`;
    const egressResult = await this.egressService.startRoomRecording({
      roomName: session.roomName,
      sessionId: session.id,
      storageKey,
    });

    const now = new Date();
    const recording = await this.recordingRepository.upsertBySessionId({
      sessionId: session.id,
      classGroupId: session.classGroupId,
      hostId: user.id,
      status: 'RECORDING',
      egressId: egressResult.egressId,
      storageKey,
      mimeType: 'video/mp4',
      startedAt: now,
      stoppedAt: null,
      errorCode: null,
      errorMessage: null,
    });

    await this.auditService?.record({
      userId: user.id,
      action: 'recording.started',
      targetType: 'Recording',
      targetId: recording.id,
      details: {
        sessionId: session.id,
        classGroupId: session.classGroupId,
        egressMode: egressResult.mode,
      },
    });

    await this.eventsPublisher?.publishToClass(session.classGroupId, {
      type: 'recording.started',
      sessionId: session.id,
      classGroupId: session.classGroupId,
      status: session.status,
      at: now.toISOString(),
      data: {
        recordingId: recording.id,
        status: recording.status,
        startedAt: now.toISOString(),
      },
    });

    return toRecordingOverviewDto(recording, null);
  }
}

export class StopRecordingUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly egressService: EgressServicePort,
    private readonly mediaWorker: MediaProcessingWorker,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    options?: {
      awaitProcessing?: boolean;
      capturePayload?: {
        spokenTranscript?: string;
        detectedLanguage?: string;
        capturedSegments?: Array<{
          startSeconds: number;
          endSeconds: number;
          text: string;
          speaker?: string;
          language?: string;
        }>;
        mediaBase64?: string;
        mimeType?: string;
      };
    },
  ): Promise<RecordingOverviewDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    const isHostOrAuthorized = session.hostId === user.id || canHost(user, access);
    if (!isHostOrAuthorized) {
      throw new ForbiddenError('Seul l’enseignant hôte ou un administrateur peut arrêter l’enregistrement');
    }

    const existing = await this.recordingRepository.findBySessionId(sessionId);
    if (!existing) {
      throw new AppError(
        'Aucun enregistrement actif pour cette séance',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    if (options?.capturePayload) {
      await this.mediaWorker.saveLiveCaptureHints(session.id, options.capturePayload);
    }

    // Idempotent if already stopped/processing/ready
    if (!canStopRecording(existing.status)) {
      const latestJob = await this.recordingRepository.findLatestJobByRecordingId(existing.id);
      return toRecordingOverviewDto(existing, latestJob);
    }

    const storageKey = existing.storageKey ?? `recordings/${session.id}/lecture.mp4`;
    let stopResult;
    try {
      stopResult = await this.egressService.stopRoomRecording({
        egressId: existing.egressId ?? `egress_local_${session.id}`,
        storageKey,
        startedAt: existing.startedAt,
        sessionTitle: session.title,
        subject: session.subject,
        mediaBase64: options?.capturePayload?.mediaBase64,
        mimeType: options?.capturePayload?.mimeType,
      });
    } catch (err: unknown) {
      const errorMsg = err instanceof Error ? err.message : String(err);
      console.error(
        `[StopRecordingUseCase] Failed to stop recording for session ${session.id} (recording ${existing.id}): ${errorMsg}`,
      );
      await this.recordingRepository.updateRecording(existing.id, {
        status: 'FAILED',
        errorCode: 'RECORDING_STOP_FAILED',
        errorMessage: errorMsg,
        stoppedAt: new Date(),
      });
      await this.eventsPublisher?.publishToClass(session.classGroupId, {
        type: 'recording.stopped',
        sessionId: session.id,
        classGroupId: session.classGroupId,
        status: session.status,
        at: new Date().toISOString(),
        data: {
          recordingId: existing.id,
          status: 'FAILED',
          errorMessage: errorMsg,
        },
      });
      throw err;
    }

    const stoppedAt = new Date();
    const recorded = await this.recordingRepository.updateRecording(existing.id, {
      status: 'RECORDED',
      storageKey,
      sizeBytes: stopResult.sizeBytes,
      durationSeconds: stopResult.durationSeconds,
      stoppedAt,
    });

    await this.auditService?.record({
      userId: user.id,
      action: 'recording.stopped',
      targetType: 'Recording',
      targetId: recorded.id,
      details: {
        sessionId: session.id,
        durationSeconds: stopResult.durationSeconds,
        sizeBytes: stopResult.sizeBytes,
      },
    });

    await this.eventsPublisher?.publishToClass(session.classGroupId, {
      type: 'recording.stopped',
      sessionId: session.id,
      classGroupId: session.classGroupId,
      status: session.status,
      at: stoppedAt.toISOString(),
      data: {
        recordingId: recorded.id,
        status: options?.awaitProcessing ? 'PROCESSING' : 'RECORDED',
        durationSeconds: stopResult.durationSeconds,
      },
    });

    // Automatically launch asynchronous 7-stage media & AI processing pipeline
    const job = await this.mediaWorker.enqueueProcessing(recorded.id, {
      awaitCompletion: options?.awaitProcessing,
    });
    const refreshed = (await this.recordingRepository.findById(recorded.id)) ?? recorded;

    return toRecordingOverviewDto(refreshed, job);
  }
}

export class GetRecordingUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<RecordingOverviewDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    const isTeacherOrAdmin = session.hostId === user.id || canHost(user, access);
    if (!isTeacherOrAdmin && !access.isMember) {
      throw new ForbiddenError('Accès refusé à cette séance enregistrée');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording || recording.status === 'DELETED') {
      throw new AppError(
        'Aucun enregistrement disponible pour cette séance',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    const latestJob = await this.recordingRepository.findLatestJobByRecordingId(recording.id);
    return toRecordingOverviewDto(recording, latestJob);
  }
}

export class ListRecordingsUseCase {
  constructor(
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(
    user: UserContext,
    filter?: { classGroupId?: string; status?: RecordingStatus },
  ): Promise<RecordingOverviewDto[]> {
    let classGroupIds: string[] | undefined;

    if (filter?.classGroupId) {
      const access = await this.classAccessPort.getClassAccess(user.id, filter.classGroupId);
      if (user.role !== 'ADMIN' && !access.isMember && !canHost(user, access)) {
        throw new ForbiddenError('Accès refusé aux enregistrements de cette classe');
      }
      classGroupIds = [filter.classGroupId];
    } else if (user.role !== 'ADMIN') {
      classGroupIds = await this.classAccessPort.getUserClassGroupIds(user.id);
      if (classGroupIds.length === 0) return [];
    }

    const list = await this.recordingRepository.listByClassGroups({
      classGroupIds,
      status: filter?.status,
      publishedOnly: user.role === 'STUDENT',
    });

    const dtos: RecordingOverviewDto[] = [];
    for (const rec of list) {
      const job = await this.recordingRepository.findLatestJobByRecordingId(rec.id);
      dtos.push(toRecordingOverviewDto(rec, job));
    }
    return dtos;
  }
}

export class UploadRecordingSourceDocumentUseCase {
  private readonly pdfExtractor: PdfTextExtractorPort;

  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly storage: StoragePort,
    pdfExtractor?: PdfTextExtractorPort,
  ) {
    this.pdfExtractor = pdfExtractor ?? new UnpdfTextExtractor();
  }

  public async execute(
    user: UserContext,
    sessionId: string,
    input: { title: string; mimeType?: string; contentText?: string; fileBase64?: string },
  ): Promise<RecordingOverviewDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant peut associer un support de cours à la séance');
    }

    const docKey = `recordings/${session.id}/documents/source_${Date.now()}.pdf`;
    let extractedText = input.contentText?.trim() ?? '';

    if (input.fileBase64) {
      const buffer = Buffer.from(input.fileBase64, 'base64');
      await this.storage.putBuffer(docKey, buffer);
      if (!extractedText) {
        try {
          const parsed = await this.pdfExtractor.extract(buffer);
          extractedText = parsed.text;
        } catch {
          extractedText = buffer.toString('utf8').slice(0, 15_000);
        }
      }
    } else if (extractedText) {
      await this.storage.putBuffer(docKey, Buffer.from(extractedText, 'utf8'));
    }

    const existing = await this.recordingRepository.findBySessionId(session.id);
    const recording = await this.recordingRepository.upsertBySessionId({
      sessionId: session.id,
      classGroupId: session.classGroupId,
      hostId: existing?.hostId ?? user.id,
      status: existing?.status ?? 'NOT_STARTED',
      sourceDocKey: docKey,
      sourceDocTitle: input.title,
      sourceDocText: extractedText,
    });

    const latestJob = await this.recordingRepository.findLatestJobByRecordingId(recording.id);
    return toRecordingOverviewDto(recording, latestJob);
  }
}

export class RetryRecordingProcessingUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly mediaWorker: MediaProcessingWorker,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    options?: { awaitProcessing?: boolean },
  ): Promise<RecordingOverviewDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant ou un administrateur peut relancer le traitement IA');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording) {
      throw new AppError(
        'Aucun enregistrement trouvé pour cette séance',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    await this.recordingRepository.updateRecording(recording.id, {
      processingVersion: recording.processingVersion + 1,
    });

    const job = await this.mediaWorker.enqueueProcessing(recording.id, {
      awaitCompletion: options?.awaitProcessing,
    });
    const refreshed = (await this.recordingRepository.findById(recording.id)) ?? recording;
    return toRecordingOverviewDto(refreshed, job);
  }
}

export class DeleteRecordingUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly storage: StoragePort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<{ deleted: boolean }> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    if (session.hostId !== user.id && !canHost(user, access)) {
      throw new ForbiddenError('Seul l’enseignant hôte ou un administrateur peut supprimer cet enregistrement');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording) {
      throw new AppError(
        'Aucun enregistrement trouvé pour cette séance',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    if (recording.storageKey) {
      await this.storage.delete(recording.storageKey);
    }

    await this.recordingRepository.updateRecording(recording.id, {
      status: 'DELETED',
    });

    await this.auditService?.record({
      userId: user.id,
      action: 'recording.deleted',
      targetType: 'Recording',
      targetId: recording.id,
      details: { sessionId },
    });

    return { deleted: true };
  }
}

export class ResolveRecordingMediaStreamUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly recordingRepository: RecordingRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    asset: 'video' | 'poster' | 'subtitles-vtt' | 'subtitles-srt' | 'frame',
    frameIndex = 0,
  ): Promise<{
    recording: RecordingEntity;
    storageKey: string;
    mimeType: string;
    inlineContent?: string;
  }> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Séance vidéo introuvable');
    }

    const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
    const isTeacherOrAdmin = session.hostId === user.id || canHost(user, access);
    if (!isTeacherOrAdmin && !access.isMember) {
      throw new ForbiddenError('Accès non autorisé à ce média de cours');
    }

    const recording = await this.recordingRepository.findBySessionId(sessionId);
    if (!recording || recording.status === 'DELETED') {
      throw new AppError(
        'Enregistrement introuvable pour cette séance',
        404,
        ErrorCodes.RECORDING_NOT_FOUND,
      );
    }

    if (!isTeacherOrAdmin && recording.status !== 'PUBLISHED') {
      throw new AppError(
        'Ce cours enregistré n’a pas encore été publié par votre enseignant',
        403,
        ErrorCodes.RECORDING_NOT_PUBLISHED,
      );
    }

    if (asset === 'subtitles-vtt' || asset === 'subtitles-srt') {
      const transcript = await this.recordingRepository.getTranscript(recording.id);
      const isVtt = asset === 'subtitles-vtt';
      return {
        recording,
        storageKey: `recordings/${session.id}/subtitles/captions.${isVtt ? 'vtt' : 'srt'}`,
        mimeType: isVtt ? 'text/vtt; charset=utf-8' : 'application/x-subrip; charset=utf-8',
        inlineContent: isVtt
          ? (transcript?.vttContent ?? 'WEBVTT\n\n')
          : (transcript?.srtContent ?? ''),
      };
    }

    if (asset === 'frame') {
      const frames = await this.recordingRepository.listSlideFrames(recording.id);
      const safeIdx = Math.max(0, Math.min(frameIndex, Math.max(0, frames.length - 1)));
      const matched = frames[safeIdx];
      return {
        recording,
        storageKey:
          matched?.storageKey ??
          `recordings/${session.id}/frames/slide_${safeIdx + 1}_0s.jpg`,
        mimeType: 'image/jpeg',
      };
    }

    if (asset === 'poster') {
      return {
        recording,
        storageKey: recording.thumbnailKey ?? `recordings/${session.id}/poster.jpg`,
        mimeType: 'image/jpeg',
      };
    }

    return {
      recording,
      storageKey: recording.storageKey ?? `recordings/${session.id}/lecture.mp4`,
      mimeType: recording.mimeType || 'video/mp4',
    };
  }
}
