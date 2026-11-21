import type {
  CourseFlashcard,
  CoursePassage,
  CourseStudyLanguage,
  CourseSummaryMode,
} from './course-study.entity.js';

/**
 * Deterministic course grounding.
 *
 * Two responsibilities, no I/O:
 *  - split a Markdown course into citable passages;
 *  - decide whether a student question is *inside* the course before any LLM
 *    call, so an off-course question can never be answered (user requirement).
 */

const STOPWORDS = new Set([
  // French
  'les', 'des', 'une', 'uns', 'unes', 'est', 'sont', 'que', 'qui', 'quoi', 'quel',
  'quelle', 'quels', 'quelles', 'comment', 'pourquoi', 'quand', 'dans', 'pour',
  'par', 'sur', 'avec', 'sans', 'mais', 'donc', 'alors', 'plus', 'moins', 'tout',
  'tous', 'toute', 'toutes', 'cette', 'ces', 'son', 'sa', 'ses', 'leur', 'leurs',
  'nous', 'vous', 'ils', 'elles', 'elle', 'lui', 'moi', 'toi', 'mon', 'ton',
  'peux', 'peut', 'pouvoir', 'veux', 'veut', 'vais', 'faire', 'fait', 'fais',
  'donne', 'donner', 'dis', 'dire', 'explique', 'expliquer', 'aider', 'aide',
  'merci', 'bonjour', 'salut', 'aussi', 'entre', 'chez', 'aux', 'the', 'and',
  // Meta words: a question made only of these is a course-level request.
  'resume', 'resumes', 'resumer', 'resumé', 'synthese', 'summary', 'summarize',
  'cours', 'course', 'chapitre', 'chapters', 'chapitre', 'lecon', 'lesson',
  'fiche', 'fiches', 'flashcard', 'flashcards', 'revision', 'reviser', 'quiz',
  'notion', 'notions', 'concept', 'concepts', 'idee', 'idees', 'point', 'points',
  'cle', 'cles', 'plan', 'objectif', 'objectifs', 'definition', 'definitions',
  // English
  'the', 'this', 'that', 'these', 'those', 'what', 'which', 'how', 'why', 'when',
  'where', 'who', 'with', 'from', 'into', 'about', 'explain', 'give', 'show',
  'please', 'can', 'could', 'would', 'should', 'does', 'did', 'for', 'are', 'was',
]);

const normalize = (text: string): string =>
  text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

/** Crude but stable stemming: `boucles` → `boucl`, `algorithmes` → `algori`. */
const stem = (term: string): string => {
  const base = term.length > 4 && term.endsWith('s') ? term.slice(0, -1) : term;
  return base.length > 6 ? base.slice(0, 6) : base;
};

export const extractQueryTerms = (question: string): string[] => {
  const tokens = normalize(question)
    .split(' ')
    .filter((t) => t.length >= 3 && !STOPWORDS.has(t) && !/^\d+$/.test(t));
  return [...new Set(tokens)];
};

/** Splits Markdown into citable chapters (headings 1-2, or 3 as a fallback). */
export const splitCoursePassages = (
  content: string,
  fallbackTitle: string,
): CoursePassage[] => {
  const passages: CoursePassage[] = [];
  let currentTitle = fallbackTitle.trim() || 'Cours';
  let currentLevel = 0;
  let buffer: string[] = [];

  const flush = () => {
    const text = buffer.join('\n').trim();
    if (text.length > 0) {
      passages.push({
        id: `p-${passages.length + 1}`,
        title: currentTitle,
        level: currentLevel,
        content: text,
      });
    }
    buffer = [];
  };

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    const heading = /^(#{1,2})\s+(.+)$/.exec(line);
    if (heading) {
      flush();
      currentLevel = heading[1]?.length ?? 1;
      currentTitle = (heading[2] ?? '').trim() || currentTitle;
      continue;
    }
    buffer.push(rawLine);
  }
  flush();

  if (passages.length === 0) {
    // No Markdown headings: chunk paragraphs into ~1200 character passages.
    const paragraphs = content
      .split(/\n{2,}/)
      .map((p) => p.trim())
      .filter((p) => p.length > 0);
    let chunk = '';
    for (const paragraph of paragraphs) {
      if (chunk.length + paragraph.length > 1200 && chunk.length > 0) {
        passages.push({
          id: `p-${passages.length + 1}`,
          title: fallbackTitle.trim() || 'Cours',
          level: 0,
          content: chunk,
        });
        chunk = '';
      }
      chunk = chunk.length > 0 ? `${chunk}\n\n${paragraph}` : paragraph;
    }
    if (chunk.length > 0) {
      passages.push({
        id: `p-${passages.length + 1}`,
        title: fallbackTitle.trim() || 'Cours',
        level: 0,
        content: chunk,
      });
    }
  }

  return passages;
};

export interface ScoredPassage {
  passage: CoursePassage;
  score: number;
  matchedTerms: string[];
}

export interface CourseScopeEvaluation {
  inScope: boolean;
  /** Best passage score (0 when nothing matched). */
  score: number;
  terms: string[];
  matchedTerms: string[];
  ranked: ScoredPassage[];
}

/**
 * Deterministic relevance gate.
 *
 * `terms` are the meaningful words of the question (stopwords and study meta
 * words removed). A question made only of meta words ("résume ce cours") is
 * course-level and therefore in scope. Otherwise at least one third of the
 * terms must be found in the course, and at least one passage must score
 * above `minScore`.
 */
export const evaluateCourseScope = (input: {
  question: string;
  courseTitle: string;
  courseSubject?: string | null;
  passages: CoursePassage[];
  minScore?: number;
}): CourseScopeEvaluation => {
  const minScore = input.minScore ?? 0.34;
  const terms = extractQueryTerms(input.question);
  const titleTokens = new Set(
    normalize(`${input.courseTitle} ${input.courseSubject ?? ''}`)
      .split(' ')
      .filter((t) => t.length >= 3)
      .map(stem),
  );

  if (terms.length === 0) {
    return {
      inScope: true,
      score: 1,
      terms,
      matchedTerms: [],
      ranked: input.passages.slice(0, 4).map((passage) => ({
        passage,
        score: 1,
        matchedTerms: [],
      })),
    };
  }

  const ranked: ScoredPassage[] = input.passages.map((passage) => {
    const normalizedText = normalize(`${passage.title} ${passage.content}`);
    const passageStems = new Set(normalizedText.split(' ').map(stem));
    const matchedTerms = terms.filter((term) => {
      if (normalizedText.includes(term)) return true;
      return passageStems.has(stem(term));
    });
    const coverage = matchedTerms.length / terms.length;
    const titleBonus = matchedTerms.some((term) => titleTokens.has(stem(term)))
      ? 0.12
      : 0;
    return {
      passage,
      matchedTerms,
      score: Number(Math.min(1, coverage + titleBonus).toFixed(4)),
    };
  });

  ranked.sort((a, b) => b.score - a.score);

  const best = ranked[0];
  const allMatched = new Set(ranked.flatMap((entry) => entry.matchedTerms));
  const bestScore = best?.score ?? 0;
  const enoughTerms = terms.length <= 2 ? allMatched.size >= 1 : allMatched.size / terms.length >= 0.34;

  return {
    inScope: Boolean(best) && bestScore >= minScore && enoughTerms,
    score: bestScore,
    terms,
    matchedTerms: [...allMatched],
    ranked,
  };
};

const firstSentences = (text: string, max = 2, maxChars = 280): string => {
  const clean = text.replace(/[#*_>`]/g, ' ').replace(/\s+/g, ' ').trim();
  const sentences = clean.split(/(?<=[.!?])\s+/).filter((s) => s.length > 0);
  const picked = sentences.slice(0, max).join(' ');
  const out = picked.length > 0 ? picked : clean;
  return out.length > maxChars ? `${out.slice(0, maxChars).trimEnd()}…` : out;
};

const MODE_LABELS: Record<CourseSummaryMode, string> = {
  short: 'Résumé court',
  medium: 'Résumé structuré',
  detailed: 'Synthèse détaillée',
  exam: 'Fiche de révision examen',
  eli15: 'Explication simplifiée',
  bullet_points: 'Points clés',
};

export const summaryModeLabel = (mode: CourseSummaryMode): string => MODE_LABELS[mode];

/** Deterministic extractive summary, used when the local LLM is unavailable. */
export const buildExtractiveSummary = (input: {
  courseTitle: string;
  passages: CoursePassage[];
  mode: CourseSummaryMode;
  language: CourseStudyLanguage;
}): string => {
  const maxPassages = input.mode === 'short' ? 4 : input.passages.length;
  const selected = input.passages.slice(0, maxPassages);
  const intro =
    input.language === 'en'
      ? `# ${MODE_LABELS[input.mode]} — ${input.courseTitle}`
      : `# ${MODE_LABELS[input.mode]} — ${input.courseTitle}`;
  const headingMots =
    input.language === 'en'
      ? ['## Key points', '## Chapter by chapter']
      : ['## Points clés', '## Chapitre par chapitre'];

  const keyPoints = selected.map(
    (passage) => `- **${passage.title}** : ${firstSentences(passage.content, 1, 180)}`,
  );

  const detail = selected.map(
    (passage) => `### ${passage.title}\n\n${firstSentences(passage.content, 3, 700)}`,
  );

  return [intro, '', headingMots[0], ...keyPoints, '', headingMots[1], '', ...detail].join('\n');
};

export const buildExtractiveFlashcards = (input: {
  courseTitle: string;
  passages: CoursePassage[];
  count: number;
}): CourseFlashcard[] => {
  const cards: CourseFlashcard[] = [];
  const limit = Math.max(1, Math.min(input.count, 30));
  const source = input.passages.length > 0 ? input.passages : [];
  for (let i = 0; i < limit; i += 1) {
    const passage = source[i % Math.max(1, source.length)];
    if (!passage) break;
    cards.push({
      id: `fc-${i + 1}`,
      front: `Que retenir de « ${passage.title} » ?`,
      back: firstSentences(passage.content, 2, 400) || input.courseTitle,
      sectionTitle: passage.title,
    });
  }
  return cards;
};

/** Parses the LLM JSON contract `[{ "front": "...", "back": "..." }]`. */
export const parseFlashcardsJson = (raw: string): CourseFlashcard[] => {
  const withoutFences = raw
    .replace(/```(?:json)?/gi, '')
    .replace(/```/g, '')
    .trim();
  const start = withoutFences.indexOf('[');
  const end = withoutFences.lastIndexOf(']');
  if (start === -1 || end === -1 || end <= start) return [];
  let parsed: unknown;
  try {
    parsed = JSON.parse(withoutFences.slice(start, end + 1));
  } catch {
    return [];
  }
  if (!Array.isArray(parsed)) return [];
  const cards: CourseFlashcard[] = [];
  for (const entry of parsed) {
    if (!entry || typeof entry !== 'object') continue;
    const row = entry as Record<string, unknown>;
    const front = typeof row.front === 'string' ? row.front.trim() : '';
    const back = typeof row.back === 'string' ? row.back.trim() : '';
    if (front.length < 3 || back.length < 3) continue;
    cards.push({
      id: `fc-${cards.length + 1}`,
      front: front.slice(0, 400),
      back: back.slice(0, 1200),
      sectionTitle:
        typeof row.sectionTitle === 'string' && row.sectionTitle.trim().length > 0
          ? row.sectionTitle.trim().slice(0, 200)
          : null,
    });
    if (cards.length >= 30) break;
  }
  return cards;
};
