export interface LivenessResult {
  status: 'ok';
  uptime: number;
}

export class GetLivenessUseCase {
  public execute(): LivenessResult {
    return {
      status: 'ok',
      uptime: process.uptime(),
    };
  }
}
