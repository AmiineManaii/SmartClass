import type {
  KnowledgeSearchHit,
  KnowledgeTrustTier,
  KnowledgeVisibility,
  KnowledgeSourceType,
} from './knowledge-document.entity.js';

export interface VectorCandidate {
  chunkId: string;
  documentId: string;
  sourceType: KnowledgeSourceType;
  sourceId: string;
  title: string;
  subject: string | null;
  visibility: KnowledgeVisibility;
  trustTier: KnowledgeTrustTier;
  sectionTitle: string | null;
  headingPath: string | null;
  content: string;
  contextHeader: string;
  startSeconds: number | null;
  endSeconds: number | null;
  sourcePage: number | null;
  slideNumber: number | null;
  metadata: Record<string, unknown>;
  vectorSimilarity: number;
  embedding?: number[] | null;
}

export interface FtsCandidate {
  chunkId: string;
  documentId: string;
  sourceType: KnowledgeSourceType;
  sourceId: string;
  title: string;
  subject: string | null;
  visibility: KnowledgeVisibility;
  trustTier: KnowledgeTrustTier;
  sectionTitle: string | null;
  headingPath: string | null;
  content: string;
  contextHeader: string;
  startSeconds: number | null;
  endSeconds: number | null;
  sourcePage: number | null;
  slideNumber: number | null;
  metadata: Record<string, unknown>;
  ftsRank: number;
  embedding?: number[] | null;
}

export interface RankerOptions {
  k: number;
  rrfK?: number;
  vectorWeight?: number;
  ftsWeight?: number;
  mmrLambda?: number;
}

const dotCosine = (a: number[], b: number[]): number => {
  let dot = 0;
  let na = 0;
  let nb = 0;
  const len = Math.min(a.length, b.length);
  for (let i = 0; i < len; i++) {
    const va = a[i] ?? 0;
    const vb = b[i] ?? 0;
    dot += va * vb;
    na += va * va;
    nb += vb * vb;
  }
  if (na === 0 || nb === 0) return 0;
  return dot / (Math.sqrt(na) * Math.sqrt(nb));
};

const tokenize = (text: string): Set<string> => {
  const normalized = text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
  const tokens = normalized.split(/[^\p{L}\p{N}]+/u).filter((t) => t.length >= 2);
  return new Set(tokens);
};

const jaccardSimilarity = (a: Set<string>, b: Set<string>): number => {
  if (a.size === 0 || b.size === 0) return 0;
  let intersection = 0;
  for (const item of a) {
    if (b.has(item)) intersection++;
  }
  const union = a.size + b.size - intersection;
  return union === 0 ? 0 : intersection / union;
};

/**
 * Performs Reciprocal Rank Fusion (0.65 vector / 0.35 FTS) followed by
 * Maximal Marginal Relevance (lambda = 0.78) to preserve top relevance while
 * preventing redundant near-duplicate chunks in the returned context window.
 */
export const fuseAndDiversifyRrfMmr = (
  vectorCandidates: VectorCandidate[],
  ftsCandidates: FtsCandidate[],
  options: RankerOptions,
): KnowledgeSearchHit[] => {
  const rrfK = options.rrfK ?? 60;
  const vectorWeight = options.vectorWeight ?? 0.65;
  const ftsWeight = options.ftsWeight ?? 0.35;
  const mmrLambda = options.mmrLambda ?? 0.78;
  const limit = Math.max(1, options.k);

  interface MergedCandidate {
    base: VectorCandidate | FtsCandidate;
    vectorScore: number | null;
    ftsScore: number | null;
    rrfScore: number;
    embedding: number[] | null;
    tokens: Set<string>;
  }

  const byId = new Map<string, MergedCandidate>();

  const sortedVec = [...vectorCandidates].sort((a, b) => b.vectorSimilarity - a.vectorSimilarity);
  sortedVec.forEach((cand, idx) => {
    const rank = idx + 1;
    const rrf = vectorWeight / (rrfK + rank);
    byId.set(cand.chunkId, {
      base: cand,
      vectorScore: Number(cand.vectorSimilarity.toFixed(4)),
      ftsScore: null,
      rrfScore: rrf,
      embedding: cand.embedding ?? null,
      tokens: tokenize(cand.content),
    });
  });

  const sortedFts = [...ftsCandidates].sort((a, b) => b.ftsRank - a.ftsRank);
  sortedFts.forEach((cand, idx) => {
    const rank = idx + 1;
    const rrf = ftsWeight / (rrfK + rank);
    const existing = byId.get(cand.chunkId);
    if (existing) {
      existing.ftsScore = Number(cand.ftsRank.toFixed(4));
      existing.rrfScore += rrf;
      if (!existing.embedding && cand.embedding) {
        existing.embedding = cand.embedding;
      }
    } else {
      byId.set(cand.chunkId, {
        base: cand,
        vectorScore: null,
        ftsScore: Number(cand.ftsRank.toFixed(4)),
        rrfScore: rrf,
        embedding: cand.embedding ?? null,
        tokens: tokenize(cand.content),
      });
    }
  });

  const pool = [...byId.values()];
  if (pool.length === 0) return [];

  // Small quality prior (+4%) for VERIFIED human-approved content over DRAFT_AI
  for (const item of pool) {
    if (item.base.trustTier === 'VERIFIED') {
      item.rrfScore *= 1.04;
    }
  }

  const maxRrf = Math.max(...pool.map((p) => p.rrfScore)) || 1;
  const selected: MergedCandidate[] = [];
  const remaining = new Set(pool);

  while (selected.length < limit && remaining.size > 0) {
    let bestItem: MergedCandidate | null = null;
    let bestMmrScore = Number.NEGATIVE_INFINITY;

    for (const candidate of remaining) {
      const normalizedRelevance = candidate.rrfScore / maxRrf;
      let maxRedundancy = 0;

      for (const picked of selected) {
        const sim =
          candidate.embedding && picked.embedding
            ? Math.max(0, dotCosine(candidate.embedding, picked.embedding))
            : jaccardSimilarity(candidate.tokens, picked.tokens);
        if (sim > maxRedundancy) {
          maxRedundancy = sim;
        }
      }

      const mmrScore = mmrLambda * normalizedRelevance - (1 - mmrLambda) * maxRedundancy;
      if (mmrScore > bestMmrScore) {
        bestMmrScore = mmrScore;
        bestItem = candidate;
      }
    }

    if (!bestItem) break;
    selected.push(bestItem);
    remaining.delete(bestItem);
  }

  return selected.map((item) => ({
    chunkId: item.base.chunkId,
    documentId: item.base.documentId,
    sourceType: item.base.sourceType,
    sourceId: item.base.sourceId,
    title: item.base.title,
    subject: item.base.subject,
    visibility: item.base.visibility,
    trustTier: item.base.trustTier,
    sectionTitle: item.base.sectionTitle,
    headingPath: item.base.headingPath,
    content: item.base.content,
    contextHeader: item.base.contextHeader,
    startSeconds: item.base.startSeconds,
    endSeconds: item.base.endSeconds,
    sourcePage: item.base.sourcePage,
    slideNumber: item.base.slideNumber,
    score: Number((item.rrfScore / maxRrf).toFixed(4)),
    vectorScore: item.vectorScore,
    ftsScore: item.ftsScore,
    metadata: item.base.metadata,
  }));
};
