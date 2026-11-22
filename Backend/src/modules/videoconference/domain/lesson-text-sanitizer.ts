/**
 * Normalizes raw LaTeX tokens, removes degenerate repetition loops (e.g. `$ $ $ $`),
 * and filters accidental desktop/browser/IDE chrome captured during screen-share OCR.
 */

const LATEX_REPLACEMENTS: Array<[RegExp, string]> = [
  [/\$\s*\\rightarrow\s*\$|\\rightarrow\b|\$\s*->\s*\$/g, '→'],
  [/\$\s*\\leftarrow\s*\$|\\leftarrow\b/g, '←'],
  [/\$\s*\\Rightarrow\s*\$|\\Rightarrow\b/g, '⇒'],
  [/\$\s*\\Leftarrow\s*\$|\\Leftarrow\b/g, '⇐'],
  [/\$\s*\\leftrightarrow\s*\$|\\leftrightarrow\b/g, '↔'],
  [/\$\s*\\times\s*\$|\\times\b/g, '×'],
  [/\$\s*\\approx\s*\$|\\approx\b/g, '≈'],
  [/\$\s*\\leq?\s*\$|\\leq?\b/g, '≤'],
  [/\$\s*\\geq?\s*\$|\\geq?\b/g, '≥'],
  [/\$\s*\\neq?\s*\$|\\neq?\b/g, '≠'],
  [/\$\s*\\pm\s*\$|\\pm\b/g, '±'],
  [/\$\s*\\cdot\s*\$|\\cdot\b/g, '·'],
];

const CHROME_PATTERNS: RegExp[] = [
  /https?:\/\/localhost(?::\d+)?\S*/gi,
  /\bArc\s+SmartClass(?:\s*[-–—]\s*(?:Profil|Profile)\s*\d*(?:\s*[-–—]\s*Mi\w*)?)?\.{0,3}/gi,
  /\bSmartClass\s*[-–—]\s*(?:Profil|Profile|Antigravity)\b[^.\n]*/gi,
  /\bProfil\s+\d+(?:\s*[-–—]\s*Mi\w*)?\.{0,3}/gi,
  /\bAntigravity(?:\s+I?\S*)?\.{0,3}/gi,
  /\bbackend\s*[-–—]\s*App\s*[-–—]\s*Docker\S*\.{0,3}/gi,
  /\bNews\s+articles\b\.{0,3}/gi,
  /\btell\s+three\s+bichichim\S*\.{0,3}/gi,
];

const NOISE_MARKER_REGEXES: RegExp[] = [
  /localhost:/i,
  /\bprofil(?:e)?\s+\d+\b/i,
  /\bantigravity\b/i,
  /\bdocker\b/i,
  /\bchrome\b/i,
  /\bedge\b/i,
  /\barc\s+smartclass\b/i,
  /\bzoom\b/i,
  /\blivekit\b/i,
  /\btaskbar\b/i,
  /\bnews\s+articles\b/i,
  /(?:\$\s*){5,}/,
];

export function sanitizeMathAndMarkdown(text: string): string {
  if (!text) return '';
  let out = text;

  for (const [pattern, replacement] of LATEX_REPLACEMENTS) {
    out = out.replace(pattern, replacement);
  }

  // Strip runaway repetition of punctuation / currency symbols (5+ repetitions)
  out = out.replace(/(?:[$*#=~_|\\]\s*){5,}/g, ' ');

  // Strip 1-3 char non-word tokens repeated 5+ times consecutively
  out = out.replace(/(?:^|\s)([^\p{L}\p{N}\s]{1,3})(?:\s+\1){4,}(?=\s|$)/gu, ' ');

  // Collapse identical short words repeated 6+ times consecutively
  out = out.replace(/\b(\w{1,12})(?:\s+\1){5,}\b/gi, '$1');

  // Collapse horizontal multi-spaces after non-whitespace (preserves Markdown list indentation)
  out = out.replace(/(?<=\S)[ \t]{2,}/g, ' ');
  // Clean excessive spaces at ends of lines and around arrows
  out = out
    .split('\n')
    .map((line) => line.replace(/[ \t]+$/g, ''))
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

  return out;
}

export function sanitizeSlideVisionOutput(text: string): string {
  if (!text) return '';
  let out = sanitizeMathAndMarkdown(text);

  for (const pattern of CHROME_PATTERNS) {
    out = out.replace(pattern, ' ');
  }

  out = out
    .replace(/(?<=\S)[ \t]{2,}/g, ' ')
    .replace(/(?:\s*[—–\-|•·…]+\s*)+$/g, '')
    .replace(/^(?:\s*[—–\-|•·]+\s*)+/g, '')
    .replace(/\.{3,}\s*$/g, '')
    .trim();

  return out;
}

export function isMostlyDesktopNoise(text: string): boolean {
  if (!text || !text.trim()) return true;

  let markerCount = 0;
  for (const rx of NOISE_MARKER_REGEXES) {
    if (rx.test(text)) {
      markerCount += 1;
    }
  }
  if (markerCount < 2) {
    return false;
  }

  const origNonSpaceLen = text.replace(/\s+/g, '').length;
  const cleaned = sanitizeSlideVisionOutput(text);
  const cleanedAlnumLen = cleaned.replace(/[^\p{L}\p{N}]/gu, '').length;

  return cleanedAlnumLen < 25 || (origNonSpaceLen > 0 && cleanedAlnumLen / origNonSpaceLen < 0.35);
}
