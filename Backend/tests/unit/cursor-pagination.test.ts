import { describe, it, expect } from 'vitest';
import {
  encodeCursor,
  decodeCursor,
  buildCursorPaginationResult,
} from '../../src/shared/http/pagination/cursor-pagination.js';
import { BadRequestError } from '../../src/shared/errors/index.js';

describe('Cursor Pagination', () => {
  const testDate = new Date('2026-01-15T10:30:00.000Z');
  const testId = '550e8400-e29b-41d4-a716-446655440000';

  describe('encodeCursor / decodeCursor', () => {
    it('round-trips a cursor correctly', () => {
      const encoded = encodeCursor(testDate, testId);
      const decoded = decodeCursor(encoded);
      expect(decoded.createdAt.toISOString()).toBe(testDate.toISOString());
      expect(decoded.id).toBe(testId);
    });

    it('throws BadRequestError for invalid base64', () => {
      expect(() => decodeCursor('not-valid-base64!!')).toThrow(BadRequestError);
    });

    it('throws BadRequestError for valid base64 but invalid JSON', () => {
      const badCursor = Buffer.from('not json at all', 'utf8').toString('base64url');
      expect(() => decodeCursor(badCursor)).toThrow(BadRequestError);
    });

    it('throws BadRequestError for missing fields', () => {
      const partial = Buffer.from(JSON.stringify({ createdAt: '2026-01-01' }), 'utf8').toString('base64url');
      expect(() => decodeCursor(partial)).toThrow(BadRequestError);
    });

    it('throws BadRequestError for invalid date', () => {
      const badDate = Buffer.from(JSON.stringify({ createdAt: 'not-a-date', id: testId }), 'utf8').toString('base64url');
      expect(() => decodeCursor(badDate)).toThrow(BadRequestError);
    });
  });

  describe('buildCursorPaginationResult', () => {
    it('returns hasMore=false and null cursor when items <= limit', () => {
      const items = [
        { id: '1', createdAt: new Date(), name: 'A' },
        { id: '2', createdAt: new Date(), name: 'B' },
      ];
      const result = buildCursorPaginationResult(items, 5);
      expect(result.data).toHaveLength(2);
      expect(result.meta.hasMore).toBe(false);
      expect(result.meta.nextCursor).toBeNull();
    });

    it('returns hasMore=true and a cursor when items > limit', () => {
      const now = new Date();
      const items = Array.from({ length: 6 }, (_, i) => ({
        id: String(i),
        createdAt: new Date(now.getTime() + i * 1000),
      }));
      const result = buildCursorPaginationResult(items, 5);
      expect(result.data).toHaveLength(5);
      expect(result.meta.hasMore).toBe(true);
      expect(result.meta.nextCursor).toBeTruthy();

      // Verify cursor decodes to the last item in data
      const decoded = decodeCursor(result.meta.nextCursor!);
      expect(decoded.id).toBe('4');
    });

    it('handles empty array', () => {
      const result = buildCursorPaginationResult([], 20);
      expect(result.data).toHaveLength(0);
      expect(result.meta.hasMore).toBe(false);
      expect(result.meta.nextCursor).toBeNull();
    });
  });
});
