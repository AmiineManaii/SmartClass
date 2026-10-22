import { describe, it, expect, vi } from 'vitest';
import { ApplySectionImageUseCase } from '../../src/modules/ai-assistant/application/apply-section-image.use-case.js';
import { SearchSectionImagesUseCase } from '../../src/modules/ai-assistant/application/search-section-images.use-case.js';
import type { ImageSearchResult, SearchPort } from '../../src/modules/ai-assistant/domain/search.port.js';
import type { CourseRepositoryPort } from '../../src/modules/courses/domain/course-repository.port.js';
import type { CourseSectionRepositoryPort } from '../../src/modules/courses/domain/course-section-repository.port.js';
import type { CourseSection } from '../../src/modules/courses/domain/course-section.entity.js';
import type { CourseDetail } from '../../src/modules/courses/domain/course.entity.js';

const COURSE_ID = '11111111-1111-1111-1111-111111111111';

const makeCourse = (overrides: Partial<CourseDetail> = {}): CourseDetail => ({
  id: COURSE_ID,
  title: 'Algorithmique avancée',
  subject: 'Informatique',
  content: '# Avant',
  level: 'equilibre',
  difficulty: 'moyen',
  format: 'resume',
  status: 'DRAFT',
  authorId: 'author-1',
  authorName: 'Ada Lovelace',
  classGroupIds: [],
  outline: null,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
  ...overrides,
});

const makeSections = (): CourseSection[] => [
  {
    id: 's1',
    courseId: COURSE_ID,
    sectionKey: 'sec-1',
    title: 'Tris',
    description: 'Tri rapide',
    keyTopics: ['Quick sort', 'Merge sort', 'Complexité', 'Stabilité'],
    content: '## Tris\nContenu du tri rapide.',
    order: 0,
    estimatedMinutes: 20,
    status: 'VALIDATED',
  },
  {
    id: 's2',
    courseId: COURSE_ID,
    sectionKey: 'sec-2',
    title: 'Graphes',
    description: 'Parcours',
    keyTopics: ['BFS', 'DFS'],
    content: null,
    order: 1,
    estimatedMinutes: 15,
    status: 'PENDING',
  },
];

class FakeSectionRepository implements CourseSectionRepositoryPort {
  public rows = makeSections();
  public saves: Array<{ courseId: string; sectionKey: string; content: string; status?: string }> = [];

  async initFromOutline(): Promise<CourseSection[]> {
    return this.rows;
  }

  async listByCourse(): Promise<CourseSection[]> {
    return [...this.rows];
  }

  async findByKey(courseId: string, sectionKey: string): Promise<CourseSection | null> {
    return this.rows.find((row) => row.courseId === courseId && row.sectionKey === sectionKey) ?? null;
  }

  async saveContent(params: {
    courseId: string;
    sectionKey: string;
    content: string;
    status?: 'GENERATED' | 'VALIDATED';
  }): Promise<CourseSection> {
    this.saves.push(params);
    const row = this.rows.find((item) => item.sectionKey === params.sectionKey);
    if (!row) throw new Error('section missing');
    row.content = params.content;
    row.status = params.status ?? 'GENERATED';
    return row;
  }

  async updateStatus(_courseId: string, sectionKey: string, status: CourseSection['status']): Promise<CourseSection> {
    const row = this.rows.find((item) => item.sectionKey === sectionKey);
    if (!row) throw new Error('section missing');
    row.status = status;
    return row;
  }

  async countNotValidated(): Promise<number> {
    return this.rows.filter((row) => row.status !== 'VALIDATED').length;
  }
}

const makeCourseRepo = (course: CourseDetail | null): CourseRepositoryPort => ({
  save: async () => course as CourseDetail,
  update: async () => course as CourseDetail,
  listByAuthor: async () => [],
  listPublished: async () => [],
  findById: async () => course,
  updateStatus: async (_id, status) => ({ ...(course as CourseDetail), status }),
  remove: async () => undefined,
});

const candidate = (index: number): ImageSearchResult => ({
  title: `Image ${index}`,
  url: `https://example.com/image-${index}.png`,
  caption: `Illustration ${index}`,
  source: 'wikimedia',
  width: 640,
  height: 480,
});

const makeSearch = (images: ImageSearchResult[]): SearchPort & { searchImages: ReturnType<typeof vi.fn> } => ({
  searchWeb: async () => [],
  searchImages: vi.fn(async (_query: string, limit = 5) => images.slice(0, limit)),
});

const ACCESS = {
  requesterId: 'author-1',
  requesterRole: null,
  courseId: COURSE_ID,
};

describe('Unit: SearchSectionImagesUseCase', () => {
  it('builds a query from the section and course, and returns five candidates', async () => {
    const search = makeSearch(Array.from({ length: 8 }, (_, index) => candidate(index)));
    const useCase = new SearchSectionImagesUseCase(makeCourseRepo(makeCourse()), new FakeSectionRepository(), search);

    const result = await useCase.execute({ ...ACCESS, sectionKey: 'sec-1' });

    expect(result.query).toBe('Tris Informatique Quick sort Merge sort Complexité');
    expect(search.searchImages).toHaveBeenCalledWith(result.query, 5);
    expect(result.images).toHaveLength(5);
  });

  it('lets the teacher override the query', async () => {
    const search = makeSearch([candidate(1)]);
    const useCase = new SearchSectionImagesUseCase(makeCourseRepo(makeCourse()), new FakeSectionRepository(), search);

    const result = await useCase.execute({ ...ACCESS, sectionKey: 'sec-1', query: '  quicksort diagram  ' });

    expect(result.query).toBe('quicksort diagram');
    expect(search.searchImages).toHaveBeenCalledWith('quicksort diagram', 5);
  });

  it('enforces ownership and section existence', async () => {
    const useCase = new SearchSectionImagesUseCase(makeCourseRepo(makeCourse()), new FakeSectionRepository(), makeSearch([]));

    await expect(
      useCase.execute({ ...ACCESS, requesterId: 'intruder', sectionKey: 'sec-1' }),
    ).rejects.toMatchObject({ statusCode: 404 });
    await expect(
      useCase.execute({ ...ACCESS, sectionKey: 'missing' }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it('answers 404 for an unknown course', async () => {
    const useCase = new SearchSectionImagesUseCase(makeCourseRepo(null), new FakeSectionRepository(), makeSearch([]));

    await expect(useCase.execute({ ...ACCESS, sectionKey: 'sec-1' })).rejects.toMatchObject({
      statusCode: 404,
    });
  });
});

describe('Unit: ApplySectionImageUseCase', () => {
  it('appends the image and demotes a validated section to GENERATED', async () => {
    const sections = new FakeSectionRepository();
    const useCase = new ApplySectionImageUseCase(makeCourseRepo(makeCourse()), sections);

    const result = await useCase.execute({
      ...ACCESS,
      sectionKey: 'sec-1',
      imageUrl: 'https://example.com/sorting.png',
      caption: '  Tri [rapide]  ',
    });

    expect(result.section.content).toBe(
      '## Tris\nContenu du tri rapide.\n\n![Tri rapide](https://example.com/sorting.png)\n',
    );
    expect(result.section.status).toBe('GENERATED');
    expect(sections.saves).toHaveLength(1);
  });

  it('sanitizes the URL parentheses and falls back to the section title', async () => {
    const sections = new FakeSectionRepository();
    const useCase = new ApplySectionImageUseCase(makeCourseRepo(makeCourse()), sections);

    const result = await useCase.execute({
      ...ACCESS,
      sectionKey: 'sec-1',
      imageUrl: 'https://example.com/a(b).png',
    });

    expect(result.section.content).toContain('![Tris](https://example.com/a%28b%29.png)');
  });

  it('is idempotent for the same URL', async () => {
    const sections = new FakeSectionRepository();
    const useCase = new ApplySectionImageUseCase(makeCourseRepo(makeCourse()), sections);

    await useCase.execute({ ...ACCESS, sectionKey: 'sec-1', imageUrl: 'https://example.com/sorting.png' });
    const second = await useCase.execute({
      ...ACCESS,
      sectionKey: 'sec-1',
      imageUrl: 'https://example.com/sorting.png',
    });

    expect(second.section.content?.match(/sorting\.png/g)).toHaveLength(1);
    expect(sections.saves).toHaveLength(1);
  });

  it('rejects non-http URLs, empty sections and foreign courses', async () => {
    const useCase = new ApplySectionImageUseCase(makeCourseRepo(makeCourse()), new FakeSectionRepository());

    await expect(
      useCase.execute({ ...ACCESS, sectionKey: 'sec-1', imageUrl: 'javascript:alert(1)' }),
    ).rejects.toMatchObject({ statusCode: 400 });
    await expect(
      useCase.execute({ ...ACCESS, sectionKey: 'sec-2', imageUrl: 'https://example.com/a.png' }),
    ).rejects.toMatchObject({ statusCode: 400 });
    await expect(
      useCase.execute({
        ...ACCESS,
        requesterId: 'intruder',
        sectionKey: 'sec-1',
        imageUrl: 'https://example.com/a.png',
      }),
    ).rejects.toMatchObject({ statusCode: 404 });
  });

  it('lets an ADMIN edit another teacher course', async () => {
    const useCase = new ApplySectionImageUseCase(makeCourseRepo(makeCourse()), new FakeSectionRepository());

    const result = await useCase.execute({
      ...ACCESS,
      requesterId: 'admin-1',
      requesterRole: 'ADMIN',
      sectionKey: 'sec-1',
      imageUrl: 'https://example.com/a.png',
    });

    expect(result.section.content).toContain('https://example.com/a.png');
  });
});
