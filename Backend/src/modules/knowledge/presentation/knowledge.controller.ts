import type { NextFunction, Request, Response } from 'express';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';
import type { Role } from '../../auth/index.js';
import type {
  DeleteKnowledgeDocumentUseCase,
  GetKnowledgeDocumentUseCase,
  GetKnowledgeStatusUseCase,
  ListKnowledgeDocumentsUseCase,
  ReindexKnowledgeUseCase,
} from '../application/knowledge-management.use-cases.js';
import type { SearchKnowledgeUseCase } from '../application/search-knowledge.use-case.js';
import type {
  KnowledgeIndexStatus,
  KnowledgeSearchFilters,
  KnowledgeSearchMode,
  KnowledgeSourceType,
} from '../domain/knowledge-document.entity.js';
import {
  toKnowledgeDocumentDto,
  toKnowledgeSearchResponseDto,
  toKnowledgeStatusDto,
} from './knowledge.mapper.js';

const requireUser = (req: Request): { id: string; role: Role } => {
  if (!req.user || !req.user.role) {
    throw new UnauthorizedError('Authentication required');
  }
  return { id: req.user.id, role: req.user.role };
};

export class KnowledgeController {
  constructor(
    private readonly searchUseCase: SearchKnowledgeUseCase,
    private readonly listDocumentsUseCase: ListKnowledgeDocumentsUseCase,
    private readonly getDocumentUseCase: GetKnowledgeDocumentUseCase,
    private readonly deleteDocumentUseCase: DeleteKnowledgeDocumentUseCase,
    private readonly reindexUseCase: ReindexKnowledgeUseCase,
    private readonly statusUseCase: GetKnowledgeStatusUseCase,
  ) {}

  public search = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = requireUser(req);
      const body = req.body as {
        query: string;
        k?: number;
        preferredMode?: KnowledgeSearchMode;
        filters?: KnowledgeSearchFilters;
      };
      const result = await this.searchUseCase.search({
        actor,
        query: body.query,
        k: body.k,
        preferredMode: body.preferredMode,
        filters: body.filters,
      });
      res.status(200).json({ data: toKnowledgeSearchResponseDto(result) });
    } catch (err) {
      next(err);
    }
  };

  public listDocuments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = requireUser(req);
      const query = validatedQuery<{
        page: number;
        limit: number;
        sourceType?: KnowledgeSourceType;
        indexStatus?: KnowledgeIndexStatus;
        subject?: string;
      }>(req);

      const result = await this.listDocumentsUseCase.execute({
        actor,
        sourceTypes: query.sourceType ? [query.sourceType] : undefined,
        indexStatuses: query.indexStatus ? [query.indexStatus] : undefined,
        subject: query.subject,
        page: query.page ?? 1,
        limit: query.limit ?? 20,
      });

      res.status(200).json({
        data: result.data.map(toKnowledgeDocumentDto),
        meta: result.meta,
      });
    } catch (err) {
      next(err);
    }
  };

  public getDocument = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = requireUser(req);
      const doc = await this.getDocumentUseCase.execute(actor, req.params.id as string);
      res.status(200).json({ data: toKnowledgeDocumentDto(doc) });
    } catch (err) {
      next(err);
    }
  };

  public deleteDocument = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = requireUser(req);
      const result = await this.deleteDocumentUseCase.execute(actor, req.params.id as string);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public reindex = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = requireUser(req);
      const body = req.body as {
        sourceTypes?: KnowledgeSourceType[];
        documentId?: string;
        force?: boolean;
      };
      const result = await this.reindexUseCase.execute({
        actor,
        sourceTypes: body.sourceTypes,
        documentId: body.documentId,
        force: body.force,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public getStatus = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const status = await this.statusUseCase.execute();
      res.status(200).json({ data: toKnowledgeStatusDto(status) });
    } catch (err) {
      next(err);
    }
  };
}
