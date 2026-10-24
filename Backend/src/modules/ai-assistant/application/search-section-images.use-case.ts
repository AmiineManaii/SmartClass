import { getEnv } from '../../../config/env.js';
import { NotFoundError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type { Role } from '../../auth/index.js';
import type { CourseSectionRepositoryPort } from '../../courses/domain/course-section-repository.port.js';
import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import type { ImageSearchResult, SearchPort } from '../domain/search.port.js';
import type { AiGatewayPort } from '../domain/ai-gateway.port.js';
import { loadOwnedCourse } from './course-access.js';

export interface SearchSectionImagesDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
  sectionKey: string;
  /** Optional teacher refinement; defaults to the section title/topics. */
  query?: string;
  count?: number;
}

export type SearchSectionImagesResult = {
  query: string;
  images: ImageSearchResult[];
  urls?: string[];
  query_used?: string;
};

/**
 * REFORMULATION_SYSTEM_PROMPT pour le modèle Lucy via Ollama.
 * Lucy sert UNIQUEMENT à transformer les mots-clés bruts en requête de recherche
 * optimisée (termes techniques, anglais si pertinent, 4 à 8 mots-clés).
 * Lucy ne génère JAMAIS d'URLs.
 */
const REFORMULATION_SYSTEM_PROMPT = `Tu es un assistant qui transforme une description de section de cours en requête de
recherche d'images efficace.

Règles :
- Réponds UNIQUEMENT par la requête finale, en mots-clés.
- Pas de phrase, pas de ponctuation finale, pas de guillemets, pas d'explication.
- 4 à 8 mots-clés maximum.
- Traduis en anglais si les termes techniques anglais sont plus courants.
- Ajoute le contexte technique pertinent (ex: "database", "diagram", "schema", "tutorial").
- Exemple : "modélisation conceptuelle base de données" → "conceptual database model ER diagram schema"

Ne réponds jamais autre chose que la requête.`;

export class SearchSectionImagesUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly sectionRepository: CourseSectionRepositoryPort,
    private readonly search: SearchPort,
    private readonly gateway?: AiGatewayPort,
  ) {}

  public async execute(dto: SearchSectionImagesDTO): Promise<SearchSectionImagesResult> {
    const course = await loadOwnedCourse(this.courses, dto);
    const section = await this.sectionRepository.findByKey(dto.courseId, dto.sectionKey);
    if (!section) {
      throw new NotFoundError('Course section not found');
    }

    // Si count est spécifié (1 à 50), l'utiliser ; sinon renvoyer jusqu'à 50 résultats (tous les résultats trouvés par SearxNG)
    const count = dto.count && dto.count >= 1 ? Math.min(dto.count, 50) : 50;

    // Contexte brut envoyé : mots-clés / description + titre de la section
    const rawKeywords = dto.query?.trim() || [section.description, ...section.keyTopics].filter(Boolean).join(' ').trim() || section.title;
    const rawSection = section.title;

    logger.info(
      { section: rawSection, keywords: rawKeywords, count },
      '[SearchSectionImages] Reçu demande de recherche d\'images',
    );

    // 1. Reformulation via Ollama (Lucy)
    const reformulatedQuery = await this.reformulateQuery(rawSection, rawKeywords);
    logger.info({ sectionKey: dto.sectionKey, query_used: reformulatedQuery }, '[SearchSectionImages] Query reformulée');

    // 2. Recherche d'images via SearxNG (avec fallbacks automatiques dans searchImages)
    const images = await this.search.searchImages(reformulatedQuery, count);

    logger.info(
      { query_used: reformulatedQuery, count: images.length },
      '[SearchSectionImages] Images trouvées',
    );

    const urls = images.map((img) => img.url);

    return {
      query: reformulatedQuery,
      query_used: reformulatedQuery,
      images,
      urls,
    };
  }

  /**
   * Reformule les mots-clés via Ollama (Lucy).
   * Fallback strict : si Ollama échoue ou renvoie vide, utilise `${section} ${keywords}` brut.
   */
  private async reformulateQuery(section: string, keywords: string): Promise<string> {
    const fallback = `${section} ${keywords}`.replace(/\s+/g, ' ').trim().slice(0, 200);
    const env = getEnv();
    const ollamaUrl = env.AI_BASE_URL.replace(/\/+$/, '');
    const model = env.OLLAMA_REFORMULATE_MODEL || 'sam860/lucy:1.7b';

    try {
      const response = await fetch(`${ollamaUrl}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model,
          messages: [
            { role: 'system', content: REFORMULATION_SYSTEM_PROMPT },
            { role: 'user', content: `Section: ${section}\nDescription: ${keywords}` },
          ],
          stream: false,
          options: {
            temperature: 0.2,
            num_predict: 60,
          },
        }),
        signal: AbortSignal.timeout(10_000),
      });

      if (!response.ok) {
        logger.warn({ status: response.status, model }, '[Ollama Lucy] Erreur HTTP, utilisation du fallback');
        return fallback;
      }

      const data = (await response.json()) as { message?: { content?: string } };
      const rawContent = data.message?.content || '';
      const cleaned = this.cleanQuery(rawContent);

      if (!cleaned) {
        logger.warn('[Ollama Lucy] Réponse vide, utilisation du fallback');
        return fallback;
      }

      return cleaned;
    } catch (err) {
      logger.warn({ error: (err as Error).message }, '[Ollama Lucy] Échec appel, utilisation du fallback');
      return fallback;
    }
  }

  private cleanQuery(text: string): string {
    return text
      .replace(/["'«»`]/g, ' ')
      .replace(/[\r\n\t]+/g, ' ')
      .replace(/[.;:!?]+$/g, '')
      .replace(/\s+/g, ' ')
      .trim()
      .slice(0, 200);
  }
}


