import type {
  KnowledgeActor,
  KnowledgeDocumentEntity,
  KnowledgeSearchFilters,
  KnowledgeTrustTier,
  KnowledgeVisibility,
} from './knowledge-document.entity.js';

export interface KnowledgeRetrievalScope {
  mode: 'AUTHOR_PRIVATE' | 'STUDENT_ENROLLED' | 'ADMIN_ALL' | 'EMPTY';
  authorId?: string;
  enrolledClassGroupIds: string[];
  allowedVisibilities: KnowledgeVisibility[];
  allowedTrustTiers: KnowledgeTrustTier[];
}

/**
 * Resolves the hard authorization boundary enforced at SQL retrieval time
 * BEFORE semantic or full-text ranking ever inspects chunk contents.
 *
 * - TEACHER: strictly private author KB (`authorId = actor.id`), seeing both own
 *   `DRAFT_AI` and `VERIFIED` documents. Never reads other teachers' docs in Phase 1.
 * - STUDENT: strictly `CLASS_PUBLISHED` AND `VERIFIED` content assigned to at least
 *   one class group in `enrolledClassGroupIds`. Never reads drafts or private docs.
 * - ADMIN: permitted to inspect across scopes (filters still apply if provided).
 */
export const resolveRetrievalScope = (
  actor: KnowledgeActor,
  enrolledClassGroupIds: string[],
  filters?: KnowledgeSearchFilters,
): KnowledgeRetrievalScope => {
  if (actor.role === 'ADMIN') {
    const requestedTiers = filters?.trustTiers?.length
      ? filters.trustTiers
      : (['DRAFT_AI', 'VERIFIED'] as KnowledgeTrustTier[]);
    return {
      mode: 'ADMIN_ALL',
      enrolledClassGroupIds: filters?.classGroupIds ?? [],
      allowedVisibilities: ['PRIVATE_AUTHOR', 'CLASS_PUBLISHED', 'INSTITUTION_SHARED'],
      allowedTrustTiers: requestedTiers,
    };
  }

  if (actor.role === 'TEACHER') {
    const requestedTiers = filters?.trustTiers?.length
      ? filters.trustTiers
      : (['DRAFT_AI', 'VERIFIED'] as KnowledgeTrustTier[]);
    return {
      mode: 'AUTHOR_PRIVATE',
      authorId: actor.id,
      enrolledClassGroupIds: filters?.classGroupIds ?? [],
      allowedVisibilities: ['PRIVATE_AUTHOR', 'CLASS_PUBLISHED', 'INSTITUTION_SHARED'],
      allowedTrustTiers: requestedTiers,
    };
  }

  // STUDENT strict security boundary
  const effectiveClasses =
    filters?.classGroupIds && filters.classGroupIds.length > 0
      ? enrolledClassGroupIds.filter((id) => filters.classGroupIds!.includes(id))
      : enrolledClassGroupIds;

  if (effectiveClasses.length === 0) {
    return {
      mode: 'EMPTY',
      enrolledClassGroupIds: [],
      allowedVisibilities: ['CLASS_PUBLISHED'],
      allowedTrustTiers: ['VERIFIED'],
    };
  }

  return {
    mode: 'STUDENT_ENROLLED',
    enrolledClassGroupIds: [...new Set(effectiveClasses)],
    allowedVisibilities: ['CLASS_PUBLISHED'],
    allowedTrustTiers: ['VERIFIED'],
  };
};

export const canReadDocument = (
  actor: KnowledgeActor,
  doc: Pick<KnowledgeDocumentEntity, 'authorId' | 'visibility' | 'trustTier' | 'classGroupIds'>,
  enrolledClassGroupIds: string[],
): boolean => {
  if (actor.role === 'ADMIN') return true;
  if (actor.role === 'TEACHER') {
    return doc.authorId === actor.id;
  }
  if (doc.visibility !== 'CLASS_PUBLISHED' || doc.trustTier !== 'VERIFIED') {
    return false;
  }
  return doc.classGroupIds.some((id) => enrolledClassGroupIds.includes(id));
};

export const canManageDocument = (
  actor: KnowledgeActor,
  doc: Pick<KnowledgeDocumentEntity, 'authorId'>,
): boolean => {
  if (actor.role === 'ADMIN') return true;
  if (actor.role === 'TEACHER') {
    return doc.authorId === actor.id;
  }
  return false;
};
