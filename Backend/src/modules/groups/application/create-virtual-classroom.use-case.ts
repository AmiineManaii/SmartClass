import type { GroupRepositoryPort } from '../domain/group-repository.port.js';
import type { ClassGroupDetail } from '../domain/class-group.entity.js';
import { ForbiddenError } from '../../../shared/errors/app-error.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';

export interface CreateVirtualClassroomParams {
  teacherId: string;
  teacherRole: string;
  name: string;
  capacity?: number;
  description?: string | null;
}

export class CreateVirtualClassroomUseCase {
  constructor(
    private readonly groupRepository: GroupRepositoryPort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(params: CreateVirtualClassroomParams): Promise<ClassGroupDetail> {
    if (params.teacherRole !== 'TEACHER' && params.teacherRole !== 'ADMIN') {
      throw new ForbiddenError('Only professors can create a virtual classroom');
    }

    const created = await this.groupRepository.createGroup({
      name: params.name.trim(),
      level: 'LICENCE',
      department: 'Enseignement Indépendant',
      capacity: params.capacity ?? 50,
      description: params.description ?? 'Classe virtuelle indépendante',
      forumEnabled: true,
      entSyncEnabled: false,
      status: 'PUBLISHED',
      isVirtual: true,
      ownerId: params.teacherId,
    });

    await this.auditService?.record({
      userId: params.teacherId,
      action: 'VIRTUAL_CLASSROOM_CREATED',
      targetType: 'CLASS_GROUP',
      targetId: created.id,
      details: {
        name: created.name,
      },
    });

    return created;
  }
}
