import { describe, it, expect } from 'vitest';
import { ExportUserDataUseCase } from '../../src/modules/users/application/export-user-data.use-case.js';
import type { ExportDataPort, UserExportData } from '../../src/modules/users/domain/export-data.port.js';
import { PdfExportGenerator } from '../../src/modules/users/infrastructure/pdf-export-generator.js';

describe('ExportUserDataUseCase & PdfExportGenerator', () => {
  const mockExportData: UserExportData = {
    exportedAt: new Date().toISOString(),
    format: 'SmartClass RGPD Art. 20 Export',
    user: {
      id: '00000000-0000-0000-0000-000000000001',
      email: 'alex.dupont@smartclass.edu',
      firstName: 'Alex',
      lastName: 'Dupont',
      role: 'STUDENT',
      status: 'ACTIVE',
      emailVerified: true,
      twoFactorEnabled: false,
      birthDate: '2002-05-14',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
    groups: [
      {
        groupId: 'grp-1',
        groupName: 'Master 1 Informatique',
        level: 'M1',
        department: 'Informatique & IA',
        academicYear: '2025-2026',
        joinedAt: new Date().toISOString(),
      },
    ],
    enrolledCourses: [
      {
        id: 'crs-1',
        title: 'Algorithmique Avancée & Graphes',
        subject: 'Informatique',
        level: 'M1',
        difficulty: 'ADVANCED',
        status: 'PUBLISHED',
        sectionsCount: 4,
        createdAt: new Date().toISOString(),
      },
    ],
    timetable: [
      {
        title: 'Cours Magistral - Algorithmique',
        kind: 'LECTURE',
        startsAt: new Date().toISOString(),
        endsAt: new Date().toISOString(),
        room: 'Amphi A',
        groupName: 'Master 1 Informatique',
      },
    ],
    recentAuditLogs: [
      {
        action: 'USER_LOGIN',
        targetType: 'USER',
        targetId: '00000000-0000-0000-0000-000000000001',
        createdAt: new Date().toISOString(),
      },
    ],
  };

  class FakeExportDataAdapter implements ExportDataPort {
    public async getUserExportData(): Promise<UserExportData> {
      return mockExportData;
    }
  }

  it('successfully fetches user export data through the use case', async () => {
    const fakeAdapter = new FakeExportDataAdapter();
    const useCase = new ExportUserDataUseCase(fakeAdapter);

    const result = await useCase.execute({
      userId: '00000000-0000-0000-0000-000000000001',
      role: 'STUDENT',
    });

    expect(result).toBeDefined();
    expect(result.user.email).toBe('alex.dupont@smartclass.edu');
    expect(result.groups).toHaveLength(1);
    expect(result.enrolledCourses).toHaveLength(1);
  });

  it('rejects execution when userId is missing', async () => {
    const fakeAdapter = new FakeExportDataAdapter();
    const useCase = new ExportUserDataUseCase(fakeAdapter);

    await expect(
      useCase.execute({
        userId: '',
        role: 'STUDENT',
      }),
    ).rejects.toThrow('UserId is required');
  });

  it('generates a valid, non-empty PDF binary buffer with PDF magic bytes', async () => {
    const generator = new PdfExportGenerator();
    const buffer = await generator.generatePdf(mockExportData);

    expect(buffer).toBeInstanceOf(Buffer);
    expect(buffer.length).toBeGreaterThan(1000);
    // Standard PDF header signature: %PDF-
    const headerStr = buffer.subarray(0, 5).toString('ascii');
    expect(headerStr).toBe('%PDF-');
  });

  it('generates a valid PDF for teachers with assignments and authored courses', async () => {
    const teacherData: UserExportData = {
      ...mockExportData,
      user: {
        ...mockExportData.user,
        role: 'TEACHER',
        firstName: 'Sarah',
        lastName: 'Conor',
        email: 'sarah.conor@smartclass.edu',
      },
      assignments: [
        {
          groupId: 'grp-2',
          groupName: 'Licence 3 Informatique',
          subject: 'Programmation Web',
          weeklyHours: '4h / semaine',
          assignedAt: new Date().toISOString(),
        },
      ],
      authoredCourses: [
        {
          id: 'crs-2',
          title: 'Architecture Microservices avec Node.js',
          subject: 'Génie Logiciel',
          level: 'L3',
          difficulty: 'INTERMEDIATE',
          status: 'PUBLISHED',
          sectionsCount: 6,
          createdAt: new Date().toISOString(),
        },
      ],
    };

    const generator = new PdfExportGenerator();
    const buffer = await generator.generatePdf(teacherData);

    expect(buffer).toBeInstanceOf(Buffer);
    expect(buffer.length).toBeGreaterThan(1000);
    expect(buffer.subarray(0, 5).toString('ascii')).toBe('%PDF-');
  });

  it('generates a valid PDF for admins with platform statistics', async () => {
    const adminData: UserExportData = {
      ...mockExportData,
      user: {
        ...mockExportData.user,
        role: 'ADMIN',
        firstName: 'System',
        lastName: 'Administrator',
      },
      platformStats: {
        totalUsers: 250,
        totalStudents: 220,
        totalTeachers: 25,
        totalAdmins: 5,
        totalGroups: 12,
        totalCourses: 45,
      },
    };

    const generator = new PdfExportGenerator();
    const buffer = await generator.generatePdf(adminData);

    expect(buffer).toBeInstanceOf(Buffer);
    expect(buffer.length).toBeGreaterThan(1000);
    expect(buffer.subarray(0, 5).toString('ascii')).toBe('%PDF-');
  });
});
