export interface ExamAiModelCatalogPort {
  /**
   * Lists model names installed in the local Ollama instance. Never pulls
   * or downloads a model: an unknown model is a hard failure.
   */
  listInstalledModels(): Promise<string[]>;
}
