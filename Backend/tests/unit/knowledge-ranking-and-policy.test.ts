import { describe, expect, it } from 'vitest';
import {
  canManageDocument,
  canReadDocument,
  resolveRetrievalScope,
} from '../../src/modules/knowledge/domain/knowledge-policy.js';
import {
  fuseAndDiversifyRrfMmr,
  type FtsCandidate,
  type VectorCandidate,
} from '../../src/modules/knowledge/domain/hybrid-ranker.js';

describe('Unit: Knowledge Authorization Policy (Private Teacher vs Enrolled Student)', () => {
  it('scopes TEACHER strictly to own authorId (reading own DRAFT_AI & VERIFIED)', () => {
    const scope = resolveRetrievalScope({ id: 'teacher-1', role: 'TEACHER' }, ['class-1']);
    expect(scope.mode).toBe('AUTHOR_PRIVATE');
    expect(scope.authorId).toBe('teacher-1');

    expect(
      canReadDocument(
        { id: 'teacher-1', role: 'TEACHER' },
        { authorId: 'teacher-1', visibility: 'PRIVATE_AUTHOR', trustTier: 'DRAFT_AI', classGroupIds: [] },
        [],
      ),
    ).toBe(true);

    // Must NEVER read another teacher's private OR published document via private KB filter
    expect(
      canReadDocument(
        { id: 'teacher-1', role: 'TEACHER' },
        { authorId: 'teacher-2', visibility: 'CLASS_PUBLISHED', trustTier: 'VERIFIED', classGroupIds: ['class-1'] },
        ['class-1'],
      ),
    ).toBe(false);
  });

  it('restricts STUDENT strictly to VERIFIED + CLASS_PUBLISHED docs in enrolled classes', () => {
    const emptyScope = resolveRetrievalScope({ id: 'student-1', role: 'STUDENT' }, []);
    expect(emptyScope.mode).toBe('EMPTY');

    const studentScope = resolveRetrievalScope({ id: 'student-1', role: 'STUDENT' }, ['class-a', 'class-b'], {
      classGroupIds: ['class-b', 'class-c'],
    });
    expect(studentScope.mode).toBe('STUDENT_ENROLLED');
    expect(studentScope.enrolledClassGroupIds).toEqual(['class-b']);
    expect(studentScope.allowedVisibilities).toEqual(['CLASS_PUBLISHED']);
    expect(studentScope.allowedTrustTiers).toEqual(['VERIFIED']);

    expect(
      canReadDocument(
        { id: 'student-1', role: 'STUDENT' },
        { authorId: 't1', visibility: 'PRIVATE_AUTHOR', trustTier: 'VERIFIED', classGroupIds: ['class-a'] },
        ['class-a'],
      ),
    ).toBe(false);

    expect(
      canReadDocument(
        { id: 'student-1', role: 'STUDENT' },
        { authorId: 't1', visibility: 'CLASS_PUBLISHED', trustTier: 'DRAFT_AI', classGroupIds: ['class-a'] },
        ['class-a'],
      ),
    ).toBe(false);

    expect(
      canReadDocument(
        { id: 'student-1', role: 'STUDENT' },
        { authorId: 't1', visibility: 'CLASS_PUBLISHED', trustTier: 'VERIFIED', classGroupIds: ['class-other'] },
        ['class-a'],
      ),
    ).toBe(false);

    expect(
      canReadDocument(
        { id: 'student-1', role: 'STUDENT' },
        { authorId: 't1', visibility: 'CLASS_PUBLISHED', trustTier: 'VERIFIED', classGroupIds: ['class-a'] },
        ['class-a'],
      ),
    ).toBe(true);
  });

  it('allows ADMIN global access and restricts deletion/management properly', () => {
    const adminScope = resolveRetrievalScope({ id: 'admin-1', role: 'ADMIN' }, []);
    expect(adminScope.mode).toBe('ADMIN_ALL');
    expect(canManageDocument({ id: 'student-1', role: 'STUDENT' }, { authorId: 't1' })).toBe(false);
    expect(canManageDocument({ id: 'teacher-2', role: 'TEACHER' }, { authorId: 't1' })).toBe(false);
    expect(canManageDocument({ id: 't1', role: 'TEACHER' }, { authorId: 't1' })).toBe(true);
    expect(canManageDocument({ id: 'admin-1', role: 'ADMIN' }, { authorId: 't1' })).toBe(true);
  });
});

describe('Unit: Hybrid RRF + MMR Ranker', () => {
  const mkBase = (id: string, content: string, trustTier: 'DRAFT_AI' | 'VERIFIED' = 'VERIFIED') => ({
    chunkId: id,
    documentId: `doc-${id}`,
    sourceType: 'COURSE' as const,
    sourceId: `src-${id}`,
    title: `Doc ${id}`,
    subject: 'Data Science',
    visibility: 'CLASS_PUBLISHED' as const,
    trustTier,
    sectionTitle: `Section ${id}`,
    headingPath: `Section ${id}`,
    content,
    contextHeader: `[Doc ${id}]`,
    startSeconds: null,
    endSeconds: null,
    sourcePage: null,
    slideNumber: null,
    metadata: {},
  });

  it('combines dense vector and FTS ranks via RRF and diversifies near-duplicates via MMR', () => {
    const vec: VectorCandidate[] = [
      { ...mkBase('1', 'La régularisation L2 réduit le surapprentissage.'), vectorSimilarity: 0.91, embedding: [1, 0, 0] },
      { ...mkBase('2', 'La régularisation L2 réduit le surapprentissage.'), vectorSimilarity: 0.90, embedding: [0.999, 0.01, 0] },
      { ...mkBase('3', 'La validation croisée k-fold mesure la généralisation.'), vectorSimilarity: 0.85, embedding: [0, 1, 0] },
    ];
    const fts: FtsCandidate[] = [
      { ...mkBase('3', 'La validation croisée k-fold mesure la généralisation.'), ftsRank: 0.8 },
      { ...mkBase('1', 'La régularisation L2 réduit le surapprentissage.'), ftsRank: 0.6 },
    ];

    const hits = fuseAndDiversifyRrfMmr(vec, fts, { k: 2 });
    expect(hits).toHaveLength(2);
    // Diverse chunk 3 must beat duplicate chunk 2 despite chunk 2 having higher raw vector similarity
    const ids = hits.map((h) => h.chunkId);
    expect(ids).toContain('1');
    expect(ids).toContain('3');
    expect(ids).not.toContain('2');
  });

  it('works cleanly in FTS_ONLY mode using Jaccard diversity when embeddings are null', () => {
    const fts: FtsCandidate[] = [
      { ...mkBase('a', 'CRISP-DM étapes compréhension métier préparation données'), ftsRank: 0.9 },
      { ...mkBase('b', 'CRISP-DM étapes compréhension métier préparation données'), ftsRank: 0.88 },
      { ...mkBase('c', 'Imputation valeurs manquantes par médiane KNN'), ftsRank: 0.7 },
    ];

    const hits = fuseAndDiversifyRrfMmr([], fts, { k: 2, vectorWeight: 0, ftsWeight: 1 });
    expect(hits.map((h) => h.chunkId)).toEqual(['a', 'c']);
  });
});
