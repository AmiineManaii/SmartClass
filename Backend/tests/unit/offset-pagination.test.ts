import { describe, it, expect } from 'vitest';
import {
  getOffsetPaginationParams,
  buildOffsetPaginationMeta,
} from '../../src/shared/http/pagination/offset-pagination.js';

describe('Offset Pagination', () => {
  describe('getOffsetPaginationParams', () => {
    it('returns defaults when no query provided', () => {
      const result = getOffsetPaginationParams();
      expect(result).toEqual({ page: 1, limit: 20, skip: 0, take: 20 });
    });

    it('calculates correct skip for page 3', () => {
      const result = getOffsetPaginationParams({ page: 3, limit: 10 });
      expect(result).toEqual({ page: 3, limit: 10, skip: 20, take: 10 });
    });

    it('clamps page to minimum 1', () => {
      const result = getOffsetPaginationParams({ page: -5, limit: 20 });
      expect(result.page).toBe(1);
      expect(result.skip).toBe(0);
    });

    it('clamps limit to maximum 100', () => {
      const result = getOffsetPaginationParams({ page: 1, limit: 999 });
      expect(result.limit).toBe(100);
      expect(result.take).toBe(100);
    });

    it('clamps limit to minimum 1', () => {
      const result = getOffsetPaginationParams({ page: 1, limit: 0 });
      expect(result.limit).toBe(1);
    });
  });

  describe('buildOffsetPaginationMeta', () => {
    it('builds correct meta for first page', () => {
      const meta = buildOffsetPaginationMeta({ page: 1, limit: 10, total: 25 });
      expect(meta).toEqual({
        page: 1,
        limit: 10,
        total: 25,
        totalPages: 3,
        hasNextPage: true,
        hasPreviousPage: false,
      });
    });

    it('builds correct meta for last page', () => {
      const meta = buildOffsetPaginationMeta({ page: 3, limit: 10, total: 25 });
      expect(meta).toEqual({
        page: 3,
        limit: 10,
        total: 25,
        totalPages: 3,
        hasNextPage: false,
        hasPreviousPage: true,
      });
    });

    it('handles empty result', () => {
      const meta = buildOffsetPaginationMeta({ page: 1, limit: 20, total: 0 });
      expect(meta.totalPages).toBe(0);
      expect(meta.hasNextPage).toBe(false);
      expect(meta.hasPreviousPage).toBe(false);
    });

    it('handles exact page boundary', () => {
      const meta = buildOffsetPaginationMeta({ page: 2, limit: 10, total: 20 });
      expect(meta.totalPages).toBe(2);
      expect(meta.hasNextPage).toBe(false);
      expect(meta.hasPreviousPage).toBe(true);
    });
  });
});
