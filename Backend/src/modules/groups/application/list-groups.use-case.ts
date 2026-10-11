import {
  buildOffsetPaginationMeta,
  type OffsetPaginationMeta,
} from '../../../shared/http/pagination/index.js';
import type { ClassGroupSummary } from '../domain/class-group.entity.js';
import type { GroupRepositoryPort, ListGroupsQuery } from '../domain/group-repository.port.js';

export interface ListGroupsResult {
  groups: ClassGroupSummary[];
  meta: OffsetPaginationMeta;
}

export class ListGroupsUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(query: ListGroupsQuery): Promise<ListGroupsResult> {
    const { groups, total } = await this.groups.listGroups(query);

    return {
      groups,
      meta: buildOffsetPaginationMeta({ page: query.page, limit: query.limit, total }),
    };
  }
}
