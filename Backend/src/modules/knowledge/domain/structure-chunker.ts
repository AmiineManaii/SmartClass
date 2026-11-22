import { createHash } from 'node:crypto';
import type {
  KnowledgeChunkDraft,
  KnowledgeIndexInput,
  KnowledgePackageInput,
  KnowledgeSourceType,
} from './knowledge-document.entity.js';

const TARGET_MAX_TOKENS = 520;
const OVERLAP_TARGET_CHARS = 200; // ~50 tokens

export const computeSha256 = (value: string): string =>
  createHash('sha256').update(value, 'utf8').digest('hex');

export const estimateTokens = (text: string): number => {
  const clean = text.trim();
  if (!clean) return 0;
  return Math.max(1, Math.ceil(clean.length / 4));
};

const formatClock = (seconds: number): string => {
  const safe = Math.max(0, Math.floor(seconds));
  const mins = Math.floor(safe / 60);
  const secs = safe % 60;
  return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
};

const buildContextHeader = (params: {
  sourceType: KnowledgeSourceType;
  title: string;
  subject?: string | null;
  headingPath?: string | null;
  timeRange?: string | null;
  slideNumber?: number | null;
  sourcePage?: number | null;
}): string => {
  const parts = [`Type: ${params.sourceType}`, `Titre: ${params.title}`];
  if (params.subject?.trim()) parts.push(`Matière: ${params.subject.trim()}`);
  if (params.headingPath?.trim()) parts.push(`Section: ${params.headingPath.trim()}`);
  if (params.timeRange) parts.push(`Temps: ${params.timeRange}`);
  if (params.slideNumber !== null && params.slideNumber !== undefined) {
    parts.push(`Slide: #${params.slideNumber}`);
  }
  if (params.sourcePage !== null && params.sourcePage !== undefined) {
    parts.push(`Page: ${params.sourcePage}`);
  }
  return `[${parts.join(' | ')}]`;
};

const finalizeChunk = (
  chunkIndex: number,
  partial: Omit<KnowledgeChunkDraft, 'chunkIndex' | 'tokenEstimate' | 'contentHash'>,
): KnowledgeChunkDraft => {
  const content = partial.content.trim();
  const contextHeader = partial.contextHeader.trim();
  return {
    ...partial,
    chunkIndex,
    content,
    contextHeader,
    tokenEstimate: estimateTokens(content),
    contentHash: computeSha256(`${contextHeader}\n${content}`),
  };
};

interface MarkdownSection {
  sectionTitle: string | null;
  headingPath: string | null;
  blocks: Array<{ text: string; atomic: boolean }>;
}

const isTableLine = (line: string): boolean => {
  const t = line.trim();
  return t.startsWith('|') && t.includes('|', 1);
};

const parseMarkdownSections = (markdown: string): MarkdownSection[] => {
  const lines = markdown.replace(/\r\n/g, '\n').split('\n');
  const headingStack: Array<{ level: number; text: string }> = [];
  const sections: MarkdownSection[] = [];

  let currentBlocks: Array<{ text: string; atomic: boolean }> = [];
  let paraBuffer: string[] = [];

  const currentHeadingInfo = (): { sectionTitle: string | null; headingPath: string | null } => {
    if (headingStack.length === 0) return { sectionTitle: null, headingPath: null };
    return {
      sectionTitle: headingStack[headingStack.length - 1]!.text,
      headingPath: headingStack.map((h) => h.text).join(' > '),
    };
  };

  const flushParagraph = () => {
    const joined = paraBuffer.join('\n').trim();
    if (joined) {
      currentBlocks.push({ text: joined, atomic: false });
    }
    paraBuffer = [];
  };

  const flushSection = () => {
    flushParagraph();
    if (currentBlocks.length > 0) {
      const info = currentHeadingInfo();
      sections.push({
        sectionTitle: info.sectionTitle,
        headingPath: info.headingPath,
        blocks: currentBlocks,
      });
      currentBlocks = [];
    }
  };

  let i = 0;
  while (i < lines.length) {
    const line = lines[i]!;
    const trimmed = line.trim();

    // 1. Atomic fenced code / mermaid blocks
    if (/^(```|~~~)/.test(trimmed)) {
      flushParagraph();
      const fence = trimmed.slice(0, 3);
      const fenceLines = [line];
      i++;
      while (i < lines.length) {
        fenceLines.push(lines[i]!);
        if (lines[i]!.trim().startsWith(fence)) {
          i++;
          break;
        }
        i++;
      }
      currentBlocks.push({ text: fenceLines.join('\n').trim(), atomic: true });
      continue;
    }

    // 2. Atomic LaTeX $$...$$ display math blocks
    if (trimmed.startsWith('$$')) {
      flushParagraph();
      if (trimmed.endsWith('$$') && trimmed.length > 4) {
        currentBlocks.push({ text: line.trim(), atomic: true });
        i++;
      } else {
        const mathLines = [line];
        i++;
        while (i < lines.length) {
          mathLines.push(lines[i]!);
          if (lines[i]!.trim().endsWith('$$')) {
            i++;
            break;
          }
          i++;
        }
        currentBlocks.push({ text: mathLines.join('\n').trim(), atomic: true });
      }
      continue;
    }

    // 3. Atomic Markdown tables
    if (isTableLine(line)) {
      flushParagraph();
      const tableLines = [line];
      i++;
      while (i < lines.length && isTableLine(lines[i]!)) {
        tableLines.push(lines[i]!);
        i++;
      }
      currentBlocks.push({ text: tableLines.join('\n').trim(), atomic: true });
      continue;
    }

    // 4. Headings (#, ##, ###, ####)
    const headingMatch = /^(#{1,4})\s+(.+?)\s*#*$/.exec(trimmed);
    if (headingMatch) {
      flushSection();
      const level = headingMatch[1]!.length;
      const title = headingMatch[2]!.trim();
      while (
        headingStack.length > 0 &&
        headingStack[headingStack.length - 1]!.level >= level
      ) {
        headingStack.pop();
      }
      headingStack.push({ level, text: title });
      i++;
      continue;
    }

    if (trimmed === '') {
      flushParagraph();
    } else {
      paraBuffer.push(line);
    }
    i++;
  }

  flushSection();
  return sections;
};

const splitOversizedNarrative = (text: string, maxTokens: number): string[] => {
  if (estimateTokens(text) <= maxTokens) return [text];
  const sentences = text.split(/(?<=[.!?؟])\s+|\n+/).filter((s) => s.trim().length > 0);
  if (sentences.length <= 1) {
    // Hard char slice fallback for unpunctuated wall of text
    const maxChars = maxTokens * 4;
    const chunks: string[] = [];
    for (let start = 0; start < text.length; start += Math.max(200, maxChars - OVERLAP_TARGET_CHARS)) {
      const piece = text.slice(start, start + maxChars).trim();
      if (piece) chunks.push(piece);
      if (start + maxChars >= text.length) break;
    }
    return chunks;
  }

  const parts: string[] = [];
  let buf: string[] = [];
  let bufTokens = 0;

  for (const s of sentences) {
    const sTokens = estimateTokens(s);
    if (buf.length > 0 && bufTokens + sTokens > maxTokens) {
      parts.push(buf.join(' '));
      // Build ~50-token sentence overlap from tail of previous chunk
      const overlap: string[] = [];
      let overlapChars = 0;
      for (let j = buf.length - 1; j >= 0; j--) {
        const candidate = buf[j]!;
        if (overlapChars + candidate.length > OVERLAP_TARGET_CHARS && overlap.length > 0) break;
        overlap.unshift(candidate);
        overlapChars += candidate.length;
      }
      buf = overlap;
      bufTokens = estimateTokens(buf.join(' '));
    }
    buf.push(s);
    bufTokens += sTokens;
  }

  if (buf.length > 0) {
    parts.push(buf.join(' '));
  }
  return parts;
};

const packBlocksIntoChunks = (
  blocks: Array<{ text: string; atomic: boolean }>,
  sectionTitle: string | null,
  headingPath: string | null,
  sourcePage: number | null,
  input: Pick<KnowledgeIndexInput, 'sourceType' | 'title' | 'subject'>,
): Array<Omit<KnowledgeChunkDraft, 'chunkIndex' | 'tokenEstimate' | 'contentHash'>> => {
  const out: Array<Omit<KnowledgeChunkDraft, 'chunkIndex' | 'tokenEstimate' | 'contentHash'>> = [];
  let currentParts: string[] = [];
  let currentTokens = 0;

  const contextHeader = buildContextHeader({
    sourceType: input.sourceType,
    title: input.title,
    subject: input.subject,
    headingPath,
    sourcePage,
  });

  const flush = () => {
    const body = currentParts.join('\n\n').trim();
    if (!body) return;
    out.push({
      sectionTitle: sectionTitle ?? input.title,
      headingPath,
      content: headingPath ? `### ${headingPath}\n\n${body}` : body,
      contextHeader,
      startSeconds: null,
      endSeconds: null,
      sourcePage,
      slideNumber: null,
      metadata: {},
    });
    currentParts = [];
    currentTokens = 0;
  };

  for (const block of blocks) {
    const tokens = estimateTokens(block.text);
    if (block.atomic) {
      if (currentParts.length > 0 && currentTokens + tokens > TARGET_MAX_TOKENS) {
        flush();
      }
      if (tokens > TARGET_MAX_TOKENS) {
        // Keep code/LaTeX/table intact inside its own dedicated chunk
        flush();
        currentParts.push(block.text);
        flush();
      } else {
        currentParts.push(block.text);
        currentTokens += tokens;
      }
      continue;
    }

    if (tokens > TARGET_MAX_TOKENS) {
      flush();
      for (const piece of splitOversizedNarrative(block.text, TARGET_MAX_TOKENS)) {
        currentParts.push(piece);
        flush();
      }
      continue;
    }

    if (currentParts.length > 0 && currentTokens + tokens > TARGET_MAX_TOKENS) {
      flush();
    }
    currentParts.push(block.text);
    currentTokens += tokens;
  }

  flush();
  return out;
};

const chunkMarkdownDocument = (input: KnowledgeIndexInput): KnowledgeChunkDraft[] => {
  const raw = input.content?.trim() ?? '';
  if (!raw) return [];

  const sections = parseMarkdownSections(raw);
  const packed: Array<Omit<KnowledgeChunkDraft, 'chunkIndex' | 'tokenEstimate' | 'contentHash'>> = [];

  for (const section of sections) {
    packed.push(
      ...packBlocksIntoChunks(section.blocks, section.sectionTitle, section.headingPath, null, input),
    );
  }

  return packed.map((item, idx) => finalizeChunk(idx, item));
};

const chunkPlainOrPdfDocument = (input: KnowledgeIndexInput): KnowledgeChunkDraft[] => {
  const raw = input.content?.trim() ?? '';
  if (!raw) return [];

  // Split by explicit PDF page markers if present (e.g. `--- Page 3 ---` or `[Page 3]`)
  const pageMarkerRegex = /(?:^|\n)(?:---\s*Page\s+(\d+)\s*---|\[Page\s+(\d+)\])\s*(?:\n|$)/gi;
  const pageSlices: Array<{ page: number | null; text: string }> = [];
  let lastIdx = 0;
  let currentPage: number | null = null;
  let match: RegExpExecArray | null = pageMarkerRegex.exec(raw);

  while (match !== null) {
    const sliceText = raw.slice(lastIdx, match.index).trim();
    if (sliceText) {
      pageSlices.push({ page: currentPage, text: sliceText });
    }
    const pageStr = match[1] ?? match[2] ?? '';
    currentPage = pageStr ? Number.parseInt(pageStr, 10) : currentPage;
    lastIdx = match.index + match[0].length;
    match = pageMarkerRegex.exec(raw);
  }
  const trailing = raw.slice(lastIdx).trim();
  if (trailing) {
    pageSlices.push({ page: currentPage, text: trailing });
  }

  if (pageSlices.length === 0) {
    pageSlices.push({ page: null, text: raw });
  }

  const drafts: KnowledgeChunkDraft[] = [];
  let idx = 0;

  for (const slice of pageSlices) {
    const sections = parseMarkdownSections(slice.text);
    for (const sec of sections) {
      const packed = packBlocksIntoChunks(
        sec.blocks,
        sec.sectionTitle,
        sec.headingPath,
        slice.page,
        input,
      );
      for (const item of packed) {
        drafts.push(finalizeChunk(idx++, item));
      }
    }
  }

  return drafts;
};

const chunkLectureTranscript = (input: KnowledgeIndexInput): KnowledgeChunkDraft[] => {
  const segments = (input.transcriptSegments ?? [])
    .map((s) => ({ ...s, text: s.text.trim() }))
    .filter((s) => s.text.length > 0);
  const chapters = input.chapters ?? [];

  if (segments.length === 0) {
    return chunkPlainOrPdfDocument(input);
  }

  const chapterAt = (ts: number) =>
    chapters.find((c) => ts >= c.startSeconds && ts <= c.endSeconds) ??
    chapters.find((c) => c.startSeconds <= ts) ??
    chapters[0];

  const drafts: KnowledgeChunkDraft[] = [];
  let windowLines: string[] = [];
  let windowStart = segments[0]!.startSeconds;
  let windowEnd = segments[0]!.endSeconds;
  let windowChapter = chapterAt(windowStart);
  let windowTokens = 0;

  const flushWindow = () => {
    const content = windowLines.join(' ').trim();
    if (!content) return;
    const startSec = Math.floor(windowStart);
    const endSec = Math.max(startSec, Math.ceil(windowEnd));
    const chTitle = windowChapter?.title ?? input.title;
    const header = buildContextHeader({
      sourceType: input.sourceType,
      title: input.title,
      subject: input.subject,
      headingPath: chTitle,
      timeRange: `${formatClock(startSec)}-${formatClock(endSec)}`,
      sourcePage: windowChapter?.sourcePage ?? null,
    });
    drafts.push(
      finalizeChunk(drafts.length, {
        sectionTitle: chTitle,
        headingPath: chTitle,
        content: `[${formatClock(startSec)} - ${formatClock(endSec)}] ${content}`,
        contextHeader: header,
        startSeconds: startSec,
        endSeconds: endSec,
        sourcePage: windowChapter?.sourcePage ?? null,
        slideNumber: null,
        metadata: { segmentCount: windowLines.length },
      }),
    );
    windowLines = [];
    windowTokens = 0;
  };

  for (const seg of segments) {
    const segChapter = chapterAt(seg.startSeconds);
    const segTokens = estimateTokens(seg.text);
    const durationIfAdded = seg.endSeconds - windowStart;
    const chapterChanged =
      Boolean(segChapter?.title) &&
      Boolean(windowChapter?.title) &&
      segChapter!.title !== windowChapter!.title;

    if (
      windowLines.length > 0 &&
      (chapterChanged ||
        durationIfAdded > 60 ||
        (durationIfAdded >= 30 && windowTokens + segTokens > 260) ||
        windowTokens + segTokens > TARGET_MAX_TOKENS)
    ) {
      flushWindow();
      windowStart = seg.startSeconds;
      windowChapter = segChapter;
    }

    const line = seg.speaker ? `${seg.speaker}: ${seg.text}` : seg.text;
    windowLines.push(line);
    windowEnd = Math.max(windowEnd, seg.endSeconds);
    windowTokens += segTokens;
  }

  flushWindow();
  return drafts;
};

const chunkLectureSlides = (input: KnowledgeIndexInput): KnowledgeChunkDraft[] => {
  const slides = input.slides ?? [];
  if (slides.length === 0) return chunkMarkdownDocument(input);

  const drafts: KnowledgeChunkDraft[] = [];
  for (const slide of slides) {
    const ocr = slide.ocrText.trim();
    const visual = slide.visualSummary.trim();
    const parts: string[] = [];
    if (ocr) parts.push(`Texte slide:\n${ocr}`);
    if (visual) parts.push(`Analyse visuelle:\n${visual}`);
    const content = parts.join('\n\n').trim();
    if (!content) continue;

    const ts = Math.max(0, Math.floor(slide.timestampSeconds));
    const title = `Slide #${slide.slideNumber} [${formatClock(ts)}]`;
    const contextHeader = buildContextHeader({
      sourceType: input.sourceType,
      title: input.title,
      subject: input.subject,
      headingPath: title,
      timeRange: formatClock(ts),
      slideNumber: slide.slideNumber,
      sourcePage: slide.sourcePage ?? null,
    });

    drafts.push(
      finalizeChunk(drafts.length, {
        sectionTitle: title,
        headingPath: title,
        content,
        contextHeader,
        startSeconds: ts,
        endSeconds: ts,
        sourcePage: slide.sourcePage ?? null,
        slideNumber: slide.slideNumber,
        metadata: {},
      }),
    );
  }
  return drafts;
};

const chunkLecturePackage = (input: KnowledgeIndexInput): KnowledgeChunkDraft[] => {
  const pkg: KnowledgePackageInput | null | undefined = input.lessonPackage;
  if (!pkg) return chunkMarkdownDocument(input);

  const drafts: KnowledgeChunkDraft[] = [];

  if (pkg.generalSummary?.trim()) {
    const header = buildContextHeader({
      sourceType: input.sourceType,
      title: input.title,
      subject: input.subject,
      headingPath: 'Synthèse générale',
    });
    drafts.push(
      finalizeChunk(drafts.length, {
        sectionTitle: 'Synthèse générale',
        headingPath: 'Synthèse générale',
        content: pkg.generalSummary.trim(),
        contextHeader: header,
        startSeconds: null,
        endSeconds: null,
        sourcePage: null,
        slideNumber: null,
        metadata: { packagePart: 'generalSummary' },
      }),
    );
  }

  if (pkg.structuredNotes?.trim()) {
    const noteChunks = chunkMarkdownDocument({
      ...input,
      content: pkg.structuredNotes,
    });
    for (const chunk of noteChunks) {
      drafts.push(
        finalizeChunk(drafts.length, {
          ...chunk,
          metadata: { ...chunk.metadata, packagePart: 'structuredNotes' },
        }),
      );
    }
  }

  // Pack concepts, definitions, formulas, examples & important moments
  // Explicitly NEVER index quizzes or correctAnswer keys here!
  const items: Array<{
    sectionTitle: string;
    text: string;
    ts: number | null;
    page: number | null;
    part: string;
  }> = [];

  for (const kc of pkg.keyConcepts ?? []) {
    if (!kc.name.trim()) continue;
    items.push({
      sectionTitle: 'Concepts clés',
      text: `Concept — ${kc.name.trim()}: ${kc.explanation.trim()}`,
      ts: typeof kc.timestampSeconds === 'number' ? Math.floor(kc.timestampSeconds) : null,
      page: typeof kc.sourcePage === 'number' ? kc.sourcePage : null,
      part: 'keyConcepts',
    });
  }

  for (const def of pkg.definitions ?? []) {
    if (!def.term.trim()) continue;
    items.push({
      sectionTitle: 'Définitions',
      text: `Définition — ${def.term.trim()}: ${def.definition.trim()}`,
      ts: typeof def.timestampSeconds === 'number' ? Math.floor(def.timestampSeconds) : null,
      page: null,
      part: 'definitions',
    });
  }

  for (const rule of pkg.formulasAndRules ?? []) {
    if (!rule.trim()) continue;
    items.push({
      sectionTitle: 'Formules et règles',
      text: `Règle/Formule: ${rule.trim()}`,
      ts: null,
      page: null,
      part: 'formulasAndRules',
    });
  }

  for (const ex of pkg.examples ?? []) {
    if (!ex.title.trim() && !ex.description.trim()) continue;
    items.push({
      sectionTitle: 'Exemples pratiques',
      text: `Exemple — ${ex.title.trim()}: ${ex.description.trim()}\nRésolution: ${ex.solutionOrWalkthrough.trim()}`,
      ts: typeof ex.timestampSeconds === 'number' ? Math.floor(ex.timestampSeconds) : null,
      page: null,
      part: 'examples',
    });
  }

  for (const moment of pkg.importantMoments ?? []) {
    if (!moment.label.trim()) continue;
    items.push({
      sectionTitle: moment.chapterTitle?.trim() || 'Moments clés',
      text: `[${formatClock(moment.timestampSeconds)}] ${moment.label.trim()}: ${moment.reason.trim()}`,
      ts: Math.floor(moment.timestampSeconds),
      page: null,
      part: 'importantMoments',
    });
  }

  let groupLines: string[] = [];
  let groupTokens = 0;
  let groupTitle = 'Concepts & Références';
  let groupTs: number | null = null;
  let groupPage: number | null = null;

  const flushGroup = () => {
    const text = groupLines.join('\n\n').trim();
    if (!text) return;
    drafts.push(
      finalizeChunk(drafts.length, {
        sectionTitle: groupTitle,
        headingPath: groupTitle,
        content: text,
        contextHeader: buildContextHeader({
          sourceType: input.sourceType,
          title: input.title,
          subject: input.subject,
          headingPath: groupTitle,
          timeRange: groupTs !== null ? formatClock(groupTs) : null,
          sourcePage: groupPage,
        }),
        startSeconds: groupTs,
        endSeconds: groupTs,
        sourcePage: groupPage,
        slideNumber: null,
        metadata: { packagePart: 'pedagogicalItems' },
      }),
    );
    groupLines = [];
    groupTokens = 0;
    groupTs = null;
    groupPage = null;
  };

  for (const item of items) {
    const t = estimateTokens(item.text);
    if (groupLines.length > 0 && (groupTokens + t > TARGET_MAX_TOKENS || item.sectionTitle !== groupTitle)) {
      flushGroup();
    }
    groupTitle = item.sectionTitle;
    if (groupTs === null && item.ts !== null) groupTs = item.ts;
    if (groupPage === null && item.page !== null) groupPage = item.page;
    groupLines.push(item.text);
    groupTokens += t;
  }
  flushGroup();

  return drafts;
};

/**
 * Splits heterogeneous SmartClass source payloads into structure-aware chunks
 * preserving headings, atomic code/LaTeX/Mermaid/tables, video timestamps, and page numbers.
 */
export const chunkKnowledgeInput = (input: KnowledgeIndexInput): KnowledgeChunkDraft[] => {
  switch (input.sourceType) {
    case 'COURSE':
    case 'COURSE_SECTION':
      return chunkMarkdownDocument(input);
    case 'LECTURE_TRANSCRIPT':
      return chunkLectureTranscript(input);
    case 'LECTURE_SLIDE':
      return chunkLectureSlides(input);
    case 'LECTURE_PACKAGE':
      return chunkLecturePackage(input);
    case 'RECORDING_SOURCE_DOC':
    case 'UPLOADED_DOCUMENT':
    default:
      return chunkPlainOrPdfDocument(input);
  }
};

export const computeDocumentContentHash = (
  input: KnowledgeIndexInput,
  chunks: KnowledgeChunkDraft[],
): string => {
  const payload = JSON.stringify({
    sourceType: input.sourceType,
    sourceId: input.sourceId,
    title: input.title,
    subject: input.subject ?? null,
    language: input.language ?? 'fr',
    chunkHashes: chunks.map((c) => c.contentHash),
  });
  return computeSha256(payload);
};
