import { getEnv } from '../../../config/env.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type {
  ImageSearchResult,
  SearchPort,
  WebSearchResult,
} from '../domain/search.port.js';

const TIMEOUT_MS = 7_000;
const USER_AGENT =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 SmartClass/1.0';

export class HybridSearchAdapter implements SearchPort {
  /**
   * Search the web for up-to-date information, course materials, facts, and code examples.
   * Prioritizes Ollama Official Search API when OLLAMA_API_KEY is configured;
   * otherwise seamlessly falls back to DuckDuckGo (100% free, zero configuration).
   */
  public async searchWeb(query: string, limit: number = 5): Promise<WebSearchResult[]> {
    const trimmed = query.trim();
    if (!trimmed) return [];

    const env = getEnv();
    if (env.OLLAMA_API_KEY?.trim()) {
      try {
        const ollamaResults = await this.searchOllamaApi(trimmed, env.OLLAMA_API_KEY.trim(), limit);
        if (ollamaResults.length > 0) {
          logger.info({ query: trimmed, count: ollamaResults.length }, 'Web search via Ollama API succeeded');
          return ollamaResults;
        }
      } catch (err) {
        logger.warn(
          { query: trimmed, error: (err as Error).message },
          'Ollama search failed, falling back to DuckDuckGo',
        );
      }
    }

    return this.searchDuckDuckGo(trimmed, limit);
  }

  /**
   * Search SearxNG (primary), Wikimedia Commons, or DuckDuckGo for authentic diagrams,
   * scientific schematics, historical photos, and verified educational visuals.
   */
  public async searchImages(query: string, limit: number = 5): Promise<ImageSearchResult[]> {
    const trimmed = query.trim();
    if (!trimmed) return [];

    const env = getEnv();

    // 1. Priorité à SearxNG (notre moteur local dédié, multi-sources)
    if (env.SEARXNG_URL) {
      try {
        const searxImages = await this.searchSearxngImages(trimmed, limit, env.SEARXNG_URL);
        if (searxImages.length > 0) {
          logger.info({ query: trimmed, count: searxImages.length }, 'Educational image search completed (SearxNG)');
          return searxImages;
        }
      } catch (err) {
        logger.warn({ query: trimmed, error: (err as Error).message }, 'SearxNG image search failed, trying fallbacks');
      }
    }

    // 2. Wikimedia Commons
    try {
      const url = new URL('https://commons.wikimedia.org/w/api.php');
      url.searchParams.set('action', 'query');
      url.searchParams.set('format', 'json');
      url.searchParams.set('generator', 'search');
      url.searchParams.set('gsrsearch', trimmed);
      url.searchParams.set('gsrnamespace', '6'); // File namespace
      url.searchParams.set('gsrlimit', String(Math.max(limit * 2, 6)));
      url.searchParams.set('prop', 'imageinfo');
      url.searchParams.set('iiprop', 'url|mime|extmetadata|dimensions');
      // Raster thumbnail: Flutter cannot render SVG, Wikimedia can.
      url.searchParams.set('iiurlwidth', '1024');
      url.searchParams.set('origin', '*');

      const response = await fetch(url.toString(), {
        headers: { 'User-Agent': 'SmartClassApp/1.0 (educational; contact@smartclass.local)' },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });

      if (!response.ok) {
        logger.warn({ status: response.status, query: trimmed }, 'Wikimedia Commons search returned non-200');
      } else {
        const data = (await response.json()) as {
          query?: {
            pages?: Record<
              string,
              {
                title?: string;
                imageinfo?: Array<{
                  url?: string;
                  thumburl?: string;
                  mime?: string;
                  width?: number;
                  height?: number;
                  extmetadata?: {
                    ImageDescription?: { value?: string };
                  };
                }>;
              }
            >;
          };
        };

        const pages = Object.values(data.query?.pages ?? {});
        const results: ImageSearchResult[] = [];

        for (const page of pages) {
          if (results.length >= limit) break;
          const info = page.imageinfo?.[0];
          if (!info?.url) continue;

          // Prefer the 1024px raster thumbnail (works for SVG sources too).
          const rawFileUrl = info.thumburl ?? info.url;
          const cleanUrl = rawFileUrl.split('?')[0] ?? '';
          const ext = cleanUrl.split('.').pop()?.toLowerCase();
          if (!ext || !['jpg', 'jpeg', 'png', 'webp'].includes(ext)) {
            continue;
          }

          const rawTitle = page.title?.replace(/^File:/, '').replace(/\.[^.]+$/, '').replace(/_/g, ' ') ?? '';
          const rawDesc = info.extmetadata?.ImageDescription?.value ?? rawTitle;
          const cleanDesc = rawDesc.replace(/<[^>]+>/g, '').trim().slice(0, 160);

          results.push({
            title: rawTitle,
            url: cleanUrl,
            caption: cleanDesc || rawTitle,
            source: 'wikimedia',
            width: info.width,
            height: info.height,
          });
        }

        if (results.length > 0) {
          logger.info({ query: trimmed, count: results.length }, 'Educational image search completed (Wikimedia)');
          return results;
        }
      }
    } catch (error) {
      logger.warn({ query: trimmed, error: (error as Error).message }, 'Wikimedia image search failed');
    }

    // 3. Fallback: Recherche d'images via DuckDuckGo Images
    try {
      const ddgImages = await this.searchDuckDuckGoImages(trimmed, limit);
      if (ddgImages.length > 0) {
        logger.info({ query: trimmed, count: ddgImages.length }, 'Image search completed (DuckDuckGo Images)');
        return ddgImages;
      }
    } catch (err) {
      logger.warn({ query: trimmed, error: (err as Error).message }, 'DuckDuckGo image search failed');
    }

    return [];
  }

  /**
   * Recherche d'images via SearxNG (JSON format).
   */
  public async searchSearxngImages(query: string, limit: number, searxngBaseUrl: string): Promise<ImageSearchResult[]> {
    const baseUrl = searxngBaseUrl.replace(/\/+$/, '');
    const url = `${baseUrl}/search?q=${encodeURIComponent(query)}&categories=images&format=json`;

    const response = await fetch(url, {
      headers: {
        'Accept': 'application/json',
        'User-Agent': USER_AGENT,
      },
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });

    if (!response.ok) {
      throw new Error(`SearxNG HTTP ${response.status}`);
    }

    const data = (await response.json()) as {
      results?: Array<{
        title?: string;
        img_src?: string;
        url?: string;
        thumbnail_src?: string;
        width?: number;
        height?: number;
      }>;
    };

    const results = Array.isArray(data.results) ? data.results : [];
    const images: ImageSearchResult[] = [];
    const seen = new Set<string>();

    for (const item of results) {
      const imgUrl = item.img_src || item.url || item.thumbnail_src;
      if (!imgUrl || !imgUrl.startsWith('http') || seen.has(imgUrl)) continue;

      seen.add(imgUrl);
      images.push({
        title: item.title?.replace(/<[^>]+>/g, '').trim() || 'Illustration web',
        url: imgUrl,
        caption: item.title?.replace(/<[^>]+>/g, '').trim() || 'Image trouvée sur le web',
        source: 'web',
        width: item.width,
        height: item.height,
      });

      if (images.length >= limit) break;
    }

    return images;
  }

  /**
   * Recherche directe d'images réelles sur le Web via DuckDuckGo Images.
   */
  private async searchDuckDuckGoImages(query: string, limit: number): Promise<ImageSearchResult[]> {
    try {
      // 1. Obtenir le vqd token de DuckDuckGo
      const tokenRes = await fetch(`https://duckduckgo.com/?q=${encodeURIComponent(query)}&iax=images&ia=images`, {
        headers: { 'User-Agent': USER_AGENT },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
      if (!tokenRes.ok) return [];
      const tokenHtml = await tokenRes.text();
      const vqdMatch = tokenHtml.match(/vqd=["']?([^&"'\s]+)/);
      if (!vqdMatch || !vqdMatch[1]) return [];
      const vqd = vqdMatch[1];

      // 2. Requête vers l'API JSON images de DuckDuckGo
      const imgRes = await fetch(`https://duckduckgo.com/i.js?q=${encodeURIComponent(query)}&o=json&vqd=${vqd}&p=1`, {
        headers: {
          'User-Agent': USER_AGENT,
          'Accept': 'application/json',
          'Referer': 'https://duckduckgo.com/',
        },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
      if (!imgRes.ok) return [];

      const imgData = (await imgRes.json()) as {
        results?: Array<{ title?: string; image?: string; thumbnail?: string; width?: number; height?: number }>;
      };

      const images: ImageSearchResult[] = [];
      for (const item of imgData.results ?? []) {
        if (images.length >= limit) break;
        const imgUrl = item.image || item.thumbnail;
        if (!imgUrl || !imgUrl.startsWith('http')) continue;
        images.push({
          title: item.title?.replace(/<[^>]+>/g, '').trim() || 'Illustration web',
          url: imgUrl,
          caption: item.title?.replace(/<[^>]+>/g, '').trim() || 'Image trouvée sur le web',
          source: 'web',
          width: item.width,
          height: item.height,
        });
      }
      return images;
    } catch {
      return [];
    }
  }

  /**
   * Free, zero-configuration web search via DuckDuckGo.
   */
  private async searchDuckDuckGo(query: string, limit: number): Promise<WebSearchResult[]> {
    try {
      const response = await fetch(`https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`, {
        headers: {
          'User-Agent': USER_AGENT,
          'Accept-Language': 'fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7',
        },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });

      if (!response.ok) {
        logger.warn({ status: response.status, query }, 'DuckDuckGo search returned non-200');
        return [];
      }

      const html = await response.text();
      const results: WebSearchResult[] = [];
      const parts = html.split(/class="[^"]*result__body[^"]*"/);

      for (let i = 1; i < parts.length && results.length < limit; i++) {
        const block = parts[i];
        if (!block) continue;

        const linkMatch = /<a[^>]+class="result__a"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/.exec(block);
        const snippetMatch = /<a[^>]+class="result__snippet"[^>]*>([\s\S]*?)<\/a>/.exec(block);

        if (linkMatch && linkMatch[1] && linkMatch[2]) {
          let rawUrl = linkMatch[1];
          if (rawUrl.includes('uddg=')) {
            try {
              const parsed = new URL(rawUrl.startsWith('//') ? `https:${rawUrl}` : rawUrl);
              rawUrl = decodeURIComponent(parsed.searchParams.get('uddg') ?? rawUrl);
            } catch {
              // Ignore URL parse error
            }
          }

          const title = linkMatch[2].replace(/<[^>]+>/g, '').trim();
          const snippet = snippetMatch && snippetMatch[1] ? snippetMatch[1].replace(/<[^>]+>/g, '').trim() : '';

          if (title && rawUrl.startsWith('http')) {
            results.push({ title, url: rawUrl, snippet });
          }
        }
      }

      logger.info({ query, count: results.length }, 'DuckDuckGo web search completed');
      return results;
    } catch (error) {
      logger.warn({ query, error: (error as Error).message }, 'DuckDuckGo web search failed');
      return [];
    }
  }

  /**
   * Official Ollama Cloud Search API integration.
   */
  private async searchOllamaApi(query: string, apiKey: string, limit: number): Promise<WebSearchResult[]> {
    const response = await fetch('https://ollama.com/api/web_search', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
        'User-Agent': USER_AGENT,
      },
      body: JSON.stringify({ query, limit }),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });

    if (!response.ok) {
      throw new Error(`Ollama API responded with status ${response.status}`);
    }

    const data = (await response.json()) as {
      results?: Array<{ title?: string; url?: string; snippet?: string; content?: string }>;
    };

    return (data.results ?? []).slice(0, limit).map((r) => ({
      title: r.title ?? 'Untitled',
      url: r.url ?? '',
      snippet: r.snippet ?? r.content ?? '',
    }));
  }
}
