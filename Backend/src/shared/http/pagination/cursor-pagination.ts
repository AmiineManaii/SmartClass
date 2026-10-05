import { z } from 'zod';
import { BadRequestError } from '../../errors/index.js';

export const cursorPaginationQuerySchema = z
  .object({
    cursor: z.string().optional(),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  })
  .strict();

export type CursorPaginationQuery = z.infer<typeof cursorPaginationQuerySchema>;

export interface CursorPayload {
  createdAt: string;
  id: string;
}

export interface CursorPaginationMeta {
  limit: number;
  nextCursor: string | null;
  hasMore: boolean;
}

export interface CursorPaginationResult<T> {
  data: T[];
  meta: CursorPaginationMeta;
}

export const encodeCursor = (createdAt: Date, id: string): string => {
  const payload: CursorPayload = {
    createdAt: createdAt.toISOString(),
    id,
  };
  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
};

export const decodeCursor = (cursor: string): { createdAt: Date; id: string } => {
  try {
    const raw = Buffer.from(cursor, 'base64url').toString('utf8');
    const parsed = JSON.parse(raw) as Partial<CursorPayload>;

    if (!parsed || typeof parsed !== 'object') {
      throw new Error('Cursor is not an object');
    }

    if (typeof parsed.createdAt !== 'string' || typeof parsed.id !== 'string') {
      throw new Error('Cursor missing required fields');
    }

    const date = new Date(parsed.createdAt);
    if (isNaN(date.getTime())) {
      throw new Error('Invalid cursor timestamp');
    }

    return {
      createdAt: date,
      id: parsed.id,
    };
  } catch {
    throw new BadRequestError('Invalid pagination cursor');
  }
};

export const buildCursorPaginationResult = <T extends { createdAt: Date; id: string }>(
  itemsWithExtra: T[],
  limit: number,
): CursorPaginationResult<T> => {
  const hasMore = itemsWithExtra.length > limit;
  const data = hasMore ? itemsWithExtra.slice(0, limit) : itemsWithExtra;
  const lastItem = data[data.length - 1];

  const nextCursor = hasMore && lastItem ? encodeCursor(lastItem.createdAt, lastItem.id) : null;

  return {
    data,
    meta: {
      limit,
      nextCursor,
      hasMore,
    },
  };
};
