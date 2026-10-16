import { describe, expect, it, vi } from 'vitest';
import crypto from 'node:crypto';
import { GenerateInvitationUseCase } from '../../src/modules/groups/application/generate-invitation.use-case.js';
import { RotateInvitationUseCase } from '../../src/modules/groups/application/rotate-invitation.use-case.js';
import { RevokeInvitationUseCase } from '../../src/modules/groups/application/revoke-invitation.use-case.js';
import { GetInvitationStatusUseCase } from '../../src/modules/groups/application/get-invitation-status.use-case.js';
import { JoinClassUseCase } from '../../src/modules/groups/application/join-class.use-case.js';
import { LeaveClassUseCase } from '../../src/modules/groups/application/leave-class.use-case.js';
import { CreateVirtualClassroomUseCase } from '../../src/modules/groups/application/create-virtual-classroom.use-case.js';
import { RemoveMembersUseCase } from '../../src/modules/groups/application/remove-members.use-case.js';
import { UpdateTeacherApprovalUseCase } from '../../src/modules/users/application/update-teacher-approval.use-case.js';
import { createRequireApprovedTeacherMiddleware } from '../../src/modules/auth/presentation/auth.middleware.js';
import type { GroupRepositoryPort, ClassInvitationRecord } from '../../src/modules/groups/domain/group-repository.port.js';
import type { ClassGroupDetail } from '../../src/modules/groups/domain/class-group.entity.js';
import type { UserDirectoryPort } from '../../src/modules/users/domain/user-directory.port.js';
import type { AuditServicePort } from '../../src/shared/audit/audit.service.js';
import { ForbiddenError, NotFoundError, BadRequestError } from '../../src/shared/errors/app-error.js';
import { SaveCourseUseCase } from '../../src/modules/courses/application/save-course.use-case.js';
import { GetCourseUseCase } from '../../src/modules/courses/application/get-course.use-case.js';
import { ListPublishedCoursesUseCase } from '../../src/modules/courses/application/list-published-courses.use-case.js';
import type { CourseRepositoryPort } from '../../src/modules/courses/domain/course-repository.port.js';
import type { CourseDetail } from '../../src/modules/courses/domain/course.entity.js';

describe('RBAC & Teacher Approval', () => {
  const mockAuthRepository = {
    findUserById: vi.fn(),
    findUserByEmail: vi.fn(),
    createUser: vi.fn(),
    updateUser: vi.fn(),
    revokeAllUserTokens: vi.fn().mockResolvedValue(undefined),
  };

  const mockAuditService: AuditServicePort = {
    record: vi.fn().mockResolvedValue(undefined),
  };

  it('admin approves pending teacher successfully', async () => {
    const pendingTeacher = {
      id: 'teacher-1',
      email: 'teacher@test.com',
      firstName: 'Prof',
      lastName: 'Oak',
      role: 'TEACHER',
      isEmailVerified: true,
      teacherApprovalStatus: 'PENDING',
    };

    const approvedTeacher = {
      ...pendingTeacher,
      teacherApprovalStatus: 'APPROVED',
      toSafeUser: () => ({ ...pendingTeacher, teacherApprovalStatus: 'APPROVED' }),
    };

    vi.mocked(mockAuthRepository.findUserById).mockResolvedValue(pendingTeacher as any);
    vi.mocked(mockAuthRepository.updateUser).mockResolvedValue(approvedTeacher as any);

    const useCase = new UpdateTeacherApprovalUseCase(mockAuthRepository as any, mockAuditService);
    const result = await useCase.execute('admin-1', 'teacher-1', 'APPROVED');

    expect(result.user.teacherApprovalStatus).toBe('APPROVED');
    expect(mockAuditService.record).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'TEACHER_APPROVED',
        targetId: 'teacher-1',
      }),
    );
  });

  it('rejects approval update if target is not a teacher', async () => {
    vi.mocked(mockAuthRepository.findUserById).mockResolvedValue({
      id: 'student-1',
      email: 'student@test.com',
      firstName: 'Ash',
      lastName: 'Ketchum',
      role: 'STUDENT',
      isEmailVerified: true,
      teacherApprovalStatus: null,
    } as any);

    const useCase = new UpdateTeacherApprovalUseCase(mockAuthRepository as any, mockAuditService);
    await expect(
      useCase.execute('admin-1', 'student-1', 'APPROVED'),
    ).rejects.toThrow(BadRequestError);
  });

  describe('createRequireApprovedTeacherMiddleware', () => {
    const middleware = createRequireApprovedTeacherMiddleware(['TEACHER', 'ADMIN']);

    it('allows ADMIN regardless of teacherApprovalStatus', () => {
      const next = vi.fn();
      const req: any = { user: { id: 'admin-1', role: 'ADMIN', teacherApprovalStatus: null } };
      middleware(req, {} as any, next);
      expect(next).toHaveBeenCalledWith();
    });

    it('allows APPROVED TEACHER', () => {
      const next = vi.fn();
      const req: any = { user: { id: 'teacher-1', role: 'TEACHER', teacherApprovalStatus: 'APPROVED' } };
      middleware(req, {} as any, next);
      expect(next).toHaveBeenCalledWith();
    });

    it('blocks PENDING TEACHER with 403 Forbidden', () => {
      const next = vi.fn();
      const req: any = { user: { id: 'teacher-2', role: 'TEACHER', teacherApprovalStatus: 'PENDING' } };
      expect(() => middleware(req, {} as any, next)).toThrow(ForbiddenError);
    });

    it('blocks REJECTED TEACHER with 403 Forbidden', () => {
      const next = vi.fn();
      const req: any = { user: { id: 'teacher-3', role: 'TEACHER', teacherApprovalStatus: 'REJECTED' } };
      expect(() => middleware(req, {} as any, next)).toThrow(ForbiddenError);
    });

    it('blocks STUDENT from teacher routes', () => {
      const next = vi.fn();
      const req: any = { user: { id: 'student-1', role: 'STUDENT' } };
      expect(() => middleware(req, {} as any, next)).toThrow(ForbiddenError);
    });
  });
});

describe('Class Invitation System & Membership Lifecycle', () => {
  const dummyGroup: ClassGroupDetail = {
    id: 'group-1',
    name: 'Informatique L1',
    level: 'LICENCE',
    department: 'Informatique',
    academicYear: '2026-2027',
    capacity: 40,
    memberCount: 10,
    teacherCount: 2,
    description: 'Promo L1',
    forumEnabled: true,
    entSyncEnabled: true,
    status: 'PUBLISHED',
    isVirtual: false,
    ownerId: null,
    referentId: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    referent: null,
  };

  const createMockGroupRepository = (): GroupRepositoryPort => ({
    listGroups: vi.fn(),
    listMyGroups: vi.fn(),
    findGroupDetailById: vi.fn().mockResolvedValue(dummyGroup),
    createGroup: vi.fn(),
    updateGroup: vi.fn(),
    deleteGroup: vi.fn(),
    listDistinctDepartments: vi.fn(),
    listGroupMembers: vi.fn(),
    assignMembers: vi.fn(),
    removeMembers: vi.fn().mockResolvedValue({ removed: ['student-1'], memberCount: 9 }),
    listTeacherAssignments: vi.fn(),
    assignTeachers: vi.fn(),
    removeTeacherAssignments: vi.fn(),
    isTeacherAuthorizedForGroup: vi.fn().mockResolvedValue(true),
    findUserClassMembership: vi.fn().mockResolvedValue({
      isMember: false,
      isTeacher: false,
      isReferent: false,
      isOwner: false,
    }),
    createInvitation: vi.fn(),
    findActiveInvitationByGroupId: vi.fn(),
    findInvitationByCodeHash: vi.fn(),
    rotateInvitation: vi.fn(),
    revokeInvitation: vi.fn().mockResolvedValue(undefined),
    joinGroupWithInvitation: vi.fn(),
    leaveGroup: vi.fn().mockResolvedValue(true),
  });

  const mockAuditService: AuditServicePort = {
    record: vi.fn().mockResolvedValue(undefined),
  };

  it('assigned teacher generates an invitation code with hash storage', async () => {
    const repo = createMockGroupRepository();
    const createdInvitation: ClassInvitationRecord = {
      id: 'inv-1',
      classGroupId: 'group-1',
      codeHash: 'hash-abc',
      codePrefix: 'SC-A',
      creatorId: 'teacher-1',
      status: 'ACTIVE',
      expiresAt: new Date(Date.now() + 3600000),
      maxUses: 30,
      usedCount: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    vi.mocked(repo.createInvitation).mockResolvedValue(createdInvitation);

    const useCase = new GenerateInvitationUseCase(repo, mockAuditService);
    const result = await useCase.execute({
      groupId: 'group-1',
      actorId: 'teacher-1',
      actorRole: 'TEACHER',
      expiresInHours: 24,
      maxUses: 30,
    });

    expect(result.rawCode).toMatch(/^SC-[0-9A-F]{8}$/);
    expect(result.classGroupId).toBe('group-1');
    expect(repo.createInvitation).toHaveBeenCalledWith(
      expect.objectContaining({
        groupId: 'group-1',
        creatorId: 'teacher-1',
        maxUses: 30,
      }),
    );
  });

  it('unauthorized teacher cannot generate invitation', async () => {
    const repo = createMockGroupRepository();
    vi.mocked(repo.isTeacherAuthorizedForGroup).mockResolvedValue(false);

    const useCase = new GenerateInvitationUseCase(repo, mockAuditService);
    await expect(
      useCase.execute({
        groupId: 'group-1',
        actorId: 'unassigned-teacher',
        actorRole: 'TEACHER',
      }),
    ).rejects.toThrow(ForbiddenError);
  });

  it('rotating invitation revokes existing code and creates a new one', async () => {
    const repo = createMockGroupRepository();
    const rotatedInvitation: ClassInvitationRecord = {
      id: 'inv-2',
      classGroupId: 'group-1',
      codeHash: 'hash-xyz',
      codePrefix: 'SC-B',
      creatorId: 'teacher-1',
      status: 'ACTIVE',
      expiresAt: null,
      maxUses: 50,
      usedCount: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    vi.mocked(repo.rotateInvitation).mockResolvedValue(rotatedInvitation);

    const useCase = new RotateInvitationUseCase(repo, mockAuditService);
    const result = await useCase.execute({
      groupId: 'group-1',
      actorId: 'teacher-1',
      actorRole: 'TEACHER',
    });

    expect(result.id).toBe('inv-2');
    expect(result.rawCode).toMatch(/^SC-[0-9A-F]{8}$/);
    expect(repo.rotateInvitation).toHaveBeenCalled();
  });

  it('revoking invitation marks code as revoked', async () => {
    const repo = createMockGroupRepository();
    const useCase = new RevokeInvitationUseCase(repo, mockAuditService);

    const result = await useCase.execute({
      groupId: 'group-1',
      actorId: 'teacher-1',
      actorRole: 'TEACHER',
    });

    expect(result.message).toContain('revoked successfully');
    expect(repo.revokeInvitation).toHaveBeenCalledWith('group-1');
  });

  it('gets invitation status without exposing raw code or hash', async () => {
    const repo = createMockGroupRepository();
    vi.mocked(repo.findActiveInvitationByGroupId).mockResolvedValue({
      id: 'inv-1',
      classGroupId: 'group-1',
      codeHash: 'secret-hash',
      codePrefix: 'SC-A',
      creatorId: 'teacher-1',
      status: 'ACTIVE',
      expiresAt: new Date(Date.now() + 100000),
      maxUses: 25,
      usedCount: 3,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const useCase = new GetInvitationStatusUseCase(repo);
    const result = await useCase.execute({
      groupId: 'group-1',
      actorId: 'teacher-1',
      actorRole: 'TEACHER',
    });

    expect(result.hasActiveInvitation).toBe(true);
    expect(result.invitation?.id).toBe('inv-1');
    expect((result.invitation as any).codeHash).toBeUndefined();
    expect((result.invitation as any).rawCode).toBeUndefined();
    expect(result.invitation?.usedCount).toBe(3);
  });

  describe('Student joinClass', () => {
    it('student joins successfully with valid code', async () => {
      const repo = createMockGroupRepository();
      const rawCode = 'SC-VALID12';
      const codeHash = crypto.createHash('sha256').update(rawCode).digest('hex');

      vi.mocked(repo.findInvitationByCodeHash).mockResolvedValue({
        id: 'inv-1',
        classGroupId: 'group-1',
        codeHash,
        codePrefix: 'SC-V',
        creatorId: 'teacher-1',
        status: 'ACTIVE',
        expiresAt: new Date(Date.now() + 1000000),
        maxUses: 50,
        usedCount: 5,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      vi.mocked(repo.joinGroupWithInvitation).mockResolvedValue({
        classGroup: { ...dummyGroup, memberCount: 11 },
        membership: {
          id: 'mem-1',
          classGroupId: 'group-1',
          userId: 'student-1',
          joinedAt: new Date(),
        },
      });

      const useCase = new JoinClassUseCase(repo, mockAuditService);
      const result = await useCase.execute({
        rawCode,
        studentId: 'student-1',
        studentRole: 'STUDENT',
      });

      expect(result.message).toContain('Successfully joined Informatique L1');
      expect(repo.joinGroupWithInvitation).toHaveBeenCalledWith('inv-1', 'group-1', 'student-1');
    });

    it('rejects non-student from using join code', async () => {
      const repo = createMockGroupRepository();
      const useCase = new JoinClassUseCase(repo, mockAuditService);

      await expect(
        useCase.execute({
          rawCode: 'SC-VALID12',
          studentId: 'teacher-1',
          studentRole: 'TEACHER',
        }),
      ).rejects.toThrow(ForbiddenError);
    });

    it('rejects expired invitation code', async () => {
      const repo = createMockGroupRepository();
      const rawCode = 'SC-EXPIRED';
      const codeHash = crypto.createHash('sha256').update(rawCode).digest('hex');

      vi.mocked(repo.findInvitationByCodeHash).mockResolvedValue({
        id: 'inv-exp',
        classGroupId: 'group-1',
        codeHash,
        codePrefix: 'SC-E',
        creatorId: 'teacher-1',
        status: 'ACTIVE',
        expiresAt: new Date(Date.now() - 10000), // expired
        maxUses: 50,
        usedCount: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const useCase = new JoinClassUseCase(repo, mockAuditService);
      await expect(
        useCase.execute({
          rawCode,
          studentId: 'student-1',
          studentRole: 'STUDENT',
        }),
      ).rejects.toThrow(BadRequestError);
    });

    it('rejects code when max uses limit is reached', async () => {
      const repo = createMockGroupRepository();
      const rawCode = 'SC-MAXUSES';
      const codeHash = crypto.createHash('sha256').update(rawCode).digest('hex');

      vi.mocked(repo.findInvitationByCodeHash).mockResolvedValue({
        id: 'inv-max',
        classGroupId: 'group-1',
        codeHash,
        codePrefix: 'SC-M',
        creatorId: 'teacher-1',
        status: 'ACTIVE',
        expiresAt: null,
        maxUses: 10,
        usedCount: 10, // full
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const useCase = new JoinClassUseCase(repo, mockAuditService);
      await expect(
        useCase.execute({
          rawCode,
          studentId: 'student-1',
          studentRole: 'STUDENT',
        }),
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('Student leaveClass', () => {
    it('enrolled student leaves successfully', async () => {
      const repo = createMockGroupRepository();
      vi.mocked(repo.leaveGroup).mockResolvedValue(true);

      const useCase = new LeaveClassUseCase(repo, mockAuditService);
      const result = await useCase.execute({
        groupId: 'group-1',
        studentId: 'student-1',
      });

      expect(result.message).toContain('Successfully left Informatique L1');
      expect(repo.leaveGroup).toHaveBeenCalledWith('group-1', 'student-1');
    });

    it('throws if student was not enrolled in class', async () => {
      const repo = createMockGroupRepository();
      vi.mocked(repo.leaveGroup).mockResolvedValue(false);

      const useCase = new LeaveClassUseCase(repo, mockAuditService);
      await expect(
        useCase.execute({
          groupId: 'group-1',
          studentId: 'not-enrolled-student',
        }),
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('Virtual Classrooms', () => {
    it('teacher creates a virtual classroom with isVirtual=true', async () => {
      const repo = createMockGroupRepository();
      vi.mocked(repo.createGroup).mockResolvedValue({
        ...dummyGroup,
        id: 'virt-1',
        name: 'Maths Avancées - Atelier',
        isVirtual: true,
        ownerId: 'teacher-1',
      });

      const useCase = new CreateVirtualClassroomUseCase(repo, mockAuditService);
      const result = await useCase.execute({
        teacherId: 'teacher-1',
        teacherRole: 'TEACHER',
        name: 'Maths Avancées - Atelier',
        capacity: 30,
      });

      expect(result.isVirtual).toBe(true);
      expect(result.ownerId).toBe('teacher-1');
      expect(repo.createGroup).toHaveBeenCalledWith(
        expect.objectContaining({
          isVirtual: true,
          ownerId: 'teacher-1',
        }),
      );
    });

    it('student cannot create a virtual classroom', async () => {
      const repo = createMockGroupRepository();
      const useCase = new CreateVirtualClassroomUseCase(repo, mockAuditService);

      await expect(
        useCase.execute({
          teacherId: 'student-1',
          teacherRole: 'STUDENT',
          name: 'Class',
        }),
      ).rejects.toThrow(ForbiddenError);
    });
  });

  describe('Teacher student removal', () => {
    it('assigned teacher removes students from class', async () => {
      const repo = createMockGroupRepository();
      vi.mocked(repo.isTeacherAuthorizedForGroup).mockResolvedValue(true);

      const useCase = new RemoveMembersUseCase(repo, mockAuditService);
      const result = await useCase.execute(
        'group-1',
        ['student-1'],
        'teacher-1',
        'TEACHER',
      );

      expect(result.removed).toContain('student-1');
      expect(repo.removeMembers).toHaveBeenCalledWith('group-1', ['student-1']);
    });

    it('unauthorized teacher cannot remove students', async () => {
      const repo = createMockGroupRepository();
      vi.mocked(repo.isTeacherAuthorizedForGroup).mockResolvedValue(false);

      const useCase = new RemoveMembersUseCase(repo, mockAuditService);
      await expect(
        useCase.execute(
          'group-1',
          ['student-1'],
          'stranger-teacher',
          'TEACHER',
        ),
      ).rejects.toThrow(ForbiddenError);
    });
  });

  describe('Course-to-Class RBAC & Access Restrictions', () => {
    const mockCourseRepo: CourseRepositoryPort = {
      save: vi.fn(),
      update: vi.fn(),
      findById: vi.fn(),
      listByAuthor: vi.fn(),
      listPublished: vi.fn(),
      delete: vi.fn(),
    };

    it('teacher cannot associate course with a class they do not teach', async () => {
      const groupRepo = createMockGroupRepository();
      vi.mocked(groupRepo.isTeacherAuthorizedForGroup).mockResolvedValue(false);

      const useCase = new SaveCourseUseCase(mockCourseRepo, groupRepo);
      await expect(
        useCase.execute({
          requesterId: 'teacher-unassigned',
          requesterRole: 'TEACHER',
          title: 'Data Structures',
          content: 'Course content',
          level: 'detaille',
          classGroupIds: ['group-unassigned'],
        }),
      ).rejects.toThrow(ForbiddenError);
    });

    it('teacher can associate course with a class they are assigned to teach', async () => {
      const groupRepo = createMockGroupRepository();
      vi.mocked(groupRepo.isTeacherAuthorizedForGroup).mockResolvedValue(true);
      vi.mocked(mockCourseRepo.save).mockResolvedValue({
        id: 'c-1',
        title: 'Algorithms',
        subject: 'CS',
        content: 'Content',
        level: 'detaille',
        difficulty: 'moyen',
        format: 'resume',
        status: 'DRAFT',
        authorId: 'teacher-1',
        authorName: 'Prof Oak',
        createdAt: new Date(),
        updatedAt: new Date(),
        classGroupIds: ['group-1'],
      });

      const useCase = new SaveCourseUseCase(mockCourseRepo, groupRepo);
      const res = await useCase.execute({
        requesterId: 'teacher-1',
        requesterRole: 'TEACHER',
        title: 'Algorithms',
        content: 'Content',
        level: 'detaille',
        classGroupIds: ['group-1'],
      });

      expect(res.id).toBe('c-1');
      expect(mockCourseRepo.save).toHaveBeenCalled();
    });

    it('student enrolled in class can view course scoped to that class', async () => {
      const groupRepo = createMockGroupRepository();
      vi.mocked(groupRepo.listMyGroups).mockResolvedValue([
        {
          id: 'group-1',
          name: 'Informatique L1',
          academicYear: '2026',
          department: 'INFO',
          level: 'L1',
          memberCount: 20,
          status: 'ACTIVE',
          myRole: 'STUDENT',
          joinedAt: new Date(),
        },
      ]);

      vi.mocked(mockCourseRepo.findById).mockResolvedValue({
        id: 'c-scoped',
        title: 'Algorithms',
        subject: 'CS',
        content: 'Secret curriculum',
        level: 'detaille',
        difficulty: 'moyen',
        format: 'resume',
        status: 'PUBLISHED',
        authorId: 'teacher-1',
        authorName: 'Prof Oak',
        createdAt: new Date(),
        updatedAt: new Date(),
        classGroupIds: ['group-1'],
      });

      const useCase = new GetCourseUseCase(mockCourseRepo, groupRepo);
      const res = await useCase.execute({
        courseId: 'c-scoped',
        requesterId: 'student-enrolled',
        requesterRole: 'STUDENT',
      });

      expect(res.id).toBe('c-scoped');
    });

    it('student not enrolled in class cannot view course scoped to that class', async () => {
      const groupRepo = createMockGroupRepository();
      vi.mocked(groupRepo.listMyGroups).mockResolvedValue([
        {
          id: 'group-other',
          name: 'Biologie L1',
          academicYear: '2026',
          department: 'BIO',
          level: 'L1',
          memberCount: 15,
          status: 'ACTIVE',
          myRole: 'STUDENT',
          joinedAt: new Date(),
        },
      ]);

      vi.mocked(mockCourseRepo.findById).mockResolvedValue({
        id: 'c-scoped',
        title: 'Algorithms',
        subject: 'CS',
        content: 'Secret curriculum',
        level: 'detaille',
        difficulty: 'moyen',
        format: 'resume',
        status: 'PUBLISHED',
        authorId: 'teacher-1',
        authorName: 'Prof Oak',
        createdAt: new Date(),
        updatedAt: new Date(),
        classGroupIds: ['group-1'], // requires group-1, student only has group-other
      });

      const useCase = new GetCourseUseCase(mockCourseRepo, groupRepo);
      await expect(
        useCase.execute({
          courseId: 'c-scoped',
          requesterId: 'student-other',
          requesterRole: 'STUDENT',
        }),
      ).rejects.toThrow(NotFoundError);
    });

    it('listPublished filters out courses scoped to unrelated classes for students', async () => {
      const groupRepo = createMockGroupRepository();
      vi.mocked(groupRepo.listMyGroups).mockResolvedValue([
        {
          id: 'group-1',
          name: 'Informatique L1',
          academicYear: '2026',
          department: 'INFO',
          level: 'L1',
          memberCount: 20,
          status: 'ACTIVE',
          myRole: 'STUDENT',
          joinedAt: new Date(),
        },
      ]);

      vi.mocked(mockCourseRepo.listPublished).mockResolvedValue([
        {
          id: 'c-public',
          title: 'Public Guide',
          subject: 'General',
          level: 'concis',
          difficulty: 'facile',
          format: 'resume',
          status: 'PUBLISHED',
          authorId: 'teacher-1',
          createdAt: new Date(),
          updatedAt: new Date(),
          classGroupIds: [],
        },
        {
          id: 'c-my-class',
          title: 'My Class Course',
          subject: 'CS',
          level: 'concis',
          difficulty: 'facile',
          format: 'resume',
          status: 'PUBLISHED',
          authorId: 'teacher-1',
          createdAt: new Date(),
          updatedAt: new Date(),
          classGroupIds: ['group-1'],
        },
        {
          id: 'c-other-class',
          title: 'Other Class Course',
          subject: 'Physics',
          level: 'detaille',
          difficulty: 'difficile',
          format: 'resume',
          status: 'PUBLISHED',
          authorId: 'teacher-2',
          createdAt: new Date(),
          updatedAt: new Date(),
          classGroupIds: ['group-999'],
        },
      ]);

      const useCase = new ListPublishedCoursesUseCase(mockCourseRepo, groupRepo);
      const res = await useCase.execute('student-1', 'STUDENT');

      expect(res.map((c) => c.id)).toEqual(['c-public', 'c-my-class']);
      expect(res.map((c) => c.id)).not.toContain('c-other-class');
    });
  });
});

