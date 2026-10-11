import { z } from 'zod';
import { BadRequestError } from '../../errors/index.js';

export type SortOrder = 'asc' | 'desc';

/**
 * Zod `sort` query schema enforcing the field whitelist at validation
 * time (→ 422 VALIDATION_ERROR). Mirrors the shared SortParam pattern
 * (`field:asc|desc`). `parseSort` stays as the runtime normalizer.
 */
export const sortQuerySchema = (allowedFields: readonly string[]) =>
  z
    .string()
    .trim()
    .max(50)
    .refine(
      (value) => {
        const match = /^([a-zA-Z]+):(asc|desc)$/.exec(value);
        return !!match && match[1] !== undefined && allowedFields.includes(match[1]);
      },
      {
        message: `Invalid sort parameter. Allowed fields: ${allowedFields.join(', ')}`,
      },
    )
    .optional();

export interface SortCriteria<T extends string> {
  field: T;
  order: SortOrder;
}

export const parseSort = <T extends string>(
  sortParam: string | undefined,
  allowedFields: readonly T[],
  defaultSort: SortCriteria<T>,
): SortCriteria<T> => {
  if (!sortParam) {
    return defaultSort;
  }

  const [field, rawOrder] = sortParam.split(':');

  if (!field || !allowedFields.includes(field as T)) {
    throw new BadRequestError(
      `Invalid sort field '${field}'. Allowed fields: ${allowedFields.join(', ')}`,
    );
  }

  const order: SortOrder = rawOrder?.toLowerCase() === 'asc' ? 'asc' : 'desc';

  return {
    field: field as T,
    order,
  };
};
