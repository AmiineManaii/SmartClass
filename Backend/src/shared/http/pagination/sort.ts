import { BadRequestError } from '../../errors/index.js';

export type SortOrder = 'asc' | 'desc';

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
