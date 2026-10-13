import type {
  GenerateDifficulty,
  GenerateExtras,
  GenerateFormat,
  GenerateLevel,
  GenerateMode,
} from './ai-gateway.port.js';

/** Prompt template version (track iterations per the prompt-engineer skill). */
export const COURSE_PROMPT_VERSION = '2026-10-12.v6';

/** Max output tokens per course length: court 8K, normal 20K, complet 32K. */
export const MAX_TOKENS_BY_LEVEL: Record<GenerateLevel, number> = {
  concis: 8192,
  equilibre: 20480,
  detaille: 32768,
};

export const maxTokensForLevel = (level: GenerateLevel, cap: number): number =>
  Math.min(MAX_TOKENS_BY_LEVEL[level], cap);

export interface CoursePromptInput {
  mode: GenerateMode;
  level: GenerateLevel;
  difficulty: GenerateDifficulty;
  extras: GenerateExtras;
  format: GenerateFormat;
  subject?: string;
  sourceText?: string;
  sourceUrl?: string | null;
  /**
   * Whether COURSE_TOOLS are attached to this request. Must match the
   * gateway call (see `shouldOfferTools`) so the Outils paragraph never
   * promises tools the model doesn't have.
   */
  toolsOffered: boolean;
}

/**
 * Tools cost 20 s+ of time-to-first-token (server-side execution before
 * any text streams). They are offered when the teacher asked for them
 * (`Recherche web` toggle) or when a feature requires them (web images
 * need real search URLs). `webSearchEnabled` remains the global kill
 * switch for servers without tool support.
 */
export const shouldOfferTools = (args: {
  webSearch: boolean;
  webImages: boolean;
  webSearchEnabled: boolean;
}): boolean =>
  args.webSearchEnabled && (args.webSearch || args.webImages);

export interface CoursePrompt {
  version: string;
  system: string;
  user: string;
}

const LEVEL_GUIDANCE: Record<GenerateLevel, string> = {
  concis:
    'Niveau COURS COURT (remplace le résumé express) : 800 mots maximum. ' +
    'Structure OBLIGATOIRE :\n' +
    '1. `# <Titre du cours>`\n' +
    '2. `## Objectifs` : 3 à 5 objectifs mesurables en une phrase chacun.\n' +
    '3. `## Synthèse` : résumé dense du chapitre en 5 à 8 phrases.\n' +
    '4. `## Points clés` : définitions, formules et notions essentielles ' +
    'uniquement, chacune accompagnée d\'un exemple minimal résolu.\n' +
    '5. `## Quiz rapide` : exactement 5 QCM numérotés (propositions A) B) ' +
    'C) D) sur des lignes séparées), SANS la réponse sous la question.\n' +
    '6. `## Correction du quiz` : pour chaque QCM, la lettre correcte ' +
    'suivie d\'une explication d\'une phrase.',
  equilibre:
    'Niveau COURS NORMAL : 1200 à 2000 mots. Structure OBLIGATOIRE :\n' +
    '1. `# <Titre du cours>`\n' +
    '2. `## Plan du cours` : liste numérotée de toutes les parties.\n' +
    '3. `## Introduction` : contexte, motivation et objectifs d\'apprentissage.\n' +
    '4. Sections `## Partie A : <intitulé>`, `## Partie B : …` etc. — ' +
    'CHAQUE section contient au moins un exemple simple et concret, ' +
    'entièrement résolu, et une figure mermaid si cela clarifie la notion.\n' +
    '5. `## Étude de cas` : un scénario réel complet, énoncé seul.\n' +
    '6. `## Correction de l\'étude de cas` : résolution détaillée pas à pas.\n' +
    '7. `## Quiz` : exactement 5 QCM numérotés (propositions A) B) C) D) ' +
    'sur des lignes séparées), SANS la réponse sous la question.\n' +
    '8. `## Correction du quiz` : pour chaque QCM, la lettre correcte ' +
    'suivie d\'une explication d\'une ou deux phrases.\n' +
    '9. `## Conclusion` : synthèse et pistes d\'approfondissement.',
  detaille:
    'Niveau COURS COMPLET DÉTAILLÉ : 2500 à 4000 mots. Structure ' +
    'OBLIGATOIRE : même ossature que le cours normal (titre, plan, ' +
    'introduction, parties, étude de cas + correction, quiz 5 QCM, ' +
    'correction du quiz avec explications, conclusion) MAIS chaque partie ' +
    'est découpée en sous-sections `### <num>.<x> <sous-titre>` ' +
    '(ex. `### A.1 Fondements`, `### A.2 Mise en œuvre`), avec ' +
    'démonstrations guidées, extraits de code commentés syntaxiquement ' +
    'valides, calculs de complexité, cas limites, et au moins 3 exercices ' +
    'corrigés dont un exercice challenge.',
};

const DIFFICULTY_GUIDANCE: Record<GenerateDifficulty, string> = {
  facile:
    'Difficulté FACILE : vocabulaire simple, rappels des prérequis avant ' +
    'chaque notion, progression douce, exemples du quotidien.',
  moyen:
    'Difficulté MOYENNE : niveau LMD standard, rigueur méthodologique, ' +
    'vocabulaire académique.',
  difficile:
    'Difficulté DIFFICILE : formalisme poussé, démonstrations complètes, ' +
    'cas limites et au moins un exercice challenge corrigé.',
};

const extrasGuidance = (extras: GenerateExtras): string => {
  const lines: string[] = [];
  if (extras.examples) {
    lines.push(
      '- Exemples : chaque section contient au moins un exemple simple et ' +
        'concret, entièrement résolu.',
    );
  }
  if (extras.mermaid) {
    lines.push(
      '- Figures : schémas et graphes sous forme de blocs de code mermaid, ' +
        'un par grande partie. Types AUTORISÉS UNIQUEMENT (rendu natif ' +
        'flutter_mermaid 0.1.0) : `graph`/`flowchart` (ex. `graph TD`), ' +
        '`sequenceDiagram`, `pie`, `gantt`, `timeline`. INTERDIT : `mindmap` ' +
        '(non supporté par le renderer — utilise `graph TD` hiérarchique à ' +
        'la place). Chaque bloc doit être autonettoyant : première ligne = ' +
        'le type, nœuds avec identifiants simples ASCII entre crochets ' +
        '(ex. `A[Factorielle]`), flèches `-->` ; aucun HTML, aucun style ' +
        'exotique.',
    );
  }
  if (extras.webImages) {
    lines.push(
      '- Images web : illustre les notions clés avec des images issues ' +
        'd\'internet en Markdown `![description](url)` — utilise UNIQUEMENT ' +
        'des URL trouvées via web_search, jamais d\'URL inventée.',
    );
  }
  if (lines.length === 0) return 'Contenu texte seul, sans exemple ni figure.';
  return `Enrichissements :\n${lines.join('\n')}`;
};

const FORMAT_GUIDANCE: Record<GenerateFormat, string> = {
  resume:
    'Format COURS STRUCTURÉ : document Markdown qui respecte avant tout la ' +
    'structure demandée par le niveau choisi (court = synthèse + points ' +
    'clés + quiz ; normal = plan, intro, parties avec exemples, étude de ' +
    'cas + correction, quiz + correction, conclusion ; complet = normal ' +
    'détaillé en sous-sections avec exercices et applications).',
  flashcards:
    'Format FICHES MÉMO : paires Question / Réponse numérotées (10 si concis, ' +
    '15 si équilibré, 25 si détaillé), adaptées à la répétition espacée.',
  'carte-mentale':
    'Format CARTE MENTALE : un bloc de code mermaid `graph TD` hiérarchique ' +
    'couvrant tout le sujet (le type `mindmap` est INTERDIT : non supporté ' +
    'par le renderer), suivi d\'une légende d\'une phrase par branche principale.',
};

const BASE_HEAD =
  'Rôle : tu es un concepteur pédagogique expert de l\'enseignement ' +
  'supérieur francophone (normes LMD : Licence, Master, Doctorat).\n' +
  'Tâche : produire un support de cours complet, exact et directement ' +
  'utilisable par un enseignant.\n' +
  'Contraintes :\n' +
  '- Fidélité : si un document source est fourni, fonde chaque section sur ' +
  'lui ; signale explicitement les notions du programme absentes de la source ' +
  'au lieu de les inventer.\n' +
  '- Exactitude : aucun théorème, formule ou code inventé ; tout exemple de ' +
  'code doit être syntaxiquement valide.\n';

const TOOLS_OFFERED_GUIDANCE =
  '- Outils : tu as accès à web_search (informations récentes), fetch_url ' +
  '(lire des pages web), execute_code (vérifier calculs et exemples de ' +
  'code) et calculator. Utilise-les uniquement quand c\'est nécessaire, ' +
  'puis rédige ta réponse finale.\n';

const NO_TOOLS_GUIDANCE =
  '- Outils : aucun outil externe n\'est disponible pour cette requête : ' +
  'rédige directement à partir de tes connaissances, sans inventer, et ' +
  'n\'émet aucun appel d\'outil.\n';

const BASE_TAIL =
  '- Sortie : uniquement le contenu demandé en Markdown, sans préambule ni ' +
  'commentaire métacognitif.';

export const buildCoursePrompt = (input: CoursePromptInput): CoursePrompt => {
  const system =
    `${BASE_HEAD}${input.toolsOffered ? TOOLS_OFFERED_GUIDANCE : NO_TOOLS_GUIDANCE}` +
    `${BASE_TAIL}\n${LEVEL_GUIDANCE[input.level]}\n` +
    `${DIFFICULTY_GUIDANCE[input.difficulty]}\n` +
    `${extrasGuidance(input.extras)}\n${FORMAT_GUIDANCE[input.format]}`;

  let user: string;
  switch (input.mode) {
    case 'topic':
      user =
        `Sujet du cours : ${input.subject}\n` +
        'Construis le support complet sur ce sujet en respectant le niveau ' +
        'et le format demandés.';
      break;
    case 'url':
      user =
        `Améliore et restructure le contenu source ci-dessous en support de ` +
        `cours conforme aux normes LMD : corrige les erreurs, clarifie les ` +
        `passages obscurs, complète les manques du programme, puis applique ` +
        `le niveau et le format demandés.\n` +
        `Source : ${input.sourceUrl}\n\n` +
        `--- CONTENU SOURCE ---\n${input.sourceText}\n--- FIN ---`;
      break;
    case 'text':
      user =
        `Améliore et restructure le cours source ci-dessous (document fourni ` +
        `par l'enseignant : ancien PDF ou notes) en support conforme aux ` +
        `normes LMD : corrige les erreurs, clarifie, complète les manques, ` +
        `puis applique le niveau et le format demandés.\n\n` +
        `--- COURS SOURCE ---\n${input.sourceText}\n--- FIN ---`;
      break;
  }

  return { version: COURSE_PROMPT_VERSION, system, user };
};
