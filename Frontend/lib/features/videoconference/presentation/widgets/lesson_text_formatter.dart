/// Formats AI-generated lecture text, Markdown notes, quiz explanations, and
/// slide OCR text for clean presentation in Flutter.
library;

final List<(RegExp, String)> _latexTokenReplacements = [
  (RegExp(r'\$\s*\\rightarrow\s*\$|\\rightarrow\b|\$\s*->\s*\$'), '→'),
  (RegExp(r'\$\s*\\leftarrow\s*\$|\\leftarrow\b'), '←'),
  (RegExp(r'\$\s*\\Rightarrow\s*\$|\\Rightarrow\b'), '⇒'),
  (RegExp(r'\$\s*\\Leftarrow\s*\$|\\Leftarrow\b'), '⇐'),
  (RegExp(r'\$\s*\\leftrightarrow\s*\$|\\leftrightarrow\b'), '↔'),
  (RegExp(r'\$\s*\\times\s*\$|\\times\b'), '×'),
  (RegExp(r'\$\s*\\approx\s*\$|\\approx\b'), '≈'),
  (RegExp(r'\$\s*\\leq?\s*\$|\\leq?\b'), '≤'),
  (RegExp(r'\$\s*\\geq?\s*\$|\\geq?\b'), '≥'),
  (RegExp(r'\$\s*\\neq?\s*\$|\\neq?\b'), '≠'),
  (RegExp(r'\$\s*\\pm\s*\$|\\pm\b'), '±'),
  (RegExp(r'\$\s*\\cdot\s*\$|\\cdot\b'), '·'),
];

final List<RegExp> _slideChromePatterns = [
  RegExp(r'https?://localhost(?::\d+)?\S*', caseSensitive: false),
  RegExp(
    r'\bArc\s+SmartClass(?:\s*[-–—]\s*(?:Profil|Profile)\s*\d*(?:\s*[-–—]\s*Mi\w*)?)?\.{0,3}',
    caseSensitive: false,
  ),
  RegExp(
    r'\bSmartClass\s*[-–—]\s*(?:Profil|Profile|Antigravity)\b[^.\n]*',
    caseSensitive: false,
  ),
  RegExp(r'\bProfil\s+\d+(?:\s*[-–—]\s*Mi\w*)?\.{0,3}', caseSensitive: false),
  RegExp(r'\bAntigravity(?:\s+I?\S*)?\.{0,3}', caseSensitive: false),
  RegExp(
    r'\bbackend\s*[-–—]\s*App\s*[-–—]\s*Docker\S*\.{0,3}',
    caseSensitive: false,
  ),
  RegExp(r'\bNews\s+articles\b\.{0,3}', caseSensitive: false),
  RegExp(r'\btell\s+three\s+bichichim\S*\.{0,3}', caseSensitive: false),
];

/// Converts raw inline LaTeX math symbols (`$\rightarrow$`, `\leq`, ...) into
/// crisp Unicode glyphs and removes runaway hallucination repetition loops
/// while preserving Markdown structure and indentation.
String sanitizeLessonDisplayText(String raw) {
  if (raw.isEmpty) return '';
  var out = raw;

  for (final (pattern, replacement) in _latexTokenReplacements) {
    out = out.replaceAll(pattern, replacement);
  }

  // Strip runaway repeated punctuation/currency tokens (5+ repetitions)
  out = out.replaceAll(RegExp(r'(?:[$*#=~_|\\]\s*){5,}'), ' ');

  // Strip identical short words repeated 6+ times in a row
  out = out.replaceAll(
    RegExp(r'\b(\w{1,12})(?:\s+\1){5,}\b', caseSensitive: false),
    r'$1',
  );

  // Collapse extra inline spaces without stripping leading Markdown list indent
  out = out
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'(?<=\S)[ \t]{2,}'), ' ').trimRight())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  return out;
}

/// Cleans visual slide OCR text & visual summaries by removing accidental
/// browser tabs, localhost URLs, IDE chrome, and symbol repetition loops.
String sanitizeSlideDisplayText(String raw) {
  if (raw.isEmpty) return '';
  var out = sanitizeLessonDisplayText(raw);

  for (final pattern in _slideChromePatterns) {
    out = out.replaceAll(pattern, ' ');
  }

  out = out
      .replaceAll(RegExp(r'(?<=\S)[ \t]{2,}'), ' ')
      .replaceAll(RegExp(r'(?:\s*[—–\-|•·…]+\s*)+$'), '')
      .replaceAll(RegExp(r'^(?:\s*[—–\-|•·]+\s*)+'), '')
      .replaceAll(RegExp(r'\.{3,}\s*$'), '')
      .trim();

  return out;
}
