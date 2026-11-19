export interface ExamAiPromptInput {
  title: string;
  subject: string | null;
  difficulty: 'facile' | 'moyen' | 'difficile';
  questionCount: number;
  courses: { title: string; subject: string | null; content: string }[];
  maxSourceChars: number;
}

const difficultyGuidance: Record<ExamAiPromptInput['difficulty'], string> = {
  facile: 'questions de compréhension directe, une seule notion par question',
  moyen: 'questions d’application qui demandent de relier deux notions du cours',
  difficile: 'questions d’analyse qui exigent de raisonner sur les notions du cours',
};

export const buildExamPrompt = (input: ExamAiPromptInput): { system: string; user: string } => {
  let remaining = Math.max(2000, input.maxSourceChars);
  const sources: string[] = [];
  for (const course of input.courses) {
    if (remaining <= 0) break;
    const content = course.content.replace(/\s+/g, ' ').trim().slice(0, remaining);
    remaining -= content.length;
    sources.push(
      `### Cours : ${course.title}${course.subject ? ` (${course.subject})` : ''}\n${content}`,
    );
  }

  const system = [
    'Tu es un enseignant qui rédige un contrôle pour sa classe.',
    'RÈGLES ABSOLUES :',
    '1. Utilise UNIQUEMENT les cours fournis par l’enseignant ci-dessous.',
    '2. N’invente aucune notion, aucun chiffre, aucune définition absente des cours.',
    '3. Chaque question est à choix unique avec exactement 4 propositions et une seule bonne réponse.',
    '4. La bonne réponse doit être justifiable directement par le texte du cours.',
    '5. Réponds uniquement avec un objet JSON valide, sans markdown, sans commentaire.',
    'Schéma attendu :',
    '{"title":"...","questions":[{"prompt":"...","hint":null,"options":["...","...","...","..."],"correctOptionId":"A","explanation":"...","points":1}]}',
  ].join('\n');

  const user = [
    `Titre souhaité : ${input.title}`,
    input.subject ? `Matière : ${input.subject}` : '',
    `Nombre de questions : ${input.questionCount}`,
    `Niveau : ${difficultyGuidance[input.difficulty]}`,
    '',
    'CONTENU DES COURS DE LA CLASSE (source unique autorisée) :',
    sources.join('\n\n'),
    '',
    'Génère maintenant le JSON demandé. Les identifiants de bonnes réponses sont A, B, C ou D.',
  ]
    .filter((line) => line !== '')
    .join('\n');

  return { system, user };
};

export const extractJsonPayload = (content: string): unknown => {
  const trimmed = content.trim();
  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  const candidate = fenced?.[1] ? fenced[1].trim() : trimmed;
  const start = candidate.indexOf('{');
  const end = candidate.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw new Error('No JSON object found in the model output');
  }
  return JSON.parse(candidate.slice(start, end + 1)) as unknown;
};
