export interface FetchedUrl {
  finalUrl: string;
  title: string | null;
  text: string;
}

export interface UrlFetcherPort {
  fetchText(url: string): Promise<FetchedUrl>;
}
