import { describe, it, expect } from 'vitest';
import { buildCoursePrompt, COURSE_PROMPT_VERSION, maxTokensForLevel, shouldOfferTools } from '../../src/modules/ai-assistant/domain/course-prompt.js';
import {
  DEFAULT_EXTRAS,
  GenerateCourseUseCase,
  extrasForMode,
} from '../../src/modules/ai-assistant/application/generate-course.use-case.js';
import { ImprovePdfUseCase } from '../../src/modules/ai-assistant/application/improve-pdf.use-case.js';
import { UnpdfTextExtractor } from '../../src/modules/ai-assistant/infrastructure/pdf-text-extractor.adapter.js';
import { htmlToText } from '../../src/modules/ai-assistant/infrastructure/native-url-fetcher.adapter.js';
import type { AiGatewayPort } from '../../src/modules/ai-assistant/domain/ai-gateway.port.js';
import type { UrlFetcherPort } from '../../src/modules/ai-assistant/domain/url-fetcher.port.js';
import type { PdfTextExtractorPort } from '../../src/modules/ai-assistant/infrastructure/pdf-text-extractor.adapter.js';

const fakeGateway: AiGatewayPort = {
  chatCompletion: async (input) => ({
    content: `# Generated (${input.system.length}+${input.user.length})`,
    promptTokens: 10,
    completionTokens: 20,
    model: 'Qwen3.5-4B-GGUF',
    toolsUsed: (input.tools?.length ?? 0) > 0,
  }),
  streamCompletion: async (input, onDelta) => {
    onDelta('# Generated');
    return { promptTokens: 10, completionTokens: 20, model: 'Qwen3.5-4B-GGUF' };
  },
  checkHealth: async () => ({ available: true, model: 'Qwen3.5-4B-GGUF', latencyMs: 5 }),
};

const fakeFetcher: UrlFetcherPort = {
  fetchText: async (url: string) => ({
    finalUrl: url,
    title: 'Fetched Title',
    text: `Page content about algorithms. ${'x'.repeat(200)}`,
  }),
};

describe('Unit: course prompt builder (versioned)', () => {
  const base = {
    difficulty: 'moyen' as const,
    extras: { examples: true, mermaid: true, webImages: false, webSearch: false, thinking: false },
    toolsOffered: true,
  };

  it('exposes a stable prompt version', () => {
    expect(COURSE_PROMPT_VERSION).toMatch(/^\d{4}-\d{2}-\d{2}\.v\d+$/);
  });

  it('reshapes guidance when the level changes', () => {
    const concis = buildCoursePrompt({ mode: 'topic', level: 'concis', format: 'resume', subject: 'Les boucles', ...base });
    const normal = buildCoursePrompt({ mode: 'topic', level: 'equilibre', format: 'resume', subject: 'Les boucles', ...base });
    const detaille = buildCoursePrompt({ mode: 'topic', level: 'detaille', format: 'resume', subject: 'Les boucles', ...base });
    expect(concis.system).toContain('COURS COURT');
    expect(concis.system).toContain('800 mots');
    expect(concis.system).toContain('Synthèse');
    expect(normal.system).toContain('COURS NORMAL');
    expect(normal.system).toContain('Étude de cas');
    expect(normal.system).toContain('Correction de l');
    expect(detaille.system).toContain('COURS COMPLET D');
    expect(detaille.system).toContain('exercices corrigés');
    expect(concis.system).not.toContain('exercices corrigés');
  });

  it('budgets output tokens per level (32K for complet)', () => {
    expect(maxTokensForLevel('concis', 32768)).toBe(8192);
    expect(maxTokensForLevel('equilibre', 32768)).toBe(20480);
    expect(maxTokensForLevel('detaille', 32768)).toBe(32768);
    // Small local contexts cap everything.
    expect(maxTokensForLevel('detaille', 8000)).toBe(8000);
  });

  it('restricts mermaid to renderer-supported types (no mindmap)', () => {
    const prompt = buildCoursePrompt({ mode: 'topic', level: 'equilibre', format: 'resume', subject: 'Les boucles', ...base });
    expect(prompt.system).toContain('sequenceDiagram');
    expect(prompt.system).toContain('INTERDIT');
    const mindmap = buildCoursePrompt({ mode: 'topic', level: 'equilibre', format: 'carte-mentale', subject: 'Les boucles', ...base });
    expect(mindmap.system).toContain('graph TD');
    expect(mindmap.system).not.toMatch(/\(mindmap\) couvrant/);
  });

  it('reshapes guidance when the difficulty changes', () => {
    const facile = buildCoursePrompt({ mode: 'topic', level: 'equilibre', difficulty: 'facile', format: 'resume', subject: 'Les boucles', extras: base.extras });
    const difficile = buildCoursePrompt({ mode: 'topic', level: 'equilibre', difficulty: 'difficile', format: 'resume', subject: 'Les boucles', extras: base.extras });
    expect(facile.system).toContain('FACILE');
    expect(facile.system).toContain('prérequis');
    expect(difficile.system).toContain('DIFFICILE');
    expect(difficile.system).toContain('challenge');
  });

  it('adds examples, mermaid and web images only when requested', () => {
    const full = buildCoursePrompt({
      mode: 'topic',
      level: 'equilibre',
      difficulty: 'moyen',
      format: 'resume',
      subject: 'Les boucles',
      extras: { examples: true, mermaid: true, webImages: true, webSearch: false, thinking: false },
      toolsOffered: true,
    });
    expect(full.system).toContain('mermaid');
    expect(full.system).toContain('![description](url)');
    const bare = buildCoursePrompt({
      mode: 'topic',
      level: 'equilibre',
      difficulty: 'moyen',
      format: 'resume',
      subject: 'Les boucles',
      extras: { examples: false, mermaid: false, webImages: false, webSearch: false, thinking: false },
      toolsOffered: false,
    });
    expect(bare.system).toContain('texte seul');
    // The extras block itself must not request figures: check only the
    // part after the enrichissements marker (level guidance may mention
    // mermaid when relevant for pedagogy).
    const extrasBlock = bare.system.split('Enrichissements')[1] ?? '';
    expect(extrasBlock).not.toContain('figures mermaid');
  });

  it('adapts the output schema to the format', () => {
    const flashcards = buildCoursePrompt({ mode: 'topic', level: 'equilibre', format: 'flashcards', subject: 'Les boucles', ...base });
    const mindmap = buildCoursePrompt({ mode: 'topic', level: 'equilibre', format: 'carte-mentale', subject: 'Les boucles', ...base });
    expect(flashcards.system).toContain('FICHES MÉMO');
    expect(mindmap.system).toContain('mermaid');
  });

  it('grounds improve modes in the provided source', () => {
    const improved = buildCoursePrompt({
      mode: 'text',
      level: 'equilibre',
      format: 'resume',
      sourceText: 'Chapitre 1: les pointeurs...',
      ...base,
    });
    expect(improved.user).toContain('Chapitre 1: les pointeurs...');
    expect(improved.user).toContain('corrige les erreurs');
  });

  it('keeps role, task, constraints and format sections', () => {
    const prompt = buildCoursePrompt({ mode: 'topic', level: 'equilibre', format: 'resume', subject: 'Les boucles', ...base });
    expect(prompt.system).toContain('Rôle');
    expect(prompt.system).toContain('Tâche');
    expect(prompt.system).toContain('Contraintes');
    expect(prompt.system).toContain('Fidélité');
  });

  it('offers tools only when the teacher asked (or images need search)', () => {
    // Default: no tools — plain courses answer directly, no 20 s+ stall.
    expect(shouldOfferTools({ webSearch: false, webImages: false, webSearchEnabled: true })).toBe(false);
    // Teacher toggled web search on.
    expect(shouldOfferTools({ webSearch: true, webImages: false, webSearchEnabled: true })).toBe(true);
    // Web images need real search URLs even without the toggle.
    expect(shouldOfferTools({ webSearch: false, webImages: true, webSearchEnabled: true })).toBe(true);
    // Kill switch: search disabled globally.
    expect(shouldOfferTools({ webSearch: true, webImages: false, webSearchEnabled: false })).toBe(false);
  });

  it('tells the model whether tools are attached (never phantom tools)', () => {
    const withTools = buildCoursePrompt({ mode: 'topic', level: 'concis', format: 'resume', subject: 'Les boucles', ...base, toolsOffered: true });
    expect(withTools.system).toContain('tu as accès à web_search');
    const withoutTools = buildCoursePrompt({ mode: 'topic', level: 'concis', format: 'resume', subject: 'Les boucles', ...base, toolsOffered: false });
    expect(withoutTools.system).toContain('aucun outil externe');
    expect(withoutTools.system).toContain('n\'émet aucun appel d\'outil');
    expect(withoutTools.system).not.toContain('tu as accès à web_search');
  });
});

describe('Unit: source-aware extras', () => {
  it('enables web search for URL imports and thinking + search for old documents', () => {
    expect(extrasForMode('url')).toEqual({ ...DEFAULT_EXTRAS, webSearch: true });
    expect(extrasForMode('text')).toEqual({ ...DEFAULT_EXTRAS, thinking: true, webSearch: true });
  });

  it('keeps topic generation fast by default', () => {
    expect(extrasForMode('topic')).toEqual(DEFAULT_EXTRAS);
  });

  it('lets explicit teacher values override the source defaults', () => {
    expect(extrasForMode('text', { thinking: false, webSearch: false })).toEqual(DEFAULT_EXTRAS);
    expect(extrasForMode('url', { webSearch: false })).toEqual(DEFAULT_EXTRAS);
    expect(extrasForMode('topic', { examples: false, mermaid: false })).toMatchObject({
      examples: false,
      mermaid: false,
    });
  });
});

describe('Unit: GenerateCourseUseCase', () => {
  it('generates from a topic with tools offered', async () => {
    const useCase = new GenerateCourseUseCase(fakeGateway, fakeFetcher);
    const result = await useCase.execute({
      mode: 'topic',
      level: 'detaille',
      difficulty: 'difficile',
      format: 'flashcards',
      extras: { examples: true, mermaid: false, webImages: true },
      subject: 'Les arbres AVL en Algorithmique',
    });
    expect(result.content).toContain('# Generated');
    expect(result.toolsUsed).toBe(true);
    expect(result.difficulty).toBe('difficile');
    expect(result.truncatedSource).toBe(false);
    expect(result.promptVersion).toBe(COURSE_PROMPT_VERSION);
  });

  it('forwards the teacher tool toggles to the gateway', async () => {
    const seen: Array<Record<string, unknown>> = [];
    const spyGateway: AiGatewayPort = {
      ...fakeGateway,
      chatCompletion: async (input) => {
        seen.push({ tools: input.tools, thinking: input.thinking });
        return {
          content: '# Generated',
          promptTokens: 10,
          completionTokens: 20,
          model: 'Qwen3.5-4B-GGUF',
          toolsUsed: (input.tools?.length ?? 0) > 0,
        };
      },
    };
    const useCase = new GenerateCourseUseCase(spyGateway, fakeFetcher);
    // Teacher enabled both toggles: tools attached, thinking on.
    const withToggles = await useCase.execute({
      mode: 'topic',
      level: 'concis',
      format: 'resume',
      extras: { webSearch: true, thinking: true },
      subject: 'Les arbres AVL en Algorithmique',
    });
    expect(withToggles.toolsUsed).toBe(true);
    expect(seen[0]?.thinking).toBe(true);
    expect(Array.isArray(seen[0]?.tools)).toBe(true);
    // Defaults (toggles off): no tools, no thinking — fast direct answer.
    const plain = await useCase.execute({
      mode: 'topic',
      level: 'concis',
      format: 'resume',
      subject: 'Les arbres AVL en Algorithmique',
    });
    expect(plain.toolsUsed).toBe(false);
    expect(seen[1]?.thinking).toBe(false);
    expect(seen[1]?.tools).toBeUndefined();
  });

  it('defaults difficulty to moyen and extras safely', async () => {
    const useCase = new GenerateCourseUseCase(fakeGateway, fakeFetcher);
    const result = await useCase.execute({
      mode: 'topic',
      level: 'concis',
      format: 'resume',
      subject: 'Les arbres AVL en Algorithmique',
    });
    expect(result.difficulty).toBe('moyen');
  });

  it('streams deltas and resolves metadata without content', async () => {
    const useCase = new GenerateCourseUseCase(fakeGateway, fakeFetcher);
    const deltas: string[] = [];
    const meta = await useCase.stream(
      {
        mode: 'topic',
        level: 'concis',
        format: 'resume',
        subject: 'Les arbres AVL en Algorithmique',
      },
      (delta) => deltas.push(delta),
    );
    expect(deltas.join('')).toBe('# Generated');
    expect(meta.model).toBe('Qwen3.5-4B-GGUF');
    expect(meta.promptVersion).toBe(COURSE_PROMPT_VERSION);
    expect('content' in meta).toBe(false);
  });

  it('rejects a too-short topic subject with 422', async () => {
    const useCase = new GenerateCourseUseCase(fakeGateway, fakeFetcher);
    await expect(
      useCase.execute({ mode: 'topic', level: 'concis', format: 'resume', subject: 'Maths' }),
    ).rejects.toMatchObject({ statusCode: 422 });
  });

  it('fetches a url then improves its content', async () => {
    const useCase = new GenerateCourseUseCase(fakeGateway, fakeFetcher);
    const result = await useCase.execute({
      mode: 'url',
      level: 'equilibre',
      format: 'resume',
      url: 'https://example.com/cours',
    });
    expect(result.sourceChars).toBeGreaterThan(100);
    expect(result.content).toContain('# Generated');
  });

  it('rejects short source text with 422', async () => {
    const useCase = new GenerateCourseUseCase(fakeGateway, fakeFetcher);
    await expect(
      useCase.execute({ mode: 'text', level: 'concis', format: 'resume', sourceText: 'trop court' }),
    ).rejects.toMatchObject({ statusCode: 422 });
  });

  it('flags truncation for oversized sources', async () => {
    const useCase = new GenerateCourseUseCase(fakeGateway, fakeFetcher);
    const result = await useCase.execute({
      mode: 'text',
      level: 'concis',
      format: 'resume',
      sourceText: `pad ${'y'.repeat(60000)}`,
    });
    expect(result.truncatedSource).toBe(true);
  });
});

describe('Unit: ImprovePdfUseCase', () => {
  const file = (text: string) => ({
    buffer: Buffer.from(`%PDF-1.4 ${text}`),
    originalName: 'cours.pdf',
    size: 1024,
  });

  it('improves extracted PDF text through the gateway', async () => {
    const fakeExtractor: PdfTextExtractorPort = {
      extract: async () => ({ text: `Ancien cours. ${'z'.repeat(200)}`, totalPages: 3 }),
    };
    const useCase = new ImprovePdfUseCase(fakeExtractor, fakeGateway);
    const result = await useCase.execute({
      file: file('x'),
      level: 'equilibre',
      difficulty: 'facile',
      format: 'resume',
    });
    expect(result.fileName).toBe('cours.pdf');
    expect(result.totalPages).toBe(3);
    expect(result.difficulty).toBe('facile');
    expect(result.truncatedSource).toBe(false);
    expect(result.content).toContain('# Generated');
  });

  it('propagates extraction failures (422)', async () => {
    const fakeExtractor: PdfTextExtractorPort = {
      extract: async () => {
        throw new Error('nope');
      },
    };
    const useCase = new ImprovePdfUseCase(fakeExtractor, fakeGateway);
    await expect(
      useCase.execute({ file: file('x'), level: 'concis', format: 'resume' }),
    ).rejects.toThrow('nope');
  });

  it('reports the generating phase once extraction finishes (stream)', async () => {
    const fakeExtractor: PdfTextExtractorPort = {
      extract: async () => ({ text: `Ancien cours. ${'z'.repeat(200)}`, totalPages: 3 }),
    };
    const useCase = new ImprovePdfUseCase(fakeExtractor, fakeGateway);
    const phases: string[] = [];
    const meta = await useCase.stream(
      { file: file('x'), level: 'concis', format: 'resume' },
      () => undefined,
      (phase) => phases.push(phase),
    );
    expect(meta.model).toBe('Qwen3.5-4B-GGUF');
    expect(phases).toEqual(['generating']);
  });
});

describe('Unit: UnpdfTextExtractor', () => {
  // One Tj operator per line, like real PDFs (a single giant Tj gets
  // truncated by the underlying pdf.js text layer).
  const buildPdf = (lines: string[]): Buffer => {
    const stream = lines
      .map((line, i) => `BT /F1 12 Tf 72 ${720 - i * 20} Td (${line}) Tj ET`)
      .join('\n');
    const objs = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      `<< /Length ${Buffer.byteLength(stream)} >> stream\n${stream}\nendstream`,
    ];
    let pdf = '%PDF-1.4\n';
    const offsets: number[] = [];
    for (let i = 0; i < objs.length; i++) {
      offsets.push(Buffer.byteLength(pdf));
      pdf += `${i + 1} 0 obj\n${objs[i]}\nendobj\n`;
    }
    const xrefAt = Buffer.byteLength(pdf);
    pdf += 'xref\n0 6\n0000000000 65535 f \n';
    for (const offset of offsets) {
      pdf += `${String(offset).padStart(10, '0')} 00000 n \n`;
    }
    pdf += 'trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n' + xrefAt + '\n%%EOF';
    return Buffer.from(pdf, 'latin1');
  };

  it('extracts text and page count from a valid PDF', async () => {
    const extractor = new UnpdfTextExtractor();
    const lines = ['Chapitre 1 : les pointeurs.'];
    for (let i = 0; i < 10; i++) lines.push(`Contenu pedagogique reel numero ${i}.`);
    const result = await extractor.extract(buildPdf(lines));
    expect(result.totalPages).toBe(1);
    expect(result.text).toContain('Chapitre 1');
    expect(result.text.length).toBeGreaterThan(100);
  });

  it('rejects non-PDF buffers with 422', async () => {
    const extractor = new UnpdfTextExtractor();
    await expect(extractor.extract(Buffer.from('not a pdf at all'))).rejects.toMatchObject({
      statusCode: 422,
    });
  });
});

describe('Unit: htmlToText extraction', () => {
  it('strips scripts/styles/tags and keeps the title', () => {
    const { title, text } = htmlToText(
      '<html><head><title>Mon Cours</title><style>.x{}</style></head>' +
        '<body><script>alert(1)</script><h1>Intro</h1><p>Les pointeurs &amp; références.</p></body></html>',
    );
    expect(title).toBe('Mon Cours');
    expect(text).toContain('Intro');
    expect(text).toContain('Les pointeurs & références.');
    expect(text).not.toContain('alert');
  });
});
