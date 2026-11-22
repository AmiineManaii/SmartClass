import { logger } from '../../../shared/infrastructure/logger.js';
import type { Role } from '../../auth/index.js';
import type {
  KnowledgeRetrievalPort,
  KnowledgeSearchHit,
  KnowledgeSearchMode,
  KnowledgeSourceType,
  KnowledgeTrustTier,
} from '../../knowledge/index.js';
import type {
  ExamCoverageReport,
  ExamKnowledgeBlueprint,
  ExamKnowledgeSearchMode,
  ExamKnowledgeSourceAttribution,
  ExamSourceCoverageEntry,
} from '../domain/exam-knowledge.types.js';

const MAX_SNIPPET_CHARS = 220;

const PRACTICE_QUIZ_HEADING_PATTERN =
  /^(correction\s+du\s+quiz|corrige(s)?(\s+du\s+quiz)?|quiz(\s+rapide|\s+d['’]?auto-?evaluation)?|auto-?evaluation|reponses?\s+du\s+quiz|answer\s+key|quiz\s+answers?|solutions?\s+du\s+quiz)\b/i;

const SOURCE_TYPE_LABELS: Record<KnowledgeSourceType, string> = {
  COURSE: 'Cours',
  COURSE_SECTION: 'Chapitre',
  LECTURE_TRANSCRIPT: 'Transcription vidéo',
  LECTURE_SLIDE: 'Diapositive',
  LECTURE_PACKAGE: 'Synthèse de séance',
  RECORDING_SOURCE_DOC: 'Document source',
  UPLOADED_DOCUMENT: 'Document importé',
};

export interface ParsedCourseChapter {
  title: string;
  content: string;
}

export interface BuildExamBlueprintParams {
  requesterId: string;
  requesterRole: Role | null;
  title: string;
  courses: Array<{ id: string; title: string; subject: string | null; content: string }>;
  chapters?: string[];
  focusTopics?: string[];
  knowledgeDocumentIds?: string[];
  includeDrafts?: boolean;
  questionCount: number;
  maxSourceChars: number;
  balancedCoverage?: boolean;
}

interface BlueprintSegment {
  id: string;
  sectionTitle: string;
  text: string;
  originalChars: number;
  startSeconds: number | null;
  slideNumber: number | null;
  trustTier: KnowledgeTrustTier;
  documentId: string | null;
  retrievalOrigin: 'KNOWLEDGE_ENGINE' | 'COURSE_STRUCTURE';
}

interface BlueprintSourceUnit {
  key: string;
  sourceId: string;
  documentId: string | null;
  sourceType: KnowledgeSourceType;
  title: string;
  subject: string | null;
  segments: BlueprintSegment[];
  weight: number;
}

/**
 * Normalizes strings for accent- and case-insensitive matching across
 * teacher-provided chapter filters and retrieved headings.
 */
export const normalizeMatchKey = (value: string): string =>
  value
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, ' ');

/**
 * Identifies self-check quiz or answer-key headings inside courses so they can
 * be stripped before generating an official exam.
 */
export const isPracticeQuizOrAnswerKeyHeading = (heading: string): boolean => {
  const normalized = normalizeMatchKey(heading).replace(/^[:\-\s]+/, '');
  if (!normalized) return false;
  return PRACTICE_QUIZ_HEADING_PATTERN.test(normalized);
};

interface RawMarkdownSection {
  title: string;
  content: string;
  hasHeading: boolean;
}

const splitMarkdownByTopHeadings = (markdown: string): RawMarkdownSection[] => {
  const normalized = markdown.replace(/\r\n/g, '\n');
  const lines = normalized.split('\n');
  const rawSections: RawMarkdownSection[] = [];
  let currentTitle = 'Introduction';
  let currentHasHeading = false;
  let buffer: string[] = [];
  let inFence = false;

  const flush = (): void => {
    const body = buffer.join('\n').trim();
    if (body.length > 0 || currentHasHeading) {
      rawSections.push({
        title: currentTitle,
        content: body,
        hasHeading: currentHasHeading,
      });
    }
    buffer = [];
  };

  for (const line of lines) {
    const trimmedLine = line.trimStart();
    if (trimmedLine.startsWith('```')) {
      inFence = !inFence;
      buffer.push(line);
      continue;
    }

    if (!inFence) {
      const headingMatch = line.match(/^#{1,2}\s+(.+?)\s*#*$/);
      if (headingMatch?.[1]) {
        flush();
        currentTitle = headingMatch[1].trim();
        currentHasHeading = true;
        continue;
      }
    }
    buffer.push(line);
  }
  flush();

  // Merge non-heading preambles or short wrapper headers into the next heading
  // when real content chapters follow, preventing empty wrapper sections.
  const merged: RawMarkdownSection[] = [];
  let pendingIntro: RawMarkdownSection | null = null;

  for (const section of rawSections) {
    if (!section.hasHeading && rawSections.some((s) => s.hasHeading)) {
      if (section.content.length >= 80) {
        merged.push(section);
      } else if (section.content.length > 0) {
        pendingIntro = section;
      }
      continue;
    }

    if (section.hasHeading && section.content.length === 0) {
      continue;
    }

    if (pendingIntro) {
      merged.push({
        ...section,
        content: `${pendingIntro.content}\n\n${section.content}`.trim(),
      });
      pendingIntro = null;
    } else {
      merged.push(section);
    }
  }

  if (pendingIntro) {
    merged.push(pendingIntro);
  }

  return merged;
};

/**
 * Splits a Markdown course into teaching chapters while removing self-check
 * practice quizzes and answer keys whenever substantive chapters exist.
 */
export const parseCourseChaptersForExam = (markdown: string): ParsedCourseChapter[] => {
  const trimmed = markdown.trim();
  if (!trimmed) return [];

  const sections = splitMarkdownByTopHeadings(trimmed);
  const withContent = sections.filter((section) => section.content.trim().length > 0);
  if (withContent.length === 0) {
    return [{ title: 'Contenu principal', content: trimmed }];
  }

  const withoutQuizKeys = withContent.filter(
    (section) => !isPracticeQuizOrAnswerKeyHeading(section.title),
  );

  const chosen = withoutQuizKeys.length > 0 ? withoutQuizKeys : withContent;
  return chosen.map((section) => ({
    title: section.hasHeading ? section.title : 'Contenu principal',
    content: section.content.trim(),
  }));
};

/**
 * Extracts explicit Markdown `#` / `##` teaching chapter titles from a course.
 * Returns `[]` when a course uses plain prose without Markdown headings.
 */
export const extractCourseChapterTitles = (markdown: string): string[] => {
  const trimmed = markdown.trim();
  if (!trimmed) return [];

  const sections = splitMarkdownByTopHeadings(trimmed);
  const seen = new Set<string>();
  const titles: string[] = [];

  for (const section of sections) {
    if (!section.hasHeading) continue;
    if (section.content.trim().length === 0) continue;
    if (isPracticeQuizOrAnswerKeyHeading(section.title)) continue;
    const key = normalizeMatchKey(section.title);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    titles.push(section.title.trim());
  }

  return titles;
};

/**
 * Max-min fair water-filling character allocator: shorter sources receive
 * their full length first and their unused budget flows evenly to longer
 * sources, preventing the first long course from starving subsequent courses.
 */
export const allocateWaterFillingBudgets = (
  items: Array<{ id: string; rawChars: number }>,
  totalBudget: number,
): Map<string, number> => {
  const result = new Map<string, number>();
  if (items.length === 0) return result;

  const budget = Math.max(0, Math.floor(totalBudget));
  if (budget === 0) {
    for (const item of items) result.set(item.id, 0);
    return result;
  }

  const sanitized = items.map((item, index) => ({
    id: item.id,
    index,
    rawChars: Math.max(0, Math.floor(item.rawChars)),
  }));

  const sorted = [...sanitized].sort((a, b) =>
    a.rawChars === b.rawChars ? a.index - b.index : a.rawChars - b.rawChars,
  );

  let remainingBudget = budget;
  let remainingCount = sorted.length;
  let cutIndex = 0;

  while (cutIndex < sorted.length) {
    const entry = sorted[cutIndex]!;
    const fairShare = Math.floor(remainingBudget / remainingCount);
    if (entry.rawChars <= fairShare) {
      result.set(entry.id, entry.rawChars);
      remainingBudget -= entry.rawChars;
      remainingCount -= 1;
      cutIndex += 1;
    } else {
      break;
    }
  }

  if (cutIndex < sorted.length && remainingCount > 0) {
    const base = Math.floor(remainingBudget / remainingCount);
    const extra = remainingBudget % remainingCount;
    const remainingIds = new Set(sorted.slice(cutIndex).map((entry) => entry.id));
    let extraUsed = 0;
    for (const item of sanitized) {
      if (!remainingIds.has(item.id)) continue;
      const bonus = extraUsed < extra ? 1 : 0;
      extraUsed += 1;
      result.set(item.id, Math.min(item.rawChars, base + bonus));
    }
  }

  return result;
};

/**
 * Distributes `questionCount` fairly across sources so every source receives
 * at least 1 question whenever `questionCount >= sourceCount`.
 */
export const distributeQuestionQuotas = (
  sourceCount: number,
  questionCount: number,
  weights?: number[],
): number[] => {
  if (sourceCount <= 0) return [];
  if (questionCount <= 0) return Array<number>(sourceCount).fill(0);

  const cleanWeights = Array.from({ length: sourceCount }, (_, i) => {
    const candidate = weights?.[i];
    return typeof candidate === 'number' && Number.isFinite(candidate) && candidate > 0
      ? candidate
      : 1;
  });

  if (questionCount < sourceCount) {
    const quotas = Array<number>(sourceCount).fill(0);
    const ordered = cleanWeights
      .map((weight, index) => ({ index, weight }))
      .sort((a, b) => (b.weight === a.weight ? a.index - b.index : b.weight - a.weight));
    for (let i = 0; i < questionCount; i += 1) {
      quotas[ordered[i]!.index] = 1;
    }
    return quotas;
  }

  const quotas = Array<number>(sourceCount).fill(1);
  const remaining = questionCount - sourceCount;
  if (remaining === 0) return quotas;

  const weightSum = cleanWeights.reduce((acc, value) => acc + value, 0);
  const remainders: Array<{ index: number; fraction: number }> = [];
  let assignedExtras = 0;

  for (let i = 0; i < sourceCount; i += 1) {
    const exact = (remaining * cleanWeights[i]!) / weightSum;
    const whole = Math.floor(exact);
    quotas[i]! += whole;
    assignedExtras += whole;
    remainders.push({ index: i, fraction: exact - whole });
  }

  const leftover = remaining - assignedExtras;
  remainders.sort((a, b) =>
    b.fraction === a.fraction ? a.index - b.index : b.fraction - a.fraction,
  );
  for (let i = 0; i < leftover; i += 1) {
    quotas[remainders[i]!.index]! += 1;
  }

  return quotas;
};

export const trimAtCleanBoundary = (
  rawText: string,
  maxChars: number,
): { text: string; trimmed: boolean } => {
  const cleaned = rawText.replace(/\n{3,}/g, '\n\n').trim();
  if (maxChars <= 0) {
    return { text: '', trimmed: cleaned.length > 0 };
  }
  if (cleaned.length <= maxChars) {
    return { text: cleaned, trimmed: false };
  }
  if (maxChars <= 4) {
    return { text: cleaned.slice(0, maxChars), trimmed: true };
  }

  const sliceLimit = maxChars - 1;
  const candidate = cleaned.slice(0, sliceLimit);
  const minBoundary = Math.floor(sliceLimit * 0.6);
  const sentenceBreaks = [
    candidate.lastIndexOf('\n'),
    candidate.lastIndexOf('. '),
    candidate.lastIndexOf('! '),
    candidate.lastIndexOf('? '),
  ].filter((pos) => pos >= minBoundary);

  let cut = sentenceBreaks.length > 0 ? Math.max(...sentenceBreaks) + 1 : -1;
  if (cut < minBoundary) {
    const lastSpace = candidate.lastIndexOf(' ');
    if (lastSpace >= minBoundary) {
      cut = lastSpace;
    }
  }
  const finalSlice = (cut >= minBoundary ? candidate.slice(0, cut) : candidate).trimEnd();
  return { text: `${finalSlice}…`, trimmed: true };
};

const toSnippet = (rawContent: string): string => {
  const singleLine = rawContent.replace(/\s+/g, ' ').trim();
  if (singleLine.length <= MAX_SNIPPET_CHARS) return singleLine;
  return `${singleLine.slice(0, MAX_SNIPPET_CHARS - 1).trimEnd()}…`;
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

const matchesChapterFilter = (candidateTitle: string | null, keys: Set<string>): boolean => {
  if (keys.size === 0) return true;
  if (!candidateTitle) return false;
  const normalized = normalizeMatchKey(candidateTitle);
  if (!normalized) return false;
  if (keys.has(normalized)) return true;
  for (const key of keys) {
    if (normalized.includes(key) || key.includes(normalized)) {
      return true;
    }
  }
  return false;
};

/**
 * Builds a balanced, non-starving exam context blueprint across selected courses,
 * chapters, and teacher-owned Knowledge Engine documents (e.g. verified video
 * lectures), strips practice quiz answer keys, and emits coverage telemetry.
 */
export class ExamKnowledgeBlueprintService {
  constructor(private readonly knowledgeRetrieval?: KnowledgeRetrievalPort) {}

  public async build(params: BuildExamBlueprintParams): Promise<ExamKnowledgeBlueprint> {
    const includeDrafts = params.includeDrafts === true;
    const trustTiers: KnowledgeTrustTier[] = includeDrafts ? ['VERIFIED', 'DRAFT_AI'] : ['VERIFIED'];
    const requestedChapterKeys = new Set(
      (params.chapters ?? []).map(normalizeMatchKey).filter(Boolean),
    );
    const focusList = (params.focusTopics ?? []).map((t) => t.trim()).filter(Boolean);
    const warnings: string[] = [];

    let sawHybrid = false;
    let sawFts = false;
    let sawVectorOnly = false;
    let degradedReason: string | null = null;

    const recordMode = (mode: KnowledgeSearchMode, reason: string | null): void => {
      if (mode === 'FTS_ONLY') {
        sawFts = true;
        if (!degradedReason && reason) degradedReason = reason;
      } else if (mode === 'HYBRID') {
        sawHybrid = true;
      } else if (mode === 'VECTOR_ONLY') {
        sawVectorOnly = true;
      }
    };

    const sourceUnits: BlueprintSourceUnit[] = [];
    let totalChapters = 0;

    // 1. Courses: parse into chapters, apply chapter filter, optionally enrich with RAG,
    //    and supplement every chapter from parsed content so no chapter is ever dropped.
    for (const course of params.courses) {
      const parsedChapters = parseCourseChaptersForExam(course.content);
      totalChapters += parsedChapters.length;

      let selectedChapters =
        requestedChapterKeys.size > 0
          ? parsedChapters.filter((ch) => matchesChapterFilter(ch.title, requestedChapterKeys))
          : parsedChapters;

      if (requestedChapterKeys.size > 0 && selectedChapters.length === 0 && parsedChapters.length > 0) {
        warnings.push(
          `Aucun chapitre correspondant au filtre n’a été trouvé dans « ${course.title} ».`,
        );
        // If only 1 course and no pinned docs, fall back rather than returning empty;
        // if multiple courses exist, skip non-matching course cleanly.
        if (params.courses.length === 1 && (params.knowledgeDocumentIds?.length ?? 0) === 0) {
          selectedChapters = parsedChapters;
        } else {
          continue;
        }
      }

      let courseRagHits: KnowledgeSearchHit[] = [];

      if (this.knowledgeRetrieval) {
        const courseQuery = [
          course.title,
          ...selectedChapters.map((c) => c.title),
          ...focusList,
        ]
          .join(' ')
          .trim()
          .slice(0, 1000);

        try {
          const ragResult = await this.knowledgeRetrieval.search({
            actor: {
              id: params.requesterId,
              role: params.requesterRole ?? 'TEACHER',
            },
            query: courseQuery || course.title,
            k: Math.min(12, Math.max(4, selectedChapters.length * 2)),
            filters: {
              sourceIds: [course.id],
              sourceTypes: ['COURSE', 'COURSE_SECTION'],
              trustTiers,
            },
          });
          recordMode(ragResult.searchMode, ragResult.degradedReason);
          courseRagHits = ragResult.hits.filter(
            (hit) =>
              !isPracticeQuizOrAnswerKeyHeading(hit.sectionTitle ?? '') &&
              matchesChapterFilter(hit.sectionTitle ?? hit.headingPath, requestedChapterKeys),
          );
        } catch (error) {
          logger.warn({ err: error, courseId: course.id }, 'Exam RAG lookup degraded for course');
          sawFts = true;
          degradedReason ??= 'Knowledge base retrieval temporarily unavailable';
        }
      }

      const hitsByChapterKey = new Map<string, KnowledgeSearchHit[]>();
      for (const hit of courseRagHits) {
        const key = normalizeMatchKey(hit.sectionTitle ?? hit.headingPath ?? '');
        if (!key) continue;
        const list = hitsByChapterKey.get(key) ?? [];
        list.push(hit);
        hitsByChapterKey.set(key, list);
      }

      const segments: BlueprintSegment[] = [];
      for (let i = 0; i < selectedChapters.length; i += 1) {
        const chapter = selectedChapters[i]!;
        const fullChapterChars = chapter.content.replace(/\s+/g, ' ').trim().length;
        const chapterKey = normalizeMatchKey(chapter.title);
        const matchingHits = hitsByChapterKey.get(chapterKey);

        if (matchingHits && matchingHits.length > 0) {
          const combined = matchingHits.map((h) => h.content.trim()).join('\n\n');
          const primary = matchingHits[0]!;
          // Combine RAG hit ranking with full chapter content when no focus filter
          // narrows the chapter, and preserve full original character count so
          // subsampling a huge chapter is never hidden from coverage telemetry.
          const chosenText =
            chapter.content.length > combined.length && !focusList.length
              ? chapter.content
              : combined;
          const chosenCleanChars = chosenText.replace(/\s+/g, ' ').trim().length;
          segments.push({
            id: `${course.id}::ch::${i}`,
            sectionTitle: chapter.title,
            text: chosenText,
            originalChars: Math.max(chosenCleanChars, fullChapterChars),
            startSeconds: primary.startSeconds,
            slideNumber: primary.slideNumber,
            trustTier: primary.trustTier,
            documentId: primary.documentId,
            retrievalOrigin: 'KNOWLEDGE_ENGINE',
          });
        } else {
          segments.push({
            id: `${course.id}::ch::${i}`,
            sectionTitle: chapter.title,
            text: chapter.content,
            originalChars: fullChapterChars,
            startSeconds: null,
            slideNumber: null,
            trustTier: 'VERIFIED',
            documentId: null,
            retrievalOrigin: 'COURSE_STRUCTURE',
          });
        }
      }

      // If Markdown yielded 0 chapters (empty course), skip.
      if (segments.length > 0) {
        sourceUnits.push({
          key: `course:${course.id}`,
          sourceId: course.id,
          documentId: courseRagHits[0]?.documentId ?? null,
          sourceType: 'COURSE',
          title: course.title,
          subject: course.subject,
          segments,
          weight: Math.max(1, selectedChapters.length),
        });
      }
    }

    // 2. Explicitly pinned Knowledge Engine documents (e.g. verified recorded lectures).
    const requestedDocIds = Array.from(new Set(params.knowledgeDocumentIds ?? []));
    if (requestedDocIds.length > 0) {
      if (!this.knowledgeRetrieval) {
        warnings.push(
          'Le moteur de connaissances n’est pas disponible pour charger les ressources complémentaires sélectionnées.',
        );
      } else {
        const pinnedQuery = [
          ...focusList,
          ...(params.chapters ?? []),
          params.title,
          ...params.courses.map((c) => c.title),
        ]
          .join(' ')
          .trim()
          .slice(0, 1000);

        for (const docId of requestedDocIds) {
          try {
            const ragResult = await this.knowledgeRetrieval.search({
              actor: {
                id: params.requesterId,
                role: params.requesterRole ?? 'TEACHER',
              },
              query: pinnedQuery.length >= 2 ? pinnedQuery : 'notions cles definitions synthese',
              k: 8,
              filters: {
                documentIds: [docId],
                trustTiers,
              },
            });
            recordMode(ragResult.searchMode, ragResult.degradedReason);

            const cleanHits = ragResult.hits.filter(
              (hit) => !isPracticeQuizOrAnswerKeyHeading(hit.sectionTitle ?? ''),
            );
            if (cleanHits.length === 0) {
              warnings.push(
                `La ressource sélectionnée (${docId.slice(0, 8)}…) n’a retourné aucun extrait autorisé ou validé.`,
              );
              continue;
            }

            const sortedHits = [...cleanHits].sort((a, b) => {
              const timeDiff = (a.startSeconds ?? Number.MAX_SAFE_INTEGER) - (b.startSeconds ?? Number.MAX_SAFE_INTEGER);
              if (timeDiff !== 0) return timeDiff;
              const slideDiff = (a.slideNumber ?? Number.MAX_SAFE_INTEGER) - (b.slideNumber ?? Number.MAX_SAFE_INTEGER);
              if (slideDiff !== 0) return slideDiff;
              return b.score - a.score;
            });

            const segments: BlueprintSegment[] = sortedHits.map((hit, idx) => {
              const trimmedText = hit.content.trim();
              return {
                id: `${docId}::hit::${idx}`,
                sectionTitle: hit.sectionTitle ?? hit.headingPath ?? 'Extrait',
                text: trimmedText,
                originalChars: trimmedText.replace(/\s+/g, ' ').length,
                startSeconds: hit.startSeconds,
                slideNumber: hit.slideNumber,
                trustTier: hit.trustTier,
                documentId: hit.documentId,
                retrievalOrigin: 'KNOWLEDGE_ENGINE',
              };
            });

            totalChapters += segments.length;
            const firstHit = sortedHits[0]!;
            sourceUnits.push({
              key: `doc:${docId}`,
              sourceId: firstHit.sourceId,
              documentId: firstHit.documentId,
              sourceType: firstHit.sourceType,
              title: firstHit.title,
              subject: firstHit.subject,
              segments,
              weight: segments.length,
            });
          } catch (error) {
            logger.warn({ err: error, documentId: docId }, 'Exam RAG pinned document lookup failed');
            sawFts = true;
            degradedReason ??= 'Knowledge base retrieval temporarily unavailable';
            warnings.push(
              `Échec temporaire de récupération pour la ressource (${docId.slice(0, 8)}…).`,
            );
          }
        }
      }
    }

    const searchMode: ExamKnowledgeSearchMode = sawFts
      ? 'FTS_ONLY'
      : sawHybrid
        ? 'HYBRID'
        : sawVectorOnly
          ? 'VECTOR_ONLY'
          : 'DIRECT_BALANCED';

    if (sourceUnits.length === 0) {
      return {
        promptContext: '',
        distributionPlan: '',
        knowledgeSources: [],
        coverage: {
          totalSources: params.courses.length + requestedDocIds.length,
          coveredSources: 0,
          totalChapters,
          coveredChapters: 0,
          truncated: false,
          warnings,
          distribution: [],
        },
        searchMode,
        degradedReason,
      };
    }

    // 3. Allocate question quotas and water-filling character budgets across sources
    const weights =
      params.balancedCoverage === false
        ? sourceUnits.map((unit) => unit.weight)
        : sourceUnits.map(() => 1);
    const questionQuotas = distributeQuestionQuotas(
      sourceUnits.length,
      params.questionCount,
      weights,
    );

    const totalBudget = Math.max(2000, params.maxSourceChars);
    const sourceRawItems = sourceUnits.map((unit) => ({
      id: unit.key,
      rawChars: unit.segments.reduce((sum, seg) => sum + seg.text.length, 0),
    }));
    const sourceBudgets = allocateWaterFillingBudgets(sourceRawItems, totalBudget);

    const distribution: ExamSourceCoverageEntry[] = [];
    const attributionList: ExamKnowledgeSourceAttribution[] = [];
    const planLines: string[] = [];
    const promptBlocks: string[] = [];

    let coveredChapters = 0;
    let anyTruncated = false;

    for (let sIdx = 0; sIdx < sourceUnits.length; sIdx += 1) {
      const unit = sourceUnits[sIdx]!;
      const quota = questionQuotas[sIdx] ?? 1;
      const sourceBudget = Math.max(1, sourceBudgets.get(unit.key) ?? 0);

      const segmentBudgets = allocateWaterFillingBudgets(
        unit.segments.map((seg) => ({ id: seg.id, rawChars: seg.text.length })),
        sourceBudget,
      );

      let unitOriginalChars = 0;
      let unitIncludedChars = 0;
      let unitTrimmed = false;
      const includedChapterNames: string[] = [];
      const formattedSegments: string[] = [];

      for (const seg of unit.segments) {
        const cleanRaw = seg.text.replace(/\s+/g, ' ').trim();
        const baselineChars = Math.max(cleanRaw.length, seg.originalChars);
        unitOriginalChars += baselineChars;

        const segBudget = segmentBudgets.get(seg.id) ?? cleanRaw.length;
        const { text: fitted, trimmed } = trimAtCleanBoundary(cleanRaw, segBudget);
        if (trimmed || fitted.length < baselineChars) unitTrimmed = true;
        if (!fitted) continue;

        unitIncludedChars += fitted.length;
        if (!includedChapterNames.includes(seg.sectionTitle)) {
          includedChapterNames.push(seg.sectionTitle);
        }

        const timeLabel = formatTimestamp(seg.startSeconds);
        const locationParts = [
          seg.sectionTitle,
          timeLabel ? `[${timeLabel}]` : null,
          seg.slideNumber !== null ? `Slide #${seg.slideNumber}` : null,
        ].filter(Boolean);

        formattedSegments.push(`#### ${locationParts.join(' · ')}\n${fitted}`);

        if (attributionList.length < 24) {
          attributionList.push({
            documentId: seg.documentId ?? unit.documentId,
            sourceId: unit.sourceId,
            sourceType: unit.sourceType,
            title: unit.title,
            sectionTitle: seg.sectionTitle,
            trustTier: seg.trustTier,
            startSeconds: seg.startSeconds,
            slideNumber: seg.slideNumber,
            snippet: toSnippet(fitted),
            allocatedQuestions: quota,
            retrievalOrigin: seg.retrievalOrigin,
          });
        }
      }

      if (unitTrimmed) {
        anyTruncated = true;
        warnings.push(
          `Le contenu de « ${unit.title} » a été condensé équitablement (${unitIncludedChars}/${unitOriginalChars} car.) afin de respecter la fenêtre du modèle tout en couvrant chaque source.`,
        );
      }

      coveredChapters += includedChapterNames.length;
      const typeLabel = SOURCE_TYPE_LABELS[unit.sourceType] ?? unit.sourceType;
      const subjectSuffix = unit.subject ? ` (${unit.subject})` : '';

      planLines.push(
        `- [SRC-${sIdx + 1}] « ${unit.title} » (${typeLabel}) : environ ${quota} question(s) — chapitres couverts : ${includedChapterNames.join(', ')}`,
      );
      promptBlocks.push(
        `### [SRC-${sIdx + 1}] ${typeLabel} : ${unit.title}${subjectSuffix}\n${formattedSegments.join('\n\n')}`,
      );

      distribution.push({
        sourceId: unit.sourceId,
        documentId: unit.documentId,
        title: unit.title,
        sourceType: unit.sourceType,
        chapters: includedChapterNames,
        targetQuestions: quota,
        charsIncluded: unitIncludedChars,
        charsOriginal: unitOriginalChars,
        trimmed: unitTrimmed,
      });
    }

    const totalDeclaredSources = Math.max(
      sourceUnits.length,
      params.courses.length + requestedDocIds.length,
    );

    const coverage: ExamCoverageReport = {
      totalSources: totalDeclaredSources,
      coveredSources: sourceUnits.length,
      totalChapters: Math.max(totalChapters, coveredChapters),
      coveredChapters,
      truncated: anyTruncated,
      warnings,
      distribution,
    };

    return {
      promptContext: promptBlocks.join('\n\n'),
      distributionPlan: planLines.join('\n'),
      knowledgeSources: attributionList,
      coverage,
      searchMode,
      degradedReason,
    };
  }
}
