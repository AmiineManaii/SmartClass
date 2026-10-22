import type {
  SectionImageJob,
  SectionImageJobStorePort,
} from '../domain/section-image-job.port.js';

const copy = (job: SectionImageJob): SectionImageJob => ({
  ...job,
  result: job.result ? { ...job.result } : undefined,
  error: job.error ? { ...job.error } : undefined,
});

/** Process-local job registry (single API container; lost on restart). */
export class InMemorySectionImageJobStore implements SectionImageJobStorePort {
  private readonly jobs = new Map<string, SectionImageJob>();

  public async save(job: SectionImageJob): Promise<void> {
    this.jobs.set(job.id, copy(job));
  }

  public async findById(jobId: string): Promise<SectionImageJob | null> {
    const job = this.jobs.get(jobId);
    return job ? copy(job) : null;
  }

  public async findActive(
    ownerId: string,
    courseId: string,
    sectionKey: string,
  ): Promise<SectionImageJob | null> {
    for (const job of this.jobs.values()) {
      if (
        job.ownerId === ownerId &&
        job.courseId === courseId &&
        job.sectionKey === sectionKey &&
        (job.status === 'QUEUED' || job.status === 'RUNNING')
      ) {
        return copy(job);
      }
    }
    return null;
  }

  public async prune(olderThan: Date): Promise<void> {
    for (const [id, job] of this.jobs) {
      if (job.updatedAt < olderThan) {
        this.jobs.delete(id);
      }
    }
  }
}
