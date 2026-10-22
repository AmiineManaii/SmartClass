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
   * Search Wikimedia Commons and open educational repositories for authentic diagrams,
   * scientific schematics, historical photos, and verified educational visuals.
   */
  public async searchImages(query: string, limit: number = 5): Promise<ImageSearchResult[]> {
    const trimmed = query.trim();
    if (!trimmed) return [];

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
      url.searchParams.set('origin', '*');

      const response = await fetch(url.toString(), {
        headers: { 'User-Agent': 'SmartClassApp/1.0 (educational; contact@smartclass.local)' },
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });

      if (!response.ok) {
        logger.warn({ status: response.status, query: trimmed }, 'Wikimedia Commons search returned non-200');
        return [];
      }

      const data = (await response.json()) as {
        query?: {
          pages?: Record<
            string,
            {
              title?: string;
              imageinfo?: Array<{
                url?: string;
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

        const rawFileUrl = info.url;
        const cleanUrl = rawFileUrl.split('?')[0] ?? '';
        const ext = cleanUrl.split('.').pop()?.toLowerCase();
        if (!ext || !['jpg', 'jpeg', 'png', 'svg', 'webp'].includes(ext)) {
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

      logger.info({ query: trimmed, count: results.length }, 'Educational image search completed');
      return results;
    } catch (error) {
      logger.warn({ query: trimmed, error: (error as Error).message }, 'Image search failed');
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
