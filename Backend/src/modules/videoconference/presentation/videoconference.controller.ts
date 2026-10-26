import type { Request, Response, NextFunction } from 'express';
import type { GetTimetableWeekUseCase } from '../application/get-timetable-week.use-case.js';
import type { CreateVideoSessionUseCase } from '../application/create-video-session.use-case.js';
import type { ListVideoSessionsUseCase } from '../application/list-video-sessions.use-case.js';
import type { GetVideoSessionUseCase } from '../application/get-video-session.use-case.js';
import type { UpdateVideoSessionUseCase } from '../application/update-video-session.use-case.js';
import type { CancelVideoSessionUseCase } from '../application/cancel-video-session.use-case.js';
import type { StartVideoSessionUseCase } from '../application/start-video-session.use-case.js';
import type { IssueJoinTokenUseCase } from '../application/issue-join-token.use-case.js';
import type { EndVideoSessionUseCase } from '../application/end-video-session.use-case.js';
import type { LeaveVideoSessionUseCase } from '../application/leave-video-session.use-case.js';
import type { MuteParticipantUseCase } from '../application/mute-participant.use-case.js';
import type { MuteAllUseCase } from '../application/mute-all.use-case.js';
import type { RemoveParticipantUseCase } from '../application/remove-participant.use-case.js';
import type { CreateSessionChatMessageUseCase } from '../application/create-session-chat-message.use-case.js';
import type { ListSessionChatMessagesUseCase } from '../application/list-session-chat-messages.use-case.js';
import type { ListSessionParticipantsUseCase } from '../application/list-session-participants.use-case.js';
import type { SetSessionChatEnabledUseCase } from '../application/set-session-chat-enabled.use-case.js';
import type { ReceiveLiveKitWebhookUseCase } from '../application/receive-livekit-webhook.use-case.js';
import type { GetMyNextSessionUseCase } from '../application/get-my-next-session.use-case.js';
import type { InMemoryLiveEventsHub } from '../infrastructure/in-memory-live-events.hub.js';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';
import type {
  TimetableQueryInput,
  CreateVideoSessionBodyInput,
  UpdateVideoSessionBodyInput,
  CancelVideoSessionBodyInput,
  ListVideoSessionsQueryInput,
  MuteParticipantBodyInput,
  RemoveParticipantBodyInput,
  CreateChatMessageBodyInput,
  ListChatMessagesQueryInput,
  ChatSettingsBodyInput,
  NextSessionQueryInput,
  SSEEventsQueryInput,
} from './videoconference.validation.js';

export class VideoconferenceController {
  constructor(
    private readonly getTimetableWeekUseCase: GetTimetableWeekUseCase,
    private readonly createVideoSessionUseCase?: CreateVideoSessionUseCase,
    private readonly listVideoSessionsUseCase?: ListVideoSessionsUseCase,
    private readonly getVideoSessionUseCase?: GetVideoSessionUseCase,
    private readonly updateVideoSessionUseCase?: UpdateVideoSessionUseCase,
    private readonly cancelVideoSessionUseCase?: CancelVideoSessionUseCase,
    private readonly startVideoSessionUseCase?: StartVideoSessionUseCase,
    private readonly issueJoinTokenUseCase?: IssueJoinTokenUseCase,
    private readonly endVideoSessionUseCase?: EndVideoSessionUseCase,
    private readonly leaveVideoSessionUseCase?: LeaveVideoSessionUseCase,
    private readonly muteParticipantUseCase?: MuteParticipantUseCase,
    private readonly muteAllUseCase?: MuteAllUseCase,
    private readonly removeParticipantUseCase?: RemoveParticipantUseCase,
    private readonly createSessionChatMessageUseCase?: CreateSessionChatMessageUseCase,
    private readonly listSessionChatMessagesUseCase?: ListSessionChatMessagesUseCase,
    private readonly listSessionParticipantsUseCase?: ListSessionParticipantsUseCase,
    private readonly setSessionChatEnabledUseCase?: SetSessionChatEnabledUseCase,
    private readonly receiveLiveKitWebhookUseCase?: ReceiveLiveKitWebhookUseCase,
    private readonly getMyNextSessionUseCase?: GetMyNextSessionUseCase,
    private readonly liveEventsHub?: InMemoryLiveEventsHub,
  ) {}

  public getTimetable = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const query = validatedQuery<TimetableQueryInput>(req);
      const result = await this.getTimetableWeekUseCase.execute(
        query.classGroupId,
        query.weekStart ? new Date(`${query.weekStart}T00:00:00.000Z`) : undefined,
        { id: req.user.id, role: req.user.role },
      );
      res.status(200).json({
        data: result.week,
      });
    } catch (err) {
      next(err);
    }
  };

  public createSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.createVideoSessionUseCase) {
        throw new Error('CreateVideoSessionUseCase not configured');
      }
      const body = req.body as CreateVideoSessionBodyInput;
      const result = await this.createVideoSessionUseCase.execute(
        { id: req.user.id, role: req.user.role },
        body,
      );
      res.status(201).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public listSessions = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.listVideoSessionsUseCase) {
        throw new Error('ListVideoSessionsUseCase not configured');
      }
      const query = validatedQuery<ListVideoSessionsQueryInput>(req);
      const result = await this.listVideoSessionsUseCase.execute(
        { id: req.user.id, role: req.user.role },
        query,
      );
      res.status(200).json({
        data: result.items,
        meta: result.meta,
      });
    } catch (err) {
      next(err);
    }
  };

  public getSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.getVideoSessionUseCase) {
        throw new Error('GetVideoSessionUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const result = await this.getVideoSessionUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public updateSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.updateVideoSessionUseCase) {
        throw new Error('UpdateVideoSessionUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const body = req.body as UpdateVideoSessionBodyInput;
      const result = await this.updateVideoSessionUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
        body,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public cancelSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.cancelVideoSessionUseCase) {
        throw new Error('CancelVideoSessionUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const body = (req.body ?? {}) as CancelVideoSessionBodyInput;
      const result = await this.cancelVideoSessionUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
        body,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public startSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.startVideoSessionUseCase) {
        throw new Error('StartVideoSessionUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const result = await this.startVideoSessionUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public issueJoinToken = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.issueJoinTokenUseCase) {
        throw new Error('IssueJoinTokenUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const result = await this.issueJoinTokenUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public endSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.endVideoSessionUseCase) {
        throw new Error('EndVideoSessionUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const result = await this.endVideoSessionUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public leaveSession = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.leaveVideoSessionUseCase) {
        throw new Error('LeaveVideoSessionUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const result = await this.leaveVideoSessionUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public listParticipants = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.listSessionParticipantsUseCase) {
        throw new Error('ListSessionParticipantsUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const result = await this.listSessionParticipantsUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public muteParticipant = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.muteParticipantUseCase) {
        throw new Error('MuteParticipantUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const targetUserId =
        (req.params as { userId?: string }).userId ??
        (req.body as MuteParticipantBodyInput).targetUserId;
      await this.muteParticipantUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
        targetUserId,
      );
      res.status(200).json({
        data: { success: true },
      });
    } catch (err) {
      next(err);
    }
  };

  public muteAll = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.muteAllUseCase) {
        throw new Error('MuteAllUseCase not configured');
      }
      const { id } = req.params as { id: string };
      await this.muteAllUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
      );
      res.status(200).json({
        data: { success: true },
      });
    } catch (err) {
      next(err);
    }
  };

  public removeParticipant = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.removeParticipantUseCase) {
        throw new Error('RemoveParticipantUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const targetUserId =
        (req.params as { userId?: string }).userId ??
        (req.body as RemoveParticipantBodyInput).targetUserId;
      const reason = (req.body as RemoveParticipantBodyInput)?.reason;
      await this.removeParticipantUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
        targetUserId,
        reason,
      );
      res.status(200).json({
        data: { success: true },
      });
    } catch (err) {
      next(err);
    }
  };

  public createChatMessage = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.createSessionChatMessageUseCase) {
        throw new Error('CreateSessionChatMessageUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const body = req.body as CreateChatMessageBodyInput;
      const result = await this.createSessionChatMessageUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
        body,
      );
      res.status(201).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public listChatMessages = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.listSessionChatMessagesUseCase) {
        throw new Error('ListSessionChatMessagesUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const query = validatedQuery<ListChatMessagesQueryInput>(req);
      const result = await this.listSessionChatMessagesUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
        query,
      );
      res.status(200).json({
        data: result.items,
        meta: result.meta,
      });
    } catch (err) {
      next(err);
    }
  };

  public setChatSettings = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.setSessionChatEnabledUseCase) {
        throw new Error('SetSessionChatEnabledUseCase not configured');
      }
      const { id } = req.params as { id: string };
      const body = req.body as ChatSettingsBodyInput;
      const result = await this.setSessionChatEnabledUseCase.execute(
        { id: req.user.id, role: req.user.role },
        id,
        body.enabled,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public receiveWebhook = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!this.receiveLiveKitWebhookUseCase) {
        throw new Error('ReceiveLiveKitWebhookUseCase not configured');
      }
      const authHeader = req.headers.authorization;
      const rawBody = (req as unknown as { rawBody?: Buffer }).rawBody ?? JSON.stringify(req.body);
      const result = await this.receiveLiveKitWebhookUseCase.execute(rawBody, authHeader);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  };

  public getMyNextSession = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Authentication required');
      }
      if (!this.getMyNextSessionUseCase) {
        throw new Error('GetMyNextSessionUseCase not configured');
      }
      const query = validatedQuery<NextSessionQueryInput>(req);
      const result = await this.getMyNextSessionUseCase.execute({
        userId: req.user.id,
        role: req.user.role,
        horizonHours: query?.horizonHours,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public streamEvents = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user || !req.user.role) {
        throw new UnauthorizedError('Authentication required');
      }
      if (!this.liveEventsHub) {
        throw new Error('InMemoryLiveEventsHub not configured');
      }
      const query = validatedQuery<SSEEventsQueryInput>(req);
      this.liveEventsHub.subscribe(req.user.id, res, req, query?.sessionId);
    } catch (err) {
      next(err);
    }
  };
}
