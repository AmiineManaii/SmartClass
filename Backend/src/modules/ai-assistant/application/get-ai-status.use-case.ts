import type { AiEmbeddingStatus, AiGatewayPort, AiGatewayStatus } from '../domain/ai-gateway.port.js';
import type { SmartModelRouterPort } from '../domain/model-router.port.js';

export class GetAiStatusUseCase {
  constructor(
    private readonly gateway: AiGatewayPort,
    private readonly modelRouter?: SmartModelRouterPort,
    private readonly checkEmbeddings?: () => Promise<AiEmbeddingStatus>,
  ) {}

  public async execute(): Promise<AiGatewayStatus> {
    const base = await this.gateway.checkHealth();
    const [router, embeddings] = await Promise.all([
      this.modelRouter ? this.modelRouter.inspectInventory().catch(() => undefined) : undefined,
      this.checkEmbeddings ? this.checkEmbeddings().catch(() => undefined) : undefined,
    ]);

    return {
      ...base,
      ...(router ? { router } : {}),
      ...(embeddings ? { embeddings } : {}),
    };
  }
}
