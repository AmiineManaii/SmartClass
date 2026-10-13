import type { AiGatewayPort, AiGatewayStatus } from '../domain/ai-gateway.port.js';

export class GetAiStatusUseCase {
  constructor(private readonly gateway: AiGatewayPort) {}

  public async execute(): Promise<AiGatewayStatus> {
    return this.gateway.checkHealth();
  }
}
