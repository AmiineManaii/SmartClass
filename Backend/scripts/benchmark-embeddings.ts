/* eslint-disable no-console */
import { execSync } from 'node:child_process';

interface CorpusDoc {
  id: string;
  subject: string;
  title: string;
  content: string;
}

interface BenchmarkQuery {
  id: string;
  category: 'FR_CONCEPT' | 'EN_CROSS_LINGUAL' | 'AR_AND_DERJA' | 'EXACT_TECHNICAL' | 'OFF_TOPIC';
  query: string;
  expectedDocIds: string[];
}

const EMBEDDING_MODEL = process.env.EMBEDDING_MODEL || 'embeddinggemma-2:270m';
const PRIMARY_LLM = process.env.AI_MODEL || 'gemma4:e4b';
const rawOllamaHost = (process.env.OLLAMA_HOST || 'http://127.0.0.1:11434').replace(/^0\.0\.0\.0/, '127.0.0.1').replace(/^(?!https?:\/\/)/, 'http://');
const OLLAMA_BASE_URL = rawOllamaHost.replace(/\/+$/, '');

const CORPUS: CorpusDoc[] = [
  {
    id: 'ds-intro',
    subject: 'Data Science',
    title: 'Introduction à la Data Science et cycle CRISP-DM',
    content:
      'La Data Science combine statistiques, informatique et expertise métier pour transformer des données brutes en décisions. Le cycle CRISP-DM comprend la compréhension métier, la préparation des données, la modélisation, l’évaluation et le déploiement.',
  },
  {
    id: 'ds-cleaning',
    subject: 'Data Science',
    title: 'Nettoyage et prétraitement des données',
    content:
      'Le nettoyage des données traite les valeurs manquantes (imputation par médiane ou KNN), les valeurs aberrantes, l’encodage one-hot des variables catégorielles et la normalisation Z-score avant d’entraîner un modèle.',
  },
  {
    id: 'ds-supervised',
    subject: 'Data Science',
    title: 'Apprentissage supervisé : Régression linéaire et classification',
    content:
      'En apprentissage supervisé, chaque observation possède un label connu. La régression linéaire prédit une valeur continue en minimisant l’erreur quadratique moyenne par descente de gradient, tandis que la régression logistique classe des probabilités.',
  },
  {
    id: 'ds-overfitting',
    subject: 'Data Science',
    title: 'Surapprentissage (Overfitting) et régularisation L1/L2',
    content:
      'Le surapprentissage survient quand un modèle mémorise le bruit du jeu d’entraînement et généralise mal. On le réduit par validation croisée k-fold, régularisation Ridge (L2) et Lasso (L1), ou arrêt précoce (early stopping).',
  },
  {
    id: 'ds-eval',
    subject: 'Data Science',
    title: 'Métriques d’évaluation : Précision, Rappel, F1-Score et AUC-ROC',
    content:
      'Sur des classes déséquilibrées, l’exactitude (accuracy) est trompeuse. Il faut analyser la matrice de confusion : précision, rappel (sensibilité), score F1 harmonique et aire sous la courbe ROC.',
  },
  {
    id: 'sql-joins',
    subject: 'Bases de Données',
    title: 'Jointures SQL : INNER JOIN, LEFT JOIN et agrégations GROUP BY HAVING',
    content:
      'INNER JOIN ne conserve que les lignes ayant une correspondance dans les deux tables, alors que LEFT JOIN conserve toutes les lignes de la table de gauche même sans correspondance à droite. GROUP BY regroupe les tuples et HAVING filtre les groupes après agrégation COUNT ou SUM.',
  },
  {
    id: 'sql-norm',
    subject: 'Bases de Données',
    title: 'Normalisation relationnelle : 1NF, 2NF, 3NF et BCNF',
    content:
      'Une relation est en troisième forme normale (3NF) si elle est en 2NF et ne contient aucune dépendance transitive entre attributs non clés vers la clé primaire, évitant les anomalies de mise à jour.',
  },
  {
    id: 'sql-indexes',
    subject: 'Bases de Données',
    title: 'Index B-Tree, plans d’exécution EXPLAIN ANALYZE et transactions ACID',
    content:
      'Un index B-Tree accélère les recherches par intervalle et égalité de O(n) à O(log n). Les transactions garantissent Atomicité, Cohérence, Isolation et Durabilité.',
  },
  {
    id: 'algo-complexity',
    subject: 'Algorithmique',
    title: 'Complexité asymptotique : Tri fusion (Merge Sort) et QuickSort',
    content:
      'Le tri fusion divise récursivement le tableau en deux moitiés et fusionne en temps linéaire, garantissant une complexité O(n log n) dans le pire cas. QuickSort a O(n log n) en moyenne mais O(n²) au pire sans bon pivot.',
  },
  {
    id: 'algo-graphs',
    subject: 'Algorithmique',
    title: 'Parcours de graphes BFS, DFS et plus court chemin de Dijkstra',
    content:
      'BFS utilise une file FIFO pour explorer par niveaux et trouver le plus court chemin en graphe non pondéré. L’algorithme de Dijkstra emploie une file de priorité pour calculer les distances minimales à poids positifs.',
  },
  {
    id: 'net-tcp',
    subject: 'Réseaux',
    title: 'Modèle TCP/IP, poignée de main TCP en 3 étapes et HTTP/TLS',
    content:
      'TCP établit une connexion fiable via SYN, SYN-ACK et ACK avant l’échange d’octets. TLS chiffre le canal applicatif HTTP avec négociation de certificats X.509 et clés éphémères ECDHE.',
  },
  {
    id: 'sec-jwt',
    subject: 'Sécurité',
    title: 'Authentification JWT, hachage Argon2id et rotation des refresh tokens',
    content:
      'Les mots de passe doivent être hachés avec Argon2id et jamais stockés en clair. Les JWT d’accès sont à courte durée (15 min) et les refresh tokens opaques sont hachés et rotatifs avec détection de réutilisation.',
  },
];

const QUERIES: BenchmarkQuery[] = [
  // 8 FR conceptual / synonym queries
  { id: 'fr-1', category: 'FR_CONCEPT', query: 'Comment éviter qu’un modèle mémorise trop les données d’entraînement ?', expectedDocIds: ['ds-overfitting'] },
  { id: 'fr-2', category: 'FR_CONCEPT', query: 'Que faire quand il manque des valeurs dans un dataset ?', expectedDocIds: ['ds-cleaning'] },
  { id: 'fr-3', category: 'FR_CONCEPT', query: 'Quelle métrique choisir quand une classe est très rare ?', expectedDocIds: ['ds-eval'] },
  { id: 'fr-4', category: 'FR_CONCEPT', query: 'Comment sécuriser le stockage des mots de passe utilisateurs ?', expectedDocIds: ['sec-jwt'] },
  { id: 'fr-5', category: 'FR_CONCEPT', query: 'Comment trouver le chemin le plus court avec des poids positifs dans un graphe ?', expectedDocIds: ['algo-graphs'] },
  { id: 'fr-6', category: 'FR_CONCEPT', query: 'À quoi sert la poignée de main SYN ACK sur le réseau ?', expectedDocIds: ['net-tcp'] },
  { id: 'fr-7', category: 'FR_CONCEPT', query: 'Quelles sont les étapes du processus CRISP-DM en Data Science ?', expectedDocIds: ['ds-intro'] },
  { id: 'fr-8', category: 'FR_CONCEPT', query: 'Quelle différence entre régression linéaire et régression logistique ?', expectedDocIds: ['ds-supervised'] },

  // 5 EN cross-lingual queries against FR corpus
  { id: 'en-1', category: 'EN_CROSS_LINGUAL', query: 'How to handle missing values and outliers before training?', expectedDocIds: ['ds-cleaning'] },
  { id: 'en-2', category: 'EN_CROSS_LINGUAL', query: 'Explain the difference between LEFT JOIN and INNER JOIN in SQL', expectedDocIds: ['sql-joins'] },
  { id: 'en-3', category: 'EN_CROSS_LINGUAL', query: 'What is overfitting and how do L1 L2 regularization help?', expectedDocIds: ['ds-overfitting'] },
  { id: 'en-4', category: 'EN_CROSS_LINGUAL', query: 'Worst case time complexity of Merge Sort versus QuickSort', expectedDocIds: ['algo-complexity'] },
  { id: 'en-5', category: 'EN_CROSS_LINGUAL', query: 'What guarantees ACID properties and B-Tree database indexing?', expectedDocIds: ['sql-indexes'] },

  // 5 Standard Arabic & Tunisian Derja / Arabizi queries
  { id: 'ar-1', category: 'AR_AND_DERJA', query: 'ما هو التعلم الخاضع للإشراف والانحدار الخطي؟', expectedDocIds: ['ds-supervised'] },
  { id: 'ar-2', category: 'AR_AND_DERJA', query: 'كيف نتعامل مع القيم المفقودة وتنظيف البيانات؟', expectedDocIds: ['ds-cleaning'] },
  { id: 'ar-3', category: 'AR_AND_DERJA', query: 'kifech naamlou nettoyage des donnees ki yabda fama valeurs manquantes?', expectedDocIds: ['ds-cleaning'] },
  { id: 'ar-4', category: 'AR_AND_DERJA', query: 'chnoua lfarq bin INNER JOIN w LEFT JOIN fi SQL?', expectedDocIds: ['sql-joins'] },
  { id: 'ar-5', category: 'AR_AND_DERJA', query: 'kifech nnaqsou ml overfitting fi apprentissage automatique?', expectedDocIds: ['ds-overfitting'] },

  // 4 Exact technical symbol / formula queries
  { id: 'tech-1', category: 'EXACT_TECHNICAL', query: '3NF BCNF dépendance transitive', expectedDocIds: ['sql-norm'] },
  { id: 'tech-2', category: 'EXACT_TECHNICAL', query: 'GROUP BY HAVING COUNT', expectedDocIds: ['sql-joins'] },
  { id: 'tech-3', category: 'EXACT_TECHNICAL', query: 'O(n log n) B-Tree EXPLAIN ANALYZE', expectedDocIds: ['sql-indexes', 'algo-complexity'] },
  { id: 'tech-4', category: 'EXACT_TECHNICAL', query: 'Argon2id ECDHE', expectedDocIds: ['sec-jwt', 'net-tcp'] },

  // 3 Off-topic negative queries (used to observe max similarity for calibration)
  { id: 'neg-1', category: 'OFF_TOPIC', query: 'Recette traditionnelle du couscous tunisien aux légumes', expectedDocIds: [] },
  { id: 'neg-2', category: 'OFF_TOPIC', query: 'Calendrier des matchs de la Ligue des Champions UEFA', expectedDocIds: [] },
  { id: 'neg-3', category: 'OFF_TOPIC', query: 'Comment réparer une fuite de radiateur automobile', expectedDocIds: [] },
];

const cosine = (a: number[], b: number[]): number => {
  let dot = 0;
  let na = 0;
  let nb = 0;
  for (let i = 0; i < a.length; i++) {
    const va = a[i] ?? 0;
    const vb = b[i] ?? 0;
    dot += va * vb;
    na += va * va;
    nb += vb * vb;
  }
  return na > 0 && nb > 0 ? dot / (Math.sqrt(na) * Math.sqrt(nb)) : 0;
};

const normalizeTerms = (text: string): string[] =>
  text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .split(/[^a-z0-9\u0600-\u06ff]+/)
    .filter((t) => t.length >= 2);

const ftsOverlapScore = (query: string, docText: string): number => {
  const qTerms = [...new Set(normalizeTerms(query))];
  const docSet = new Set(normalizeTerms(docText));
  if (qTerms.length === 0) return 0;
  let hits = 0;
  for (const term of qTerms) {
    if (docSet.has(term)) hits++;
  }
  return hits / qTerms.length;
};

const embedCpu = async (inputs: string[]): Promise<{ embeddings: number[][]; elapsedMs: number }> => {
  const t0 = performance.now();
  const res = await fetch(`${OLLAMA_BASE_URL}/api/embed`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      model: EMBEDDING_MODEL,
      input: inputs,
      options: { num_gpu: 0 },
    }),
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`Ollama /api/embed HTTP ${res.status}: ${txt}`);
  }
  const body = (await res.json()) as { embeddings?: number[][] };
  const elapsedMs = Math.round(performance.now() - t0);
  const embeddings = body.embeddings ?? [];
  if (embeddings.length !== inputs.length) {
    throw new Error(`Expected ${inputs.length} embeddings, got ${embeddings.length}`);
  }
  for (const vec of embeddings) {
    if (!Array.isArray(vec) || vec.length !== 768) {
      throw new Error(`Invalid dimension: expected 768, got ${Array.isArray(vec) ? vec.length : 'null'}`);
    }
  }
  return { embeddings, elapsedMs };
};

const safeShell = (cmd: string): string => {
  try {
    return execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  } catch (err) {
    return err instanceof Error ? err.message : 'unavailable';
  }
};

const percentile = (sorted: number[], p: number): number => {
  if (sorted.length === 0) return 0;
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[idx] ?? 0;
};

async function main(): Promise<void> {
  // 1. Verify embedding model tag & GPU warming with gemma4:e4b
  const tagsRes = await fetch(`${OLLAMA_BASE_URL}/api/tags`);
  const tagsJson = (await tagsRes.json()) as { models?: Array<{ name: string; size?: number }> };
  const installedTags = (tagsJson.models ?? []).map((m) => m.name);
  if (!installedTags.includes(EMBEDDING_MODEL)) {
    throw new Error(`Model ${EMBEDDING_MODEL} not found in Ollama. Installed: ${installedTags.join(', ')}`);
  }

  // Warm primary LLM on GPU so we prove embeddinggemma-2:270m CPU mode does not evict it
  const warmRes = await fetch(`${OLLAMA_BASE_URL}/api/chat`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      model: PRIMARY_LLM,
      messages: [{ role: 'user', content: 'Say OK.' }],
      stream: false,
      options: { num_predict: 8, num_ctx: 8192, use_mmap: true },
    }),
  });
  if (!warmRes.ok) {
    const errText = await warmRes.text().catch(() => '');
    throw new Error(`Failed warming ${PRIMARY_LLM} on GPU: HTTP ${warmRes.status} ${errText}`);
  }
  const vramBefore = safeShell('nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader');
  const psBefore = safeShell('ollama ps');

  // 2. Embed corpus & measure 20 sequential single-query + 50-chunk batch CPU latencies
  const corpusInputs = CORPUS.map((d) => `[Matière: ${d.subject} | Titre: ${d.title}]\n${d.content}`);
  const corpusEmbed = await embedCpu(corpusInputs);

  const singleLatencies: number[] = [];
  const queryVectors: Map<string, number[]> = new Map();
  for (const q of QUERIES.slice(0, 20)) {
    const res = await embedCpu([q.query]);
    singleLatencies.push(res.elapsedMs);
    queryVectors.set(q.id, res.embeddings[0]!);
  }
  for (const q of QUERIES.slice(20)) {
    const res = await embedCpu([q.query]);
    queryVectors.set(q.id, res.embeddings[0]!);
  }

  const batch50Inputs = Array.from({ length: 50 }, (_, i) => {
    const doc = CORPUS[i % CORPUS.length]!;
    return `[Chunk #${i + 1} | ${doc.title}] ${doc.content}`;
  });
  const batch50 = await embedCpu(batch50Inputs);

  const vramAfter = safeShell('nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader');
  const psAfter = safeShell('ollama ps');

  // 3. Evaluate Vector-only vs FTS-only vs Hybrid RRF (0.65 / 0.35)
  const sortedSingle = [...singleLatencies].sort((a, b) => a - b);
  const meanSingle = Math.round(sortedSingle.reduce((s, n) => s + n, 0) / sortedSingle.length);

  type ModeKey = 'vectorOnly' | 'ftsOnly' | 'hybridRrf';
  const metrics: Record<ModeKey, { recall5Sum: number; mrr5Sum: number; positiveCount: number }> = {
    vectorOnly: { recall5Sum: 0, mrr5Sum: 0, positiveCount: 0 },
    ftsOnly: { recall5Sum: 0, mrr5Sum: 0, positiveCount: 0 },
    hybridRrf: { recall5Sum: 0, mrr5Sum: 0, positiveCount: 0 },
  };
  const perCategory: Record<string, { count: number; vecRecall5: number; hybRecall5: number; vecMrr5: number; hybMrr5: number }> = {};
  const offTopicMaxVec: number[] = [];
  const positiveTopVec: number[] = [];

  for (const q of QUERIES) {
    const qVec = queryVectors.get(q.id)!;

    const vecRanked = CORPUS.map((doc, idx) => ({
      id: doc.id,
      score: cosine(qVec, corpusEmbed.embeddings[idx]!),
    })).sort((a, b) => b.score - a.score);

    const ftsRanked = CORPUS.map((doc) => ({
      id: doc.id,
      score: ftsOverlapScore(q.query, `${doc.subject} ${doc.title} ${doc.content}`),
    })).sort((a, b) => b.score - a.score);

    if (q.category === 'OFF_TOPIC') {
      offTopicMaxVec.push(Number((vecRanked[0]?.score ?? 0).toFixed(4)));
      continue;
    }

    positiveTopVec.push(Number((vecRanked[0]?.score ?? 0).toFixed(4)));

    const vecRankMap = new Map(vecRanked.map((item, i) => [item.id, i + 1]));
    const ftsRankMap = new Map(
      ftsRanked.filter((item) => item.score > 0).map((item, i) => [item.id, i + 1]),
    );

    const hybridRanked = CORPUS.map((doc) => {
      const rVec = vecRankMap.get(doc.id);
      const rFts = ftsRankMap.get(doc.id);
      const score = (rVec ? 0.65 / (60 + rVec) : 0) + (rFts ? 0.35 / (60 + rFts) : 0);
      return { id: doc.id, score };
    }).sort((a, b) => b.score - a.score);

    const evalRanking = (ids: string[]) => {
      const top5 = ids.slice(0, 5);
      const matched = q.expectedDocIds.some((exp) => top5.includes(exp)) ? 1 : 0;
      const firstRank = top5.findIndex((id) => q.expectedDocIds.includes(id));
      const rr = firstRank >= 0 ? 1 / (firstRank + 1) : 0;
      return { matched, rr };
    };

    const vRes = evalRanking(vecRanked.map((x) => x.id));
    const fRes = evalRanking(ftsRanked.filter((x) => x.score > 0).map((x) => x.id));
    const hRes = evalRanking(hybridRanked.map((x) => x.id));

    metrics.vectorOnly.recall5Sum += vRes.matched;
    metrics.vectorOnly.mrr5Sum += vRes.rr;
    metrics.vectorOnly.positiveCount++;

    metrics.ftsOnly.recall5Sum += fRes.matched;
    metrics.ftsOnly.mrr5Sum += fRes.rr;
    metrics.ftsOnly.positiveCount++;

    metrics.hybridRrf.recall5Sum += hRes.matched;
    metrics.hybridRrf.mrr5Sum += hRes.rr;
    metrics.hybridRrf.positiveCount++;

    const cat = perCategory[q.category] ?? { count: 0, vecRecall5: 0, hybRecall5: 0, vecMrr5: 0, hybMrr5: 0 };
    cat.count++;
    cat.vecRecall5 += vRes.matched;
    cat.hybRecall5 += hRes.matched;
    cat.vecMrr5 += vRes.rr;
    cat.hybMrr5 += hRes.rr;
    perCategory[q.category] = cat;
  }

  const summarizeMode = (m: { recall5Sum: number; mrr5Sum: number; positiveCount: number }) => ({
    recallAt5: Number((m.recall5Sum / Math.max(1, m.positiveCount)).toFixed(4)),
    mrrAt5: Number((m.mrr5Sum / Math.max(1, m.positiveCount)).toFixed(4)),
  });

  const report = {
    embeddingModel: EMBEDDING_MODEL,
    verifiedDimension: 768,
    numGpu: 0,
    latencyMs: {
      singleQueryCount: sortedSingle.length,
      meanMs: meanSingle,
      p50Ms: percentile(sortedSingle, 50),
      p95Ms: percentile(sortedSingle, 95),
      batch12CorpusMs: corpusEmbed.elapsedMs,
      batch50ChunksMs: batch50.elapsedMs,
      batch50PerChunkMs: Number((batch50.elapsedMs / 50).toFixed(2)),
    },
    gpuCoexistence: {
      primaryLlm: PRIMARY_LLM,
      vramBeforeEmbeddings: vramBefore,
      vramAfterEmbeddings: vramAfter,
      ollamaPsBefore: psBefore,
      ollamaPsAfter: psAfter,
    },
    retrievalQuality22PositiveQueries: {
      vectorOnly: summarizeMode(metrics.vectorOnly),
      ftsOnly: summarizeMode(metrics.ftsOnly),
      hybridRrf: summarizeMode(metrics.hybridRrf),
      byCategory: Object.fromEntries(
        Object.entries(perCategory).map(([k, v]) => [
          k,
          {
            queries: v.count,
            vectorRecall5: Number((v.vecRecall5 / v.count).toFixed(4)),
            vectorMrr5: Number((v.vecMrr5 / v.count).toFixed(4)),
            hybridRecall5: Number((v.hybRecall5 / v.count).toFixed(4)),
            hybridMrr5: Number((v.hybMrr5 / v.count).toFixed(4)),
          },
        ]),
      ),
      similarityCalibration: {
        positiveMinTopCosine: Math.min(...positiveTopVec),
        positiveMeanTopCosine: Number(
          (positiveTopVec.reduce((a, b) => a + b, 0) / positiveTopVec.length).toFixed(4),
        ),
        offTopicMaxCosines: offTopicMaxVec,
      },
    },
  };

  console.log(JSON.stringify(report, null, 2));
}

main().catch((err) => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
