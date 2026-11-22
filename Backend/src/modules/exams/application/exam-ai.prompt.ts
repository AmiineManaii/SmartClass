import type { ExamKnowledgeBlueprint } from '../domain/exam-knowledge.types.js';
import {
  allocateWaterFillingBudgets,
  trimAtCleanBoundary,
} from './exam-knowledge-blueprint.service.js';

export interface ExamAiPromptInput {
  title: string;
  subject: string | null;
  difficulty: 'facile' | 'moyen' | 'difficile';
  questionCount: number;
  courses: { title: string; subject: string | null; content: string }[];
  maxSourceChars: number;
  focusTopics?: string[];
  blueprint?: ExamKnowledgeBlueprint;
}

const difficultyGuidance: Record<ExamAiPromptInput['difficulty'], string> = {
  facile: 'questions de compréhension directe, une seule notion par question',
  moyen: 'questions d’application qui demandent de relier deux notions du cours',
  difficile: 'questions d’analyse qui exigent de raisonner sur les notions du cours',
};

const buildBalancedLegacySources = (
  courses: ExamAiPromptInput['courses'],
  maxSourceChars: number,
): string => {
  const budget = Math.max(2000, maxSourceChars);
  const items = courses.map((course, idx) => ({
    id: `c-${idx}`,
    rawChars: course.content.replace(/\s+/g, ' ').trim().length,
  }));
  const budgets = allocateWaterFillingBudgets(items, budget);

  return courses
    .map((course, idx) => {
      const clean = course.content.replace(/\s+/g, ' ').trim();
      const cap = budgets.get(`c-${idx}`) ?? clean.length;
      const { text } = trimAtCleanBoundary(clean, cap);
      return `### Cours : ${course.title}${course.subject ? ` (${course.subject})` : ''}\n${text}`;
    })
    .filter((block) => block.trim().length > 0)
    .join('\n\n');
};

export const buildExamPrompt = (input: ExamAiPromptInput): { system: string; user: string } => {
  const sourcesBlock = input.blueprint
    ? input.blueprint.promptContext
    : buildBalancedLegacySources(input.courses, input.maxSourceChars);

  const systemLines = [
    'Tu es un enseignant qui rédige un contrôle pour sa classe.',
    'RÈGLES ABSOLUES :',
    '1. Utilise UNIQUEMENT les sources pédagogiques fournies par l’enseignant ci-dessous.',
    '2. N’invente aucune notion, aucun chiffre, aucune définition absente des sources.',
    '3. Chaque question est à choix unique avec exactement 4 propositions et une seule bonne réponse.',
    '4. La bonne réponse doit être justifiable directement par le texte des sources.',
  ];

  if (input.blueprint) {
    systemLines.push(
      '5. Répartis équitablement les questions selon le plan de répartition et couvre chaque source et chapitre listés, sans tout concentrer sur le premier extrait.',
      '6. Ne recopie jamais mot pour mot un quiz d’auto-évaluation ; formule des questions originales d’évaluation.',
      '7. Réponds uniquement avec un objet JSON valide, sans markdown, sans commentaire.',
    );
  } else {
    systemLines.push(
      '5. Réponds uniquement avec un objet JSON valide, sans markdown, sans commentaire.',
    );
  }

  systemLines.push(
    'Schéma attendu :',
    '{"title":"...","questions":[{"prompt":"...","hint":null,"options":["...","...","...","..."],"correctOptionId":"A","explanation":"...","points":1}]}',
  );

  const focusLine =
    input.focusTopics && input.focusTopics.length > 0
      ? `Notions / thèmes prioritaires : ${input.focusTopics.join(', ')}`
      : '';

  const user = [
    `Titre souhaité : ${input.title}`,
    input.subject ? `Matière : ${input.subject}` : '',
    `Nombre de questions : ${input.questionCount}`,
    `Niveau : ${difficultyGuidance[input.difficulty]}`,
    focusLine,
    input.blueprint?.distributionPlan
      ? `\nPLAN DE RÉPARTITION ÉQUILIBRÉ :\n${input.blueprint.distributionPlan}`
      : '',
    '',
    'CONTENU PÉDAGOGIQUE DE RÉFÉRENCE (sources autorisées) :',
    sourcesBlock,
    '',
    'Génère maintenant le JSON demandé. Les identifiants de bonnes réponses sont A, B, C ou D.',
  ]
    .filter((line) => line !== '')
    .join('\n');

  return { system: systemLines.join('\n'), user };
};

export const buildExamJsonSchema = (questionCount: number): Record<string, unknown> => ({
  type: 'object',
  required: ['title', 'questions'],
  additionalProperties: false,
  properties: {
    title: { type: 'string' },
    description: { type: ['string', 'null'] },
    questions: {
      type: 'array',
      minItems: 1,
      maxItems: Math.min(30, Math.max(1, questionCount)),
      items: {
        type: 'object',
        required: ['prompt', 'options', 'correctOptionId', 'explanation', 'points'],
        additionalProperties: false,
        properties: {
          prompt: { type: 'string' },
          hint: { type: ['string', 'null'] },
          options: {
            type: 'array',
            minItems: 4,
            maxItems: 4,
            items: { type: 'string' },
          },
          correctOptionId: { type: 'string', enum: ['A', 'B', 'C', 'D'] },
          explanation: { type: 'string' },
          points: { type: 'integer', minimum: 1, maximum: 10 },
        },
      },
    },
  },
});

export const extractJsonPayload = (content: string): unknown => {
  const trimmed = content.trim();
  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  const candidate = fenced?.[1] ? fenced[1].trim() : trimmed;
  const start = candidate.indexOf('{');
  const end = candidate.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw new Error('No JSON object found in the model output');
  }
  const slice = candidate.slice(start, end + 1);
  try {
    return JSON.parse(slice) as unknown;
  } catch {
    const repaired = slice
      .replace(
        /("options"\s*:\s*\[[^[\]]*?)(\s*,\s*"(?:correctOptionIds?|answer|explanation|points)"\s*:)/g,
        '$1]$2',
      )
      .replace(/,\s*([}\]])/g, '$1');
    return JSON.parse(repaired) as unknown;
  }
};
