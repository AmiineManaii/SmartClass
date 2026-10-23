import type { Role } from '../../auth/index.js';
import type { ExportDataPort, UserExportData } from '../domain/export-data.port.js';

export interface ExportUserDataInput {
  userId: string;
  role: Role | null;
}

export class ExportUserDataUseCase {
  constructor(private readonly exportDataPort: ExportDataPort) {}

  public async execute(input: ExportUserDataInput): Promise<UserExportData> {
    if (!input.userId) {
      throw new Error('UserId is required for exporting account data.');
    }

    return this.exportDataPort.getUserExportData(input.userId, input.role);
  }
}
