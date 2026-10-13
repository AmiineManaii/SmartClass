import { describe, it, expect } from 'vitest';
import type { Role } from '../../src/modules/auth/index.js';
import type {
  CourseDetail,
  CourseStatus,
  CourseSummary,
} from '../../src/modules/courses/domain/course.entity.js';
import type {
  CourseRepositoryPort,
  SaveCourseParams,
} from '../../src/modules/courses/domain/course-repository.port.js';
import { SaveCourseUseCase } from '../../src/modules/courses/application/save-course.use-case.js';
import { ListMyCoursesUseCase } from '../../src/modules/courses/application/list-my-courses.use-case.js';
import { ListPublishedCoursesUseCase } from '../../src/modules/courses/application/list-published-courses.use-case.js';
import { GetCourseUseCase } from '../../src/modules/courses/application/get-course.use-case.js';
import { PublishCourseUseCase } from '../../src/modules/courses/application/publish-course.use-case.js';
import { UnpublishCourseUseCase } from '../../src/modules/courses/application/unpublish-course.use-case.js';
import { DeleteCourseUseCase } from '../../src/modules/courses/application/delete-course.use-case.js';

const TEACHER = 'teacher-1';
const OTHER_TEACHER = 'teacher-2';
const ADMIN: Role = 'ADMIN';
const TEACHER_ROLE: Role = 'TEACHER';
const STUDENT_ROLE: Role = 'STUDENT';

let seq = 0;

class FakeCourseRepository implements CourseRepositoryPort {
  readonly store = new Map<string, CourseDetail>();

  async save(params: SaveCourseParams): Promise<CourseDetail> {
    seq += 1;
    const now = new Date();
    const course: CourseDetail = {
      id: `course-${seq}`,
      title: params.title,
      subject: params.subject,
      content: params.content,
      level: params.level,
      difficulty: params.difficulty,
      format: params.format,
      status: 'DRAFT',
      authorId: params.authorId,
      authorName: `Author ${params.authorId}`,
      createdAt: now,
      updatedAt: now,
    };
    this.store.set(course.id, course);
    return course;
  }

  async listByAuthor(authorId: string): Promise<CourseSummary[]> {
    return [...this.store.values()]
      .filter((c) => c.authorId === authorId)
      .map(({ content: _content, ...summary }) => summary);
  }

  async listPublished(): Promise<CourseSummary[]> {
    return [...this.store.values()]
      .filter((c) => c.status === 'PUBLISHED')
      .map(({ content: _content, ...summary }) => summary);
  }

  async findById(id: string): Promise<CourseDetail | null> {
    return this.store.get(id) ?? null;
  }

  async updateStatus(id: string, status: CourseStatus): Promise<CourseDetail> {
    const course = this.store.get(id);
    if (!course) throw new Error('missing in fake');
    const next = { ...course, status };
    this.store.set(id, next);
    return next;
  }

  async remove(id: string): Promise<void> {
    this.store.delete(id);
  }
}

const seedDraft = async (repo: FakeCourseRepository, authorId = TEACHER) =>
  repo.save({
    title: '  Les boucles  ',
    subject: 'Algorithmique',
    content: '# Les boucles\n\nContenu.',
    level: 'concis',
    difficulty: 'moyen',
    format: 'resume',
    authorId,
  });

describe('Unit: SaveCourseUseCase', () => {
  it('saves a generated course as DRAFT with trimmed fields', async () => {
    const repo = new FakeCourseRepository();
    const result = await new SaveCourseUseCase(repo).execute({
      requesterId: TEACHER,
      title: '  Les boucles  ',
      subject: 'Algorithmique',
      content: '# Les boucles',
      level: 'concis',
    });
    expect(result.status).toBe('DRAFT');
    expect(result.title).toBe('Les boucles');
    expect(result.difficulty).toBe('moyen');
    expect(result.format).toBe('resume');
    expect(result.authorId).toBe(TEACHER);
  });

  it('stores a null subject when omitted', async () => {
    const repo = new FakeCourseRepository();
    const result = await new SaveCourseUseCase(repo).execute({
      requesterId: TEACHER,
      title: 'Sans sujet',
      content: '# Vide',
      level: 'concis',
    });
    expect(result.subject).toBeNull();
  });
});

describe('Unit: course listings', () => {
  it('lists only the teacher own courses in mine', async () => {
    const repo = new FakeCourseRepository();
    await seedDraft(repo, TEACHER);
    await seedDraft(repo, OTHER_TEACHER);
    const mine = await new ListMyCoursesUseCase(repo).execute(TEACHER);
    expect(mine).toHaveLength(1);
    expect(mine[0]?.authorId).toBe(TEACHER);
    // Summaries carry no Markdown body.
    expect(mine[0]).not.toHaveProperty('content');
  });

  it('lists only published courses for everyone', async () => {
    const repo = new FakeCourseRepository();
    const draft = await seedDraft(repo, TEACHER);
    await new PublishCourseUseCase(repo).execute({
      requesterId: TEACHER,
      requesterRole: TEACHER_ROLE,
      courseId: draft.id,
    });
    await seedDraft(repo, OTHER_TEACHER);
    const published = await new ListPublishedCoursesUseCase(repo).execute();
    expect(published).toHaveLength(1);
    expect(published[0]?.status).toBe('PUBLISHED');
  });
});

describe('Unit: GetCourseUseCase', () => {
  it('shows published courses to any authenticated user', async () => {
    const repo = new FakeCourseRepository();
    const draft = await seedDraft(repo, TEACHER);
    await new PublishCourseUseCase(repo).execute({
      requesterId: TEACHER,
      requesterRole: TEACHER_ROLE,
      courseId: draft.id,
    });
    const result = await new GetCourseUseCase(repo).execute({
      requesterId: 'student-9',
      requesterRole: STUDENT_ROLE,
      courseId: draft.id,
    });
    expect(result.content).toContain('# Les boucles');
  });

  it('shows drafts to the author and to admins, 404 for others', async () => {
    const repo = new FakeCourseRepository();
    const draft = await seedDraft(repo, TEACHER);
    const get = new GetCourseUseCase(repo);
    await expect(
      get.execute({ requesterId: TEACHER, requesterRole: TEACHER_ROLE, courseId: draft.id }),
    ).resolves.toMatchObject({ id: draft.id });
    await expect(
      get.execute({ requesterId: 'admin-1', requesterRole: ADMIN, courseId: draft.id }),
    ).resolves.toMatchObject({ id: draft.id });
    await expect(
      get.execute({ requesterId: 'student-9', requesterRole: STUDENT_ROLE, courseId: draft.id }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it('returns 404 for unknown courses', async () => {
    const repo = new FakeCourseRepository();
    await expect(
      new GetCourseUseCase(repo).execute({
        requesterId: TEACHER,
        requesterRole: TEACHER_ROLE,
        courseId: '00000000-0000-0000-0000-000000000000',
      }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });
});

describe('Unit: publish / unpublish / delete', () => {
  it('lets the author validate a draft, 403 for strangers', async () => {
    const repo = new FakeCourseRepository();
    const draft = await seedDraft(repo, TEACHER);
    const publish = new PublishCourseUseCase(repo);
    await expect(
      publish.execute({ requesterId: OTHER_TEACHER, requesterRole: TEACHER_ROLE, courseId: draft.id }),
    ).rejects.toMatchObject({ statusCode: 403 });
    const result = await publish.execute({
      requesterId: TEACHER,
      requesterRole: TEACHER_ROLE,
      courseId: draft.id,
    });
    expect(result.status).toBe('PUBLISHED');
  });

  it('lets an admin validate any draft', async () => {
    const repo = new FakeCourseRepository();
    const draft = await seedDraft(repo, TEACHER);
    const result = await new PublishCourseUseCase(repo).execute({
      requesterId: 'admin-1',
      requesterRole: ADMIN,
      courseId: draft.id,
    });
    expect(result.status).toBe('PUBLISHED');
  });

  it('returns a published course to draft on unpublish', async () => {
    const repo = new FakeCourseRepository();
    const draft = await seedDraft(repo, TEACHER);
    const publish = new PublishCourseUseCase(repo);
    await publish.execute({ requesterId: TEACHER, requesterRole: TEACHER_ROLE, courseId: draft.id });
    const result = await new UnpublishCourseUseCase(repo).execute({
      requesterId: TEACHER,
      requesterRole: TEACHER_ROLE,
      courseId: draft.id,
    });
    expect(result.status).toBe('DRAFT');
  });

  it('deletes by author or admin, 403 for strangers', async () => {
    const repo = new FakeCourseRepository();
    const draft = await seedDraft(repo, TEACHER);
    await expect(
      new DeleteCourseUseCase(repo).execute({
        requesterId: OTHER_TEACHER,
        requesterRole: TEACHER_ROLE,
        courseId: draft.id,
      }),
    ).rejects.toMatchObject({ statusCode: 403 });
    const result = await new DeleteCourseUseCase(repo).execute({
      requesterId: TEACHER,
      requesterRole: TEACHER_ROLE,
      courseId: draft.id,
    });
    expect(result).toMatchObject({ id: draft.id, deleted: true });
    await expect(
      new GetCourseUseCase(repo).execute({
        requesterId: TEACHER,
        requesterRole: TEACHER_ROLE,
        courseId: draft.id,
      }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });
});
