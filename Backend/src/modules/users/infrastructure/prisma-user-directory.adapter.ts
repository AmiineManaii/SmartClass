import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type { Prisma } from '@prisma/client';
import type { SafeUser } from '../../auth/index.js';
import type {
  ListUsersQuery,
  ListUsersResult,
  UserDirectoryPort,
} from '../domain/user-directory.port.js';

interface RawUserRow {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: string | null;
  birthDate: Date | null;
  status: string;
  emailVerified: boolean;
  onboardingCompleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export class PrismaUserDirectoryAdapter implements UserDirectoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  private toSafeUser(raw: RawUserRow): SafeUser {
    return {
      id: raw.id,
      email: raw.email,
      firstName: raw.firstName,
      lastName: raw.lastName,
      role: (raw.role ?? null) as SafeUser['role'],
      birthDate: raw.birthDate ? raw.birthDate.toISOString().slice(0, 10) : null,
      status: raw.status as SafeUser['status'],
      emailVerified: raw.emailVerified,
      onboardingCompleted: raw.onboardingCompleted,
      createdAt: raw.createdAt.toISOString(),
      updatedAt: raw.updatedAt.toISOString(),
    };
  }

  public async listUsers(query: ListUsersQuery): Promise<ListUsersResult> {
    const where: Prisma.UserWhereInput = {};
    if (query.role) {
      where.role = query.role;
    }
    if (query.search) {
      where.OR = [
        { firstName: { contains: query.search, mode: 'insensitive' } },
        { lastName: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const skip = (query.page - 1) * query.limit;
    const orderBy: Prisma.UserOrderByWithRelationInput = {
      [query.sortField]: query.sortOrder,
    };

    const [rows, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: [orderBy, { id: 'asc' }],
        skip,
        take: query.limit,
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          role: true,
          birthDate: true,
          status: true,
          emailVerified: true,
          onboardingCompleted: true,
          createdAt: true,
          updatedAt: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      users: rows.map((row) => this.toSafeUser(row)),
      total,
    };
  }
}
