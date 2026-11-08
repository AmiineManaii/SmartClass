import { execFile } from 'node:child_process';
import nodeFs from 'node:fs';
import fs from 'node:fs/promises';
import path from 'node:path';
import { pipeline } from 'node:stream/promises';
import { promisify } from 'node:util';
import type { NextFunction, Request, Response } from 'express';
import { AppError, ForbiddenError, NotFoundError, UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';
import { parseHttpRangeHeader, type StoragePort } from '../../../shared/storage/storage.port.js';
import type { SmartModelRouterPort } from '../../ai-assistant/index.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { RecordingRepositoryPort } from '../domain/recording-repository.port.js';
import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import { canHost } from '../domain/video-session-policy.js';
import { sanitizeFfmpegText } from '../infrastructure/livekit-egress.adapter.js';

const execFileAsync = promisify(execFile);
import type {
  DeleteRecordingUseCase,
  GetRecordingUseCase,
  ListRecordingsUseCase,
  ResolveRecordingMediaStreamUseCase,
  RetryRecordingProcessingUseCase,
  StartRecordingUseCase,
  StopRecordingUseCase,
  UploadRecordingSourceDocumentUseCase,
} from '../application/recording-workflow.use-cases.js';
import type {
  AskLessonAiTutorUseCase,
  GenerateStudentStudyArtifactUseCase,
  GetPublishedLessonWorkspaceUseCase,
  ManageStudentBookmarksUseCase,
  ManageStudentNotesUseCase,
  SearchLessonContentUseCase,
  SubmitStudentQuizAttemptUseCase,
  UpdateStudentProgressUseCase,
} from '../application/student-learning.use-cases.js';
import type {
  ApproveLessonPackageUseCase,
  GetLessonReviewPackageUseCase,
  PublishLessonPackageUseCase,
  RegenerateLessonSectionUseCase,
  UnpublishLessonPackageUseCase,
  UpdateLessonReviewPackageUseCase,
} from '../application/teacher-review.use-cases.js';
import type {
  AskLessonTutorBodyInput,
  CreateBookmarkBodyInput,
  CreateStudentNoteBodyInput,
  GenerateStudyArtifactBodyInput,
  ListRecordingsQueryInput,
  RegenerateSectionBodyInput,
  SearchLessonQueryInput,
  SubmitQuizAttemptBodyInput,
  UpdateLessonReviewBodyInput,
  UpdateStudentProgressBodyInput,
  UploadSourceDocBodyInput,
} from './recording.validation.js';

export interface RecordingControllerDeps {
  storage: StoragePort;
  modelRouter: SmartModelRouterPort;
  startRecordingUseCase: StartRecordingUseCase;
  stopRecordingUseCase: StopRecordingUseCase;
  getRecordingUseCase: GetRecordingUseCase;
  listRecordingsUseCase: ListRecordingsUseCase;
  uploadSourceDocUseCase: UploadRecordingSourceDocumentUseCase;
  retryProcessingUseCase: RetryRecordingProcessingUseCase;
  deleteRecordingUseCase: DeleteRecordingUseCase;
  resolveMediaStreamUseCase: ResolveRecordingMediaStreamUseCase;
  getReviewPackageUseCase: GetLessonReviewPackageUseCase;
  updateReviewPackageUseCase: UpdateLessonReviewPackageUseCase;
  regenerateSectionUseCase: RegenerateLessonSectionUseCase;
  approveLessonUseCase: ApproveLessonPackageUseCase;
  publishLessonUseCase: PublishLessonPackageUseCase;
  unpublishLessonUseCase: UnpublishLessonPackageUseCase;
  getStudentWorkspaceUseCase: GetPublishedLessonWorkspaceUseCase;
  searchLessonUseCase: SearchLessonContentUseCase;
  updateStudentProgressUseCase: UpdateStudentProgressUseCase;
  manageBookmarksUseCase: ManageStudentBookmarksUseCase;
  manageNotesUseCase: ManageStudentNotesUseCase;
  generateStudyArtifactUseCase: GenerateStudentStudyArtifactUseCase;
  submitQuizAttemptUseCase: SubmitStudentQuizAttemptUseCase;
  askLessonTutorUseCase: AskLessonAiTutorUseCase;
  sessionRepository?: VideoSessionRepositoryPort;
  recordingRepository?: RecordingRepositoryPort;
  classAccessPort?: ClassAccessPort;
}

export class RecordingController {
  constructor(private readonly deps: RecordingControllerDeps) {}

  private requireUser(req: Request): { id: string; role: 'STUDENT' | 'TEACHER' | 'ADMIN' } {
    if (!req.user || !req.user.role) {
      throw new UnauthorizedError('Authentication required', ErrorCodes.AUTH_TOKEN_INVALID);
    }
    return { id: req.user.id, role: req.user.role };
  }

  public startRecording = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.startRecordingUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public stopRecording = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = (req.body ?? {}) as {
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
      const result = await this.deps.stopRecordingUseCase.execute(user, id, {
        capturePayload: body,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public uploadRecordingMedia = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };

      if (this.deps.sessionRepository && this.deps.classAccessPort) {
        const session = await this.deps.sessionRepository.findById(id);
        if (!session) {
          throw new NotFoundError('Séance vidéo introuvable');
        }
        const access = await this.deps.classAccessPort.getClassAccess(user.id, session.classGroupId);
        const isHostOrAuthorized = session.hostId === user.id || canHost(user, access);
        if (!isHostOrAuthorized) {
          throw new ForbiddenError('Seul l’enseignant hôte ou un administrateur peut téléverser l’enregistrement');
        }
      }

      const storageKey = `recordings/${id}/lecture.mp4`;
      const targetPath = this.deps.storage.resolveSafePath(storageKey);
      await fs.mkdir(path.dirname(targetPath), { recursive: true });
      const rawUploadPath = path.join(path.dirname(targetPath), `raw_capture_${Date.now()}.webm`);

      if (Buffer.isBuffer(req.body) && req.body.length > 0) {
        await fs.writeFile(rawUploadPath, req.body);
      } else {
        const fileStream = nodeFs.createWriteStream(rawUploadPath);
        await pipeline(req, fileStream);
      }

      const st = await fs.stat(rawUploadPath).catch(() => null);
      if (!st || st.size < 500) {
        throw new AppError('Le fichier média téléversé est vide ou corrompu', 400, ErrorCodes.BAD_REQUEST);
      }

      const ffmpegPath = process.env.FFMPEG_PATH || 'ffmpeg';

      // 1. First attempt: standard transcode screen/video + audio into universal MP4 (libx264 + aac)
      try {
        await execFileAsync(
          ffmpegPath,
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
            '128k',
            '-ar',
            '16000',
            '-ac',
            '1',
            '-movflags',
            '+faststart',
            targetPath,
          ],
          { timeout: 90_000 },
        );
      } catch {
        // 2. Second attempt: if stream was audio-only without a video track, create a lecture canvas with audio
        try {
          const fontFile = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf';
          const session = this.deps.sessionRepository ? await this.deps.sessionRepository.findById(id) : null;
          const safeTitle = sanitizeFfmpegText(session?.title ?? 'SmartClass Lecture');
          const safeSub = sanitizeFfmpegText(session?.subject ?? 'Cours');
          await execFileAsync(
            ffmpegPath,
            [
              '-y',
              '-f',
              'lavfi',
              '-i',
              'color=c=0x0f172a:s=1280x720:r=15:d=30',
              '-i',
              rawUploadPath,
              '-shortest',
              '-vf',
              `drawbox=x=60:y=60:w=1160:h=600:color=0x1e293b@0.95:t=fill,drawtext=fontfile=${fontFile}:text='SMARTCLASS LIVE REPLAY':fontcolor=0x38bdf8:fontsize=24:x=110:y=110,drawtext=fontfile=${fontFile}:text='${safeTitle}':fontcolor=white:fontsize=42:x=110:y=180,drawtext=fontfile=${fontFile}:text='Module - ${safeSub}':fontcolor=0x94a3b8:fontsize=28:x=110:y=250`,
              '-c:v',
              'libx264',
              '-preset',
              'ultrafast',
              '-pix_fmt',
              'yuv420p',
              '-c:a',
              'aac',
              '-b:a',
              '128k',
              '-ar',
              '16000',
              '-ac',
              '1',
              '-movflags',
              '+faststart',
              targetPath,
            ],
            { timeout: 90_000 },
          );
        } catch {
          // Fallback: copy file
          await fs.copyFile(rawUploadPath, targetPath);
        }
      }

      await fs.unlink(rawUploadPath).catch(() => {});
      const targetStat = await fs.stat(targetPath);

      if (this.deps.recordingRepository) {
        const rec = await this.deps.recordingRepository.findBySessionId(id);
        if (rec) {
          await this.deps.recordingRepository.updateRecording(rec.id, {
            storageKey,
            sizeBytes: targetStat.size,
            durationSeconds: Math.max(rec.durationSeconds ?? 30, 20),
          });
        }
      }

      res.status(200).json({
        data: {
          success: true,
          sizeBytes: targetStat.size,
          storageKey,
        },
      });
    } catch (err) {
      next(err);
    }
  };

  public getRecording = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.getRecordingUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public listRecordings = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const query = validatedQuery<ListRecordingsQueryInput>(req);
      const result = await this.deps.listRecordingsUseCase.execute(user, query);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public uploadSourceDocument = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as UploadSourceDocBodyInput;
      const result = await this.deps.uploadSourceDocUseCase.execute(user, id, body);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public retryProcessing = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.retryProcessingUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public deleteRecording = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.deleteRecordingUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public streamVideo = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const resolved = await this.deps.resolveMediaStreamUseCase.execute(user, id, 'video');
      const stat = await this.deps.storage.stat(resolved.storageKey);

      if (!stat || stat.sizeBytes === 0) {
        throw new AppError(
          'Fichier vidéo introuvable dans le stockage local',
          404,
          ErrorCodes.RECORDING_NOT_FOUND,
        );
      }

      const rangeHeader = req.headers.range;
      if (rangeHeader) {
        const range = parseHttpRangeHeader(rangeHeader, stat.sizeBytes);
        if (!range) {
          res.setHeader('Content-Range', `bytes */${stat.sizeBytes}`);
          res.status(416).end();
          return;
        }
        const chunkLength = range.end - range.start + 1;
        res.status(206);
        res.setHeader('Content-Range', `bytes ${range.start}-${range.end}/${stat.sizeBytes}`);
        res.setHeader('Accept-Ranges', 'bytes');
        res.setHeader('Content-Length', String(chunkLength));
        res.setHeader('Content-Type', resolved.mimeType);
        res.setHeader('Cache-Control', 'private, max-age=3600');
        const stream = await this.deps.storage.createReadStream(resolved.storageKey, range);
        stream.on('error', (err: unknown) => next(err));
        stream.pipe(res);
        return;
      }

      res.status(200);
      res.setHeader('Accept-Ranges', 'bytes');
      res.setHeader('Content-Length', String(stat.sizeBytes));
      res.setHeader('Content-Type', resolved.mimeType);
      res.setHeader('Cache-Control', 'private, max-age=3600');
      const stream = await this.deps.storage.createReadStream(resolved.storageKey);
      stream.on('error', (err: unknown) => next(err));
      stream.pipe(res);
    } catch (err) {
      next(err);
    }
  };

  public streamPoster = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const resolved = await this.deps.resolveMediaStreamUseCase.execute(user, id, 'poster');
      const stat = await this.deps.storage.stat(resolved.storageKey);
      if (!stat) {
        // Return a clean 1x1 SVG placeholder if poster was not extracted yet
        res.setHeader('Content-Type', 'image/svg+xml');
        res
          .status(200)
          .send(
            '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360" viewBox="0 0 640 360"><rect width="640" height="360" fill="#1e293b"/><text x="320" y="185" fill="#f8fafc" font-family="sans-serif" font-size="22" text-anchor="middle">SmartClass Replay</text></svg>',
          );
        return;
      }
      res.setHeader('Content-Type', resolved.mimeType);
      res.setHeader('Content-Length', String(stat.sizeBytes));
      const stream = await this.deps.storage.createReadStream(resolved.storageKey);
      stream.on('error', (err: unknown) => next(err));
      stream.pipe(res);
    } catch (err) {
      next(err);
    }
  };

  public streamSlideFrame = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id, frameIndex } = req.params as { id: string; frameIndex: string };
      const idx = Math.max(0, Number.parseInt(frameIndex ?? '0', 10) || 0);
      const resolved = await this.deps.resolveMediaStreamUseCase.execute(
        user,
        id,
        'frame',
        idx,
      );
      const stat = await this.deps.storage.stat(resolved.storageKey);
      if (!stat || stat.sizeBytes < 100) {
        res.setHeader('Content-Type', 'image/svg+xml');
        res
          .status(200)
          .send(
            `<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="720" viewBox="0 0 1280 720"><rect width="1280" height="720" fill="#0f172a"/><rect x="60" y="60" width="1160" height="600" rx="20" fill="#1e293b"/><text x="640" y="340" fill="#38bdf8" font-family="sans-serif" font-size="36" font-weight="bold" text-anchor="middle">SmartClass — Diapositive #${idx + 1}</text><text x="640" y="400" fill="#94a3b8" font-family="sans-serif" font-size="24" text-anchor="middle">Analyse Visuelle IA</text></svg>`,
          );
        return;
      }
      res.setHeader('Content-Type', resolved.mimeType);
      res.setHeader('Content-Length', String(stat.sizeBytes));
      res.setHeader('Cache-Control', 'private, max-age=3600');
      const stream = await this.deps.storage.createReadStream(resolved.storageKey);
      stream.on('error', (err: unknown) => next(err));
      stream.pipe(res);
    } catch (err) {
      next(err);
    }
  };

  public streamSubtitles = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const format = req.query.format === 'srt' ? 'subtitles-srt' : 'subtitles-vtt';
      const resolved = await this.deps.resolveMediaStreamUseCase.execute(user, id, format);
      res.setHeader('Content-Type', resolved.mimeType);
      res.status(200).send(resolved.inlineContent ?? '');
    } catch (err) {
      next(err);
    }
  };

  // ───────────────────────────────────────────────────────────────────────────
  // TEACHER REVIEW & PUBLISHING STUDIO
  // ───────────────────────────────────────────────────────────────────────────

  public getTeacherReviewPackage = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.getReviewPackageUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public updateTeacherReviewPackage = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as UpdateLessonReviewBodyInput;
      const result = await this.deps.updateReviewPackageUseCase.execute(user, id, body);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public regenerateSection = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as RegenerateSectionBodyInput;
      const result = await this.deps.regenerateSectionUseCase.execute(user, id, body);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public approveLessonPackage = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.approveLessonUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public publishLessonPackage = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.publishLessonUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public unpublishLessonPackage = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.unpublishLessonUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  // ───────────────────────────────────────────────────────────────────────────
  // STUDENT LECTURE LEARNING WORKSPACE & AI TUTOR
  // ───────────────────────────────────────────────────────────────────────────

  public getStudentWorkspace = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const result = await this.deps.getStudentWorkspaceUseCase.execute(user, id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public searchLessonContent = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const query = validatedQuery<SearchLessonQueryInput>(req);
      const result = await this.deps.searchLessonUseCase.execute(user, id, query.q);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public updateStudentProgress = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as UpdateStudentProgressBodyInput;
      const result = await this.deps.updateStudentProgressUseCase.execute(user, id, body);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public createBookmark = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as CreateBookmarkBodyInput;
      const result = await this.deps.manageBookmarksUseCase.create(user, id, body);
      res.status(201).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public deleteBookmark = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id, bookmarkId } = req.params as { id: string; bookmarkId: string };
      const result = await this.deps.manageBookmarksUseCase.delete(user, id, bookmarkId);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public createStudentNote = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as CreateStudentNoteBodyInput;
      const result = await this.deps.manageNotesUseCase.create(user, id, body);
      res.status(201).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public updateStudentNote = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id, noteId } = req.params as { id: string; noteId: string };
      const result = await this.deps.manageNotesUseCase.update(user, id, noteId, req.body);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public deleteStudentNote = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id, noteId } = req.params as { id: string; noteId: string };
      const result = await this.deps.manageNotesUseCase.delete(user, id, noteId);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public generateStudyArtifact = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as GenerateStudyArtifactBodyInput;
      const result = await this.deps.generateStudyArtifactUseCase.execute(user, id, body);
      res.status(201).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public submitQuizAttempt = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as SubmitQuizAttemptBodyInput;
      const result = await this.deps.submitQuizAttemptUseCase.execute(user, id, body);
      res.status(201).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public askLessonAiTutor = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = this.requireUser(req);
      const { id } = req.params as { id: string };
      const body = req.body as AskLessonTutorBodyInput;
      const result = await this.deps.askLessonTutorUseCase.execute(user, id, body);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public getModelInventory = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      this.requireUser(req);
      const report = await this.deps.modelRouter.inspectModels();
      res.status(200).json({ data: report });
    } catch (err) {
      next(err);
    }
  };
}
