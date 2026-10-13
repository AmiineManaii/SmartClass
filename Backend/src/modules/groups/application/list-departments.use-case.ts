import type {
  DepartmentView,
  GroupRepositoryPort,
} from '../domain/group-repository.port.js';

export interface ListDepartmentsResult {
  departments: DepartmentView[];
}

export class ListDepartmentsUseCase {
  constructor(private readonly groups: GroupRepositoryPort) {}

  public async execute(): Promise<ListDepartmentsResult> {
    const departments = await this.groups.listDepartments();

    return { departments };
  }
}
