import type { PrismaClient } from '@prisma/client';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';
import type { ClassMembershipPort } from '../domain/class-membership.port.js';

export class PrismaClassMembershipAdapter implements ClassMembershipPort {
  constructor(
    private readonly groupRepository?: GroupRepositoryPort,
    private readonly prisma: PrismaClient = getPrismaClient(),
  ) {}

  public async listEnrolledClassGroupIds(userId: string): Promise<string[]> {
    if (this.groupRepository) {
      const groups = await this.groupRepository.listMyGroups(userId);
      return groups.map((g) => g.id);
    }

    const rows = await this.prisma.groupMember.findMany({
      where: { userId },
      select: { classGroupId: true },
    });
    return rows.map((r: { classGroupId: string }) => r.classGroupId);
  }
}
