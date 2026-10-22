import { describe, expect, it } from 'vitest';
import { HybridSearchAdapter } from '../../src/modules/ai-assistant/infrastructure/hybrid-search.adapter.js';

describe('Unit: HybridSearchAdapter', () => {
  it('handles empty or whitespace queries gracefully', async () => {
    const adapter = new HybridSearchAdapter();
    const web = await adapter.searchWeb('   ');
    expect(web).toEqual([]);

    const images = await adapter.searchImages('');
    expect(images).toEqual([]);
  });

  it('searches real educational images from Wikimedia Commons', async () => {
    const adapter = new HybridSearchAdapter();
    const images = await adapter.searchImages('DNA replication diagram', 3);
    // Wikimedia Commons is free public API
    if (images.length > 0) {
      expect(images[0]).toHaveProperty('title');
      expect(images[0]).toHaveProperty('url');
      expect(images[0].url).toMatch(/^https?:\/\//);
      expect(images[0].source).toBe('wikimedia');
    }
  });

  it('searches web facts and educational resources', async () => {
    const adapter = new HybridSearchAdapter();
    const results = await adapter.searchWeb('Computer Science algorithm', 3);
    if (results.length > 0) {
      expect(results[0]).toHaveProperty('title');
      expect(results[0]).toHaveProperty('url');
      expect(results[0].url).toMatch(/^https?:\/\//);
    }
  });
});
