import { logger } from '../../../shared/infrastructure/logger.js';
import type { Role } from '../../auth/index.js';
import type {
  KnowledgeRetrievalPort,
  KnowledgeSearchHit,
  KnowledgeSourceType,
  KnowledgeTrustTier,
} from '../../knowledge/index.js';
import type {
  KnowledgeGroundingOptions,
  KnowledgeGroundingOutcome,
  KnowledgeSourceAttribution,
} from '../domain/knowledge-grounding.types.js';

/**
 * Minimum cosine similarity calibrated from the local EmbeddingGemma CPU benchmark:
 * positive top cosines were >= 0.7349, while unrelated/off-topic cosines stayed <= 0.6088.
 */
export const CALIBRATED_MIN_VECTOR_SCORE = 0.65;

export const DEFAULT_GROUNDING_MAX_CHUNKS = 5;

const MAX_EXCERPT_CHARS_PER_CHUNK = 1100;
const MAX_SNIPPET_CHARS = 220;

const SOURCE_TYPE_LABELS: Record<KnowledgeSourceType, string> = {
  COURSE: 'Cours',
  COURSE_SECTION: 'Section',
  LECTURE_TRANSCRIPT: 'Transcription vidéo',
  LECTURE_SLIDE: 'Diapositive',
  LECTURE_PACKAGE: 'Synthèse de séance',
  RECORDING_SOURCE_DOC: 'Document source',
  UPLOADED_DOCUMENT: 'Document importé',
};

const formatTimestamp = (seconds: number | null): string | null => {
  if (seconds === null || !Number.isFinite(seconds) || seconds < 0) return null;
  const total = Math.floor(seconds);
  const mins = Math.floor(total / 60)
    .toString()
    .padStart(2, '0');
  const secs = (total % 60).toString().padStart(2, '0');
  return `${mins}:${secs}`;
};

const toSnippet = (rawContent: string): string => {
  const singleLine = rawContent.replace(/\s+/g, ' ').trim();
  if (singleLine.length <= MAX_SNIPPET_CHARS) return singleLine;
  return `${singleLine.slice(0, MAX_SNIPPET_CHARS - 1).trimEnd()}…`;
};

const formatHitBlock = (hit: KnowledgeSearchHit, index: number): string => {
  const typeLabel = SOURCE_TYPE_LABELS[hit.sourceType] ?? hit.sourceType;
  const trustLabel = hit.trustTier === 'VERIFIED' ? 'Vérifié' : 'Brouillon IA';
  const tags: string[] = [typeLabel, trustLabel];
  if (hit.sectionTitle && hit.sectionTitle.trim().length > 0) {
    tags.push(hit.sectionTitle.trim());
  }
  const timestamp = formatTimestamp(hit.startSeconds);
  if (timestamp) {
    tags.push(`[${timestamp}]`);
  }
  if (hit.slideNumber !== null) {
    tags.push(`Slide #${hit.slideNumber}`);
  }
  if (hit.sourcePage !== null) {
    tags.push(`p. ${hit.sourcePage}`);
  }

  const trimmedBody = hit.content.trim();
  const excerpt =
    trimmedBody.length > MAX_EXCERPT_CHARS_PER_CHUNK
      ? `${trimmedBody.slice(0, MAX_EXCERPT_CHARS_PER_CHUNK).trimEnd()}…`
      : trimmedBody;

  return `[KB-${index + 1}] (${tags.join(' | ')}) ${hit.title}\n${excerpt}`;
};

const toAttribution = (hit: KnowledgeSearchHit): KnowledgeSourceAttribution => ({
  documentId: hit.documentId,
  chunkId: hit.chunkId,
  sourceType: hit.sourceType,
  sourceId: hit.sourceId,
  title: hit.title,
  sectionTitle: hit.sectionTitle,
  trustTier: hit.trustTier,
  score: hit.score,
  vectorScore: hit.vectorScore,
  ftsScore: hit.ftsScore,
  startSeconds: hit.startSeconds,
  sourcePage: hit.sourcePage,
  slideNumber: hit.slideNumber,
  snippet: toSnippet(hit.content),
});

export interface ResolveCourseGroundingParams {
  requesterId?: string;
  requesterRole?: Role | null;
  query: string;
  options?: KnowledgeGroundingOptions;
  maxChars: number;
  excludeSourceIds?: string[];
}

/**
 * Resolves private teacher knowledge base context for course creator prompts.
 * Default policy: only VERIFIED documents unless `includeDrafts: true` is opted in.
 * Strict SQL isolation is enforced inside KnowledgeRetrievalPort before ranking.
 */
export class CourseKnowledgeGroundingService {
  constructor(private readonly knowledgeRetrieval?: KnowledgeRetrievalPort) {}

  public async resolve(params: ResolveCourseGroundingParams): Promise<KnowledgeGroundingOutcome> {
    if (!this.knowledgeRetrieval || !params.requesterId || params.options?.enabled === false) {
      return {
        promptContext: '',
        sources: [],
        searchMode: 'DISABLED',
        degradedReason: null,
      };
    }

    const query = params.query.trim().slice(0, 1200);
    if (query.length < 2) {
      return {
        promptContext: '',
        sources: [],
        searchMode: 'DISABLED',
        degradedReason: null,
      };
    }

    const includeDrafts = params.options?.includeDrafts === true;
    const trustTiers: KnowledgeTrustTier[] = includeDrafts ? ['VERIFIED', 'DRAFT_AI'] : ['VERIFIED'];
    const maxChunks = Math.max(
      1,
      Math.min(10, params.options?.maxChunks ?? DEFAULT_GROUNDING_MAX_CHUNKS),
    );
    const pinnedDocuments = Boolean(
      params.options?.documentIds && params.options.documentIds.length > 0,
    );
    const excluded = new Set(params.excludeSourceIds ?? []);

    try {
      const searchResult = await this.knowledgeRetrieval.search({
        actor: {
          id: params.requesterId,
          role: params.requesterRole ?? 'TEACHER',
        },
        query,
        k: Math.min(20, maxChunks + excluded.size + 3),
        filters: {
          sourceTypes: params.options?.sourceTypes,
          documentIds: params.options?.documentIds,
          trustTiers,
        },
      });

      const filteredHits = searchResult.hits
        .filter((hit) => !excluded.has(hit.sourceId))
        .filter((hit) => {
          if (pinnedDocuments) return true;
          if (hit.vectorScore !== null) {
            return hit.vectorScore >= CALIBRATED_MIN_VECTOR_SCORE;
          }
          return (hit.ftsScore ?? 0) > 0;
        })
        .slice(0, maxChunks);

      const sources: KnowledgeSourceAttribution[] = [];
      const blocks: string[] = [];
      let totalChars = 0;

      for (const hit of filteredHits) {
        const block = formatHitBlock(hit, blocks.length);
        const separatorLen = blocks.length > 0 ? 2 : 0;
        if (totalChars + separatorLen + block.length > params.maxChars) {
          if (blocks.length === 0 && params.maxChars > 180) {
            // Preserve partial first hit rather than dropping all context on a tight budget.
            const truncatedBlock = `${block.slice(0, params.maxChars - 1).trimEnd()}…`;
            blocks.push(truncatedBlock);
            sources.push(toAttribution(hit));
          }
          break;
        }
        blocks.push(block);
        totalChars += separatorLen + block.length;
        sources.push(toAttribution(hit));
      }

      return {
        promptContext: blocks.join('\n\n'),
        sources,
        searchMode: searchResult.searchMode,
        degradedReason: searchResult.degradedReason,
      };
    } catch (error) {
      logger.warn({ err: error }, 'Course knowledge grounding degraded: retrieval failed');
      return {
        promptContext: '',
        sources: [],
        searchMode: 'FTS_ONLY',
        degradedReason: 'Knowledge base retrieval temporarily unavailable',
      };
    }
  }
}
