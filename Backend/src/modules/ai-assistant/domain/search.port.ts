export interface WebSearchResult {
  title: string;
  url: string;
  snippet: string;
}

export interface ImageSearchResult {
  title: string;
  url: string;
  caption: string;
  source: 'wikimedia' | 'unsplash' | 'web';
  width?: number;
  height?: number;
}

export interface SearchPort {
  searchWeb(query: string, limit?: number): Promise<WebSearchResult[]>;
  searchImages(query: string, limit?: number): Promise<ImageSearchResult[]>;
}
