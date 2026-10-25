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
  generateImages?: boolean;
  webSearchEnabled: boolean;
}): boolean =>
  args.webSearchEnabled && (args.webSearch || args.webImages || !!args.generateImages);

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
      '- Images web : illustre les notions clés avec des images et schémas réels ' +
        'en Markdown `![description](url)` — utilise UNIQUEMENT des URL fournies ' +
        'par l\'outil image_search ou web_search, jamais d\'URL inventée.',
    );
  }
  if (extras.generateImages) {
    lines.push(
      '- Illustrations IA générées (ComfyUI) : utilise l\'outil generate_image ' +
        'pour concevoir des schémas explicatifs ou illustrations sur mesure, ' +
        'et insère l\'URL retournée au format Markdown `![description](url)`.',
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
    case 'pdf':
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

export interface CourseOutlineSection {
  id: string;
  title: string;
  description: string;
  keyTopics: string[];
  estimatedMinutes?: number;
}

export interface CourseOutline {
  title: string;
  targetAudience: string;
  prerequisites: string[];
  sections: CourseOutlineSection[];
}

export const buildOutlinePrompt = (input: {
  topic: string;
  level: GenerateLevel;
  difficulty: GenerateDifficulty;
  sourceContext?: string;
}): CoursePrompt => {
  const system =
    `Tu es un concepteur pédagogique universitaire expert.\n` +
    `Ton rôle est de concevoir le plan structuré (syllabus/sommaire) d'un cours universitaire de niveau ${input.level} et difficulté ${input.difficulty}.\n` +
    `Le plan doit être logique, rigoureux, progressif et adapté au système LMD.\n` +
    `Format de sortie : STRICTEMENT un bloc de code JSON valide (sans aucun texte avant ou après) respectant ce schéma exact :\n` +
    `{\n` +
    `  "title": "<Titre précis et académique du cours>",\n` +
    `  "targetAudience": "<Public visé, ex: Licence 3 Informatique>",\n` +
    `  "prerequisites": ["<Prérequis 1>", "<Prérequis 2>"],\n` +
    `  "sections": [\n` +
    `    {\n` +
    `      "id": "sec-1",\n` +
    `      "title": "<Titre du Chapitre ou de la Partie>",\n` +
    `      "description": "<Résumé en 1-2 phrases des notions abordées>",\n` +
    `      "keyTopics": ["<Notion clé 1>", "<Notion clé 2>", "<Exemple ou cas pratique>"],\n` +
    `      "estimatedMinutes": 15\n` +
    `    }\n` +
    `  ]\n` +
    `}`;

  const user =
    `Sujet du cours : ${input.topic}\n` +
    (input.sourceContext ? `Contenu de référence extrait :\n${input.sourceContext.slice(0, 4000)}\n\n` : '') +
    `Génère entre 4 et 7 chapitres structurés au format JSON pur.`;

  return { version: COURSE_PROMPT_VERSION, system, user };
};

export const buildCourseFromOutlinePrompt = (input: {
  outline: CourseOutline;
  level: GenerateLevel;
  difficulty: GenerateDifficulty;
  extras: GenerateExtras;
  format: GenerateFormat;
  toolsOffered: boolean;
  sourceText?: string;
}): CoursePrompt => {
  const base = buildCoursePrompt({
    mode: 'topic',
    level: input.level,
    difficulty: input.difficulty,
    extras: input.extras,
    format: input.format,
    subject: input.outline.title,
    toolsOffered: input.toolsOffered,
  });

  const sectionsList = input.outline.sections
    .map(
      (s, idx) =>
        `Partie ${idx + 1} : ${s.title}\n` +
        `Objectifs / Notions obligatoires : ${s.keyTopics.join(', ')}\n` +
        `Description : ${s.description}`,
    )
    .join('\n\n');

  const customUser =
    `Titre du cours validé : ${input.outline.title}\n` +
    `Public cible : ${input.outline.targetAudience}\n` +
    (input.outline.prerequisites.length > 0 ? `Prérequis : ${input.outline.prerequisites.join(', ')}\n\n` : '\n') +
    (input.sourceText
      ? `--- CONTENU DE RÉFÉRENCE SOURCE (PDF / NOTES DE L'ENSEIGNANT) ---\n${input.sourceText}\n--- FIN DU CONTENU SOURCE ---\n\n`
      : '') +
    `Rédige le cours complet en suivant STRICTEMENT et EXHAUSTIVEMENT le plan validé ci-dessous par l'enseignant. Ne saute aucun chapitre et respecte scrupuleusement cet ordre :\n\n` +
    `--- PLAN VALIDÉ PAR L'ENSEIGNANT ---\n` +
    `${sectionsList}\n` +
    `--- FIN DU PLAN ---\n\n` +
    `Assure-toi que chaque chapitre est complet, riche d'explications et d'exemples pratiques résolus, et intègre le quiz d'évaluation final comme convenu.`;

  return {
    version: COURSE_PROMPT_VERSION,
    system: base.system,
    user: customUser,
  };
};

export const buildRefineSectionPrompt = (input: {
  courseTitle?: string;
  selectedText: string;
  instruction: string;
  fullContext?: string;
  /** Teacher's validated past content recalled from vector memory. */
  memory?: SectionMemoryContext[];
}): CoursePrompt => {
  const system =
    `Tu es un assistant pédagogique universitaire de haut niveau.\n` +
    `L'enseignant révise son cours et souhaite modifier spécifiquement un passage sélectionné.\n` +
    `Ta mission : appliquer STRICTEMENT la consigne demandée par l'enseignant sur le passage sélectionné, tout en maintenant un ton académique, clair et rigoureux.\n` +
    `- Format de sortie : uniquement le texte Markdown de remplacement (la nouvelle version du passage). N'ajoute aucune formule de politesse, ni introduction. Produis directement le contenu prêt à remplacer le passage sélectionné.`;

  const memoryBlock =
    input.memory && input.memory.length > 0
      ? `--- CONTENUS DÉJÀ VALIDÉS PAR L'ENSEIGNANT (style et terminologie de référence) ---\n` +
        input.memory
          .map((m, idx) => `[${idx + 1}] ${m.title}\n${m.content.slice(0, 1200)}`)
          .join('\n\n') +
        `\n--- FIN ---\n\n`
      : '';

  const user =
    (input.courseTitle ? `Titre du cours : ${input.courseTitle}\n\n` : '') +
    (input.fullContext ? `Contexte général du cours (pour cohérence) :\n${input.fullContext.slice(0, 3000)}\n\n` : '') +
    memoryBlock +
    `--- PASSAGE ACTUEL SÉLECTIONNÉ PAR L'ENSEIGNANT ---\n` +
    `${input.selectedText}\n` +
    `--- FIN DU PASSAGE ACTUEL ---\n\n` +
    `CONSIGNE DE L'ENSEIGNANT POUR CE PASSAGE :\n` +
    `"${input.instruction}"\n\n` +
    `Rédige maintenant le nouveau texte de remplacement :`;

  return { version: COURSE_PROMPT_VERSION, system, user };
};

/** A chunk of the teacher's own previously validated course content. */
export interface SectionMemoryContext {
  title: string;
  content: string;
  /** Cosine similarity — used to phrase the block honestly. */
  similarity?: number;
}

export interface SectionPromptInput {
  courseTitle: string;
  targetAudience?: string;
  /** Full outline titles, in order — keeps cross-section coherence. */
  outlineTitles: string[];
  level: GenerateLevel;
  difficulty: GenerateDifficulty;
  /** Current section spec (title/description/notions to cover). */
  section: {
    title: string;
    description: string;
    keyTopics: string[];
    estimatedMinutes?: number;
  };
  /** Position in the plan (1-based) + total, for scoping depth. */
  position: { index: number; total: number };
  /** Titles of sections already written, so transitions stay natural. */
  writtenTitles: string[];
  /** Teacher's previously validated content recalled from vector memory. */
  memory?: SectionMemoryContext[];
  /** Structural extras (examples and figures are on by default). */
  extras?: { examples?: boolean; mermaid?: boolean };
  /** Whether the web_search/fetch_url tools are attached to this request. */
  toolsOffered?: boolean;
}

/**
 * Builds the prompt for ONE section of the section-by-section build. The
 * model receives the whole plan (titles only), the exact notions this
 * section must cover, the sections already written (no repetition), and
 * — when available — the teacher's own past validated content recalled by
 * pgvector, so style and terminology match what they already use.
 */
export const buildSectionPrompt = (input: SectionPromptInput): CoursePrompt => {
  const { index, total } = input.position;
  const isLast = index === total;
  const extras = { examples: true, mermaid: true, ...input.extras };

  const system =
    `Rôle : tu es un concepteur pédagogique expert de l'enseignement supérieur francophone (normes LMD).\n` +
    `Tâche : rédiger UNIQUEMENT le contenu Markdown d'une section précise d'un cours universitaire, en t'inscrivant dans un plan déjà validé par l'enseignant.\n` +
    `Contraintes :\n` +
    `- Exactitude : aucun théorème, formule ou code inventé ; tout code doit être syntaxiquement valide.\n` +
    `- Cohérence : tu écris la section ${index} sur ${total}. Ne répète pas le contenu des sections précédentes déjà rédigées ; fais une transition naturelle depuis la précédente.\n` +
    `- Portée : traite EXCLUSIVEMENT les notions listées pour cette section (ni plus, ni moins). Les sections voisines sont hors périmètre.\n` +
    (extras.examples
      ? `- Exemples : au moins un exemple simple et concret, entièrement résolu.\n`
      : `- Exemples : pas d'exemple résolu, va droit au concept.\n`) +
    (extras.mermaid
      ? `- Figures : si un schéma clarifie la notion, utilise un bloc de code mermaid de type \`graph TD\`, \`flowchart\`, \`sequenceDiagram\`, \`pie\`, \`gantt\` ou \`timeline\` (jamais \`mindmap\`, non supporté par le renderer).\n`
      : '') +
    (input.toolsOffered
      ? `- Recherche web : tu disposes de l'outil web_search (et fetch_url pour lire une page). Utilise-les pour vérifier les faits récents, formules ou références, puis appuie-toi sur ces sources sans inventer d'URL.\n`
      : '') +
    `- Difficulté : ${DIFFICULTY_GUIDANCE[input.difficulty]}\n` +
    `- Sortie : uniquement le corps Markdown de la section, sans préambule. ` +
    `Commence directement par le titre de section en niveau \`##\` ou \`###\` (adapte au contexte du plan), ` +
    `sans reproduire le titre du cours et sans rien écrire avant ce titre.`;

  const planList = input.outlineTitles
    .map((title, idx) => `${idx + 1}. ${title}${idx + 1 === index ? '  ← SECTION EN COURS' : ''}`)
    .join('\n');

  const memoryBlock =
    input.memory && input.memory.length > 0
      ? `\n--- CONTENUS DÉJÀ VALIDÉS PAR L'ENSEIGNANT (référence de style et de terminologie) ---\n` +
        input.memory
          .map((m, idx) => `[${idx + 1}] ${m.title}\n${m.content.slice(0, 1500)}`)
          .join('\n\n') +
        `\n--- FIN ---\n` +
        `Inspire-toi de la terminologie, du niveau de langue et des conventions pédagogiques de ces contenus ` +
        `(c'est l'enseignant qui les a validés), sans jamais en recopier la substance si elle porte sur un autre sujet.\n`
      : '';

  const user =
    `Titre du cours : ${input.courseTitle}\n` +
    (input.targetAudience ? `Public cible : ${input.targetAudience}\n` : '') +
    `Niveau : ${input.level}\n\n` +
    `Plan complet du cours (sections déjà rédigées ou non) :\n${planList}\n\n` +
    (input.writtenTitles.length > 0
      ? `Sections déjà rédigées (ne les répète pas) : ${input.writtenTitles.join(' → ')}\n\n`
      : '') +
    memoryBlock +
    `--- SECTION À RÉDIGER (position ${index}/${total}) ---\n` +
    `Titre : ${input.section.title}\n` +
    (input.section.description ? `Description : ${input.section.description}\n` : '') +
    (input.section.keyTopics.length > 0
      ? `Notions obligatoires à couvrir : ${input.section.keyTopics.join(', ')}\n`
      : '') +
    (input.section.estimatedMinutes
      ? `Durée estimée : ${input.section.estimatedMinutes} minutes\n`
      : '') +
    `--- FIN ---\n\n` +
    (isLast
      ? `Tu rédiges la DERNIÈRE section du cours : termine par une brève conclusion de la section (pas une conclusion de cours entier).\n`
      : '') +
    `Rédige maintenant cette section en Markdown :`;

  return { version: COURSE_PROMPT_VERSION, system, user };
};
