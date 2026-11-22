import { describe, expect, it } from 'vitest';
import {
  isMostlyDesktopNoise,
  sanitizeMathAndMarkdown,
  sanitizeSlideVisionOutput,
} from '../../src/modules/videoconference/index.js';

describe('lesson-text-sanitizer', () => {
  it('converts raw LaTeX inline operators to Unicode and preserves valid Markdown', () => {
    const input = [
      '## 1. Processus de Data Science',
      '  * *hacking skills* et **statistiques**',
      '- Flux : Collecte $\\rightarrow$ Compréhension \\rightarrow Nettoyage $\\rightarrow$ Solution',
      '- Contraintes : $x \\leq y$, $a \\times b$, coût $100 et note $\\neq$ 0',
    ].join('\n');

    const cleaned = sanitizeMathAndMarkdown(input);
    expect(cleaned).not.toContain('\\rightarrow');
    expect(cleaned).not.toContain('$\\');
    expect(cleaned).toContain('→');
    expect(cleaned).toContain('≤');
    expect(cleaned).toContain('×');
    expect(cleaned).toContain('≠');
    expect(cleaned).toContain('  * *hacking skills*');
    expect(cleaned).toContain('$100');
  });

  it('removes degenerate symbol repetition loops like $ $ $ $', () => {
    const hallucinated =
      'Processus de modélisation $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ fin du cours.';
    const cleaned = sanitizeMathAndMarkdown(hallucinated);
    expect(cleaned).not.toContain('$ $ $');
    expect(cleaned).toBe('Processus de modélisation fin du cours.');
  });

  it('strips browser, localhost URL, and IDE desktop chrome while keeping real lecture slides', () => {
    const noisy =
      'LEARNING FROM DATA — Arc SmartClass - Profil 1 - Mi... http://localhost:8283 tell three bichichim... SmartClass - Antigravity I... backend - App - Docker... News articles $ $ $ $ $ $ $ $ $';
    const cleaned = sanitizeSlideVisionOutput(noisy);
    expect(cleaned).not.toContain('localhost:8283');
    expect(cleaned).not.toContain('Antigravity');
    expect(cleaned).not.toContain('Docker');
    expect(cleaned).not.toContain('News articles');
    expect(cleaned).not.toContain('$ $ $');
    expect(cleaned).toContain('LEARNING FROM DATA');
    expect(isMostlyDesktopNoise(noisy)).toBe(true);

    const realSlide =
      'WHAT IS DATA SCIENCE? — solving problems with data, Venn diagram: math & statistics, hacking skills, domain expertise';
    expect(isMostlyDesktopNoise(realSlide)).toBe(false);
    expect(sanitizeSlideVisionOutput(realSlide)).toBe(realSlide);
  });
});
