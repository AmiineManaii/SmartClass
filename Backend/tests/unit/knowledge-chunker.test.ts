import { describe, expect, it } from 'vitest';
import {
  chunkKnowledgeInput,
  computeDocumentContentHash,
  computeSha256,
  estimateTokens,
} from '../../src/modules/knowledge/domain/structure-chunker.js';

describe('Unit: structure-aware knowledge chunker', () => {
  it('preserves Markdown headings hierarchy, fenced code, Mermaid diagrams, LaTeX math, and tables atomically', () => {
    const markdown = [
      '# Algorithmes de Tri',
      '',
      'Introduction générale aux méthodes de tri comparatif.',
      '',
      '## Tri Rapide',
      '',
      'Le tri rapide utilise diviser pour régner.',
      '',
      '```typescript',
      'function quickSort(arr: number[]): number[] {',
      '  if (arr.length <= 1) return arr;',
      '  const pivot = arr[0]!;',
      '  return [...quickSort(arr.slice(1).filter(x => x < pivot)), pivot, ...quickSort(arr.slice(1).filter(x => x >= pivot))];',
      '}',
      '```',
      '',
      '```mermaid',
      'flowchart TD',
      '  A["Partition"] --> B["Pivot"]',
      '  B --> C["Sous-tableau gauche"]',
      '```',
      '',
      '$$',
      'T(n) = 2T(n/2) + \\Theta(n)',
      '$$',
      '',
      '| Cas | Complexité | Espace |',
      '|---|---|---|',
      '| Moyen | O(n log n) | O(log n) |',
      '| Pire | O(n^2) | O(n) |',
    ].join('\n');

    const chunks = chunkKnowledgeInput({
      sourceType: 'COURSE',
      sourceId: 'course-sort',
      authorId: 'teacher-1',
      title: 'Algorithmique L3',
      subject: 'Informatique',
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'DRAFT_AI',
      content: markdown,
    });

    expect(chunks.length).toBeGreaterThanOrEqual(2);
    const intro = chunks.find((c) => c.headingPath === 'Algorithmes de Tri');
    expect(intro?.sectionTitle).toBe('Algorithmes de Tri');
    expect(intro?.contextHeader).toContain('Type: COURSE');
    expect(intro?.contextHeader).toContain('Matière: Informatique');

    const joinedQuickSort = chunks
      .filter((c) => c.headingPath === 'Algorithmes de Tri > Tri Rapide')
      .map((c) => c.content)
      .join('\n');
    expect(joinedQuickSort).toContain('function quickSort');
    expect(joinedQuickSort).toContain('```mermaid');
    expect(joinedQuickSort).toContain('T(n) = 2T(n/2)');
    expect(joinedQuickSort).toContain('| Moyen | O(n log n) |');

    // Ensure fenced blocks were never split mid-fence
    for (const c of chunks) {
      const fenceCount = (c.content.match(/```/g) ?? []).length;
      expect(fenceCount % 2).toBe(0);
    }
  });

  it('chunks long paragraphs cleanly with positive token estimates and deterministic SHA-256 hashes', () => {
    const longParagraph = Array.from(
      { length: 45 },
      (_, idx) =>
        `Phrase pédagogique numéro ${idx + 1} expliquant la descente de gradient stochastique et la convergence convexe.`,
    ).join(' ');

    const chunks = chunkKnowledgeInput({
      sourceType: 'COURSE_SECTION',
      sourceId: 'sec-1',
      authorId: 'teacher-1',
      title: 'Optimisation',
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'VERIFIED',
      content: `## Descente de Gradient\n\n${longParagraph}`,
    });

    expect(chunks.length).toBeGreaterThanOrEqual(2);
    for (const c of chunks) {
      expect(c.tokenEstimate).toBeGreaterThan(20);
      expect(c.tokenEstimate).toBeLessThanOrEqual(650);
      expect(c.contentHash).toMatch(/^[a-f0-9]{64}$/);
    }

    const h1 = computeDocumentContentHash(
      {
        sourceType: 'COURSE_SECTION',
        sourceId: 'sec-1',
        authorId: 'teacher-1',
        title: 'Optimisation',
        visibility: 'PRIVATE_AUTHOR',
        trustTier: 'VERIFIED',
      },
      chunks,
    );
    expect(h1).toBe(computeSha256(JSON.stringify({
      sourceType: 'COURSE_SECTION',
      sourceId: 'sec-1',
      title: 'Optimisation',
      subject: null,
      language: 'fr',
      chunkHashes: chunks.map((c) => c.contentHash),
    })));
    expect(estimateTokens('')).toBe(0);
  });

  it('groups lecture transcript segments into chapter-aligned 30-60s windows preserving timestamps', () => {
    const chunks = chunkKnowledgeInput({
      sourceType: 'LECTURE_TRANSCRIPT',
      sourceId: 'rec-1',
      authorId: 'teacher-1',
      title: 'Data Science Session 1',
      subject: 'Data Science',
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'DRAFT_AI',
      chapters: [
        {
          orderIndex: 0,
          title: 'Introduction CRISP-DM',
          summary: 'Cadre global',
          startSeconds: 0,
          endSeconds: 40,
          sourcePage: 1,
        },
        {
          orderIndex: 1,
          title: 'Nettoyage de données',
          summary: 'Imputation et outliers',
          startSeconds: 41,
          endSeconds: 95,
          sourcePage: 2,
        },
      ],
      transcriptSegments: [
        { startSeconds: 2, endSeconds: 18, text: 'Bienvenue au cours Data Science.' },
        { startSeconds: 19, endSeconds: 38, text: 'Le cycle CRISP-DM commence par le métier.' },
        { startSeconds: 42, endSeconds: 65, text: 'Ensuite on nettoie les valeurs manquantes par médiane.' },
        { startSeconds: 66, endSeconds: 92, text: 'Les valeurs aberrantes faussent la moyenne.' },
      ],
    });

    expect(chunks.length).toBeGreaterThanOrEqual(2);
    expect(chunks[0]?.sectionTitle).toBe('Introduction CRISP-DM');
    expect(chunks[0]?.startSeconds).toBe(2);
    expect(chunks[0]?.endSeconds).toBe(38);
    expect(chunks[0]?.sourcePage).toBe(1);
    expect(chunks[1]?.sectionTitle).toBe('Nettoyage de données');
    expect(chunks[1]?.startSeconds).toBe(42);
    expect(chunks[1]?.endSeconds).toBe(92);
    expect(chunks[1]?.sourcePage).toBe(2);
  });

  it('chunks lecture slides with slideNumber, timestamp, and sourcePage', () => {
    const chunks = chunkKnowledgeInput({
      sourceType: 'LECTURE_SLIDE',
      sourceId: 'rec-1',
      authorId: 'teacher-1',
      title: 'Cours 1',
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'DRAFT_AI',
      slides: [
        {
          slideNumber: 1,
          timestampSeconds: 12,
          ocrText: 'CRISP-DM Phases',
          visualSummary: 'Schéma circulaire en 6 étapes',
          sourcePage: 3,
        },
        {
          slideNumber: 2,
          timestampSeconds: 75,
          ocrText: '   ',
          visualSummary: '',
          sourcePage: 4,
        },
      ],
    });

    expect(chunks).toHaveLength(1);
    expect(chunks[0]?.slideNumber).toBe(1);
    expect(chunks[0]?.startSeconds).toBe(12);
    expect(chunks[0]?.sourcePage).toBe(3);
    expect(chunks[0]?.content).toContain('CRISP-DM Phases');
  });

  it('chunks lecture packages without exposing quiz answers and splits PDF page markers', () => {
    const pkgChunks = chunkKnowledgeInput({
      sourceType: 'LECTURE_PACKAGE',
      sourceId: 'rec-1',
      authorId: 'teacher-1',
      title: 'Cours SQL',
      visibility: 'CLASS_PUBLISHED',
      trustTier: 'VERIFIED',
      lessonPackage: {
        generalSummary: 'Résumé complet sur les jointures SQL.',
        structuredNotes: '# Jointures\n\nINNER JOIN retourne les lignes correspondantes.',
        keyConcepts: [{ name: 'INNER JOIN', explanation: 'Intersection relationnelle.', timestampSeconds: 30 }],
        definitions: [{ term: 'Clé étrangère', definition: 'Référence une clé primaire.', timestampSeconds: 45 }],
        formulasAndRules: ['Toujours indexer les colonnes de jointure.'],
        examples: [{ title: 'Commandes', description: 'Lier client et commande', solutionOrWalkthrough: 'JOIN ON client_id', timestampSeconds: 60 }],
      },
    });

    expect(pkgChunks.length).toBeGreaterThanOrEqual(4);
    expect(pkgChunks.some((c) => c.content.includes('INNER JOIN'))).toBe(true);
    expect(pkgChunks.some((c) => c.content.includes('Clé étrangère'))).toBe(true);

    const pdfChunks = chunkKnowledgeInput({
      sourceType: 'RECORDING_SOURCE_DOC',
      sourceId: 'rec-1',
      authorId: 'teacher-1',
      title: 'Support.pdf',
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'DRAFT_AI',
      content: '--- Page 1 ---\nTexte de la première page.\n--- Page 2 ---\nTexte de la deuxième page.',
    });

    expect(pdfChunks).toHaveLength(2);
    expect(pdfChunks[0]?.sourcePage).toBe(1);
    expect(pdfChunks[1]?.sourcePage).toBe(2);
    expect(chunkKnowledgeInput({
      sourceType: 'COURSE',
      sourceId: 'empty',
      authorId: 't1',
      title: 'Vide',
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'DRAFT_AI',
      content: '   \n\n  ',
    })).toEqual([]);
  });
});
