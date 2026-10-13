import { ServiceUnavailableError, ValidationError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type { FetchedUrl, UrlFetcherPort } from '../domain/url-fetcher.port.js';

const FETCH_TIMEOUT_MS = 20000;
const MAX_HTML_BYTES = 2_000_000;

/** Dependency-free HTML → text extraction (scripts, styles and tags stripped). */
export const htmlToText = (html: string): { title: string | null; text: string } => {
  const title = /<title[^>]*>([\s\S]{0,300})<\/title>/i.exec(html)?.[1]?.trim() || null;
  const withoutScripts = html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<!--[\s\S]*?-->/g, ' ');
  const text = withoutScripts
    .replace(/<\/(p|div|h[1-6]|li|tr|br)[^>]*>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&(nbsp|amp|lt|gt|quot|apos);/g, (entity) => {
      switch (entity) {
        case '&nbsp;':
          return ' ';
        case '&amp;':
          return '&';
        case '&lt;':
          return '<';
        case '&gt;':
          return '>';
        case '&quot;':
          return '"';
        default:
          return "'";
      }
    })
    .split('\n')
    .map((line) => line.replace(/[ \t]+/g, ' ').trim())
    .filter((line) => line.length > 0)
    .join('\n');
  return { title, text };
};

export class NativeUrlFetcher implements UrlFetcherPort {
  public async fetchText(url: string): Promise<FetchedUrl> {
    let parsed: URL;
    try {
      parsed = new URL(url);
    } catch {
      throw new ValidationError('Invalid URL', [{ path: 'url', message: 'Must be a valid URL' }]);
    }
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      throw new ValidationError('Invalid URL', [
        { path: 'url', message: 'Only http(s) links are supported' },
      ]);
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
    try {
      const response = await fetch(parsed.toString(), {
        signal: controller.signal,
        headers: { 'User-Agent': 'SmartClass/1.0 (course-generator)' },
      });
      if (!response.ok) {
        throw new ServiceUnavailableError(
          `The link could not be fetched (HTTP ${response.status}).`,
        );
      }
      const contentType = response.headers.get('content-type') ?? '';
      if (!/text\/html|text\/plain/i.test(contentType)) {
        throw new ValidationError('Unsupported link content', [
          { path: 'url', message: `Expected an HTML page, got: ${contentType || 'unknown'}` },
        ]);
      }
      const reader = response.body?.getReader();
      if (!reader) {
        throw new ServiceUnavailableError('The link body could not be read.');
      }
      const chunks: Uint8Array[] = [];
      let received = 0;
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        if (value) {
          received += value.byteLength;
          if (received > MAX_HTML_BYTES) break;
          chunks.push(value);
        }
      }
      const total = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
      const merged = new Uint8Array(total);
      let offset = 0;
      for (const chunk of chunks) {
        merged.set(chunk, offset);
        offset += chunk.length;
      }
      const html = new TextDecoder().decode(merged);
      if (/text\/plain/i.test(contentType)) {
        return { finalUrl: response.url || url, title: null, text: html };
      }
      const { title, text } = htmlToText(html);
      return { finalUrl: response.url || url, title, text };
    } catch (error) {
      if (error instanceof ValidationError || error instanceof ServiceUnavailableError) {
        throw error;
      }
      logger.warn({ err: error }, 'URL fetch failed');
      throw new ServiceUnavailableError('The link could not be fetched.');
    } finally {
      clearTimeout(timer);
    }
  }
}
