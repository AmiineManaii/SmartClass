import type { Role } from '../../auth/index.js';
import type { ImageKind } from './image-generator.port.js';

export type SectionImageJobStatus = 'QUEUED' | 'RUNNING' | 'SUCCEEDED' | 'FAILED';

export interface SectionImageJobResult {
  imageUrl: string;
  prompt: string;
  provider: string;
}

export interface SectionImageJobError {
  code: string;
  message: string;
}

export interface SectionImageJob {
  id: string;
  ownerId: string;
  ownerRole: Role | null;
  courseId: string;
  sectionKey: string;
  kind: ImageKind;
  status: SectionImageJobStatus;
  createdAt: Date;
  updatedAt: Date;
  result?: SectionImageJobResult;
  error?: SectionImageJobError;
}

export interface SectionImageJobStorePort {
  save(job: SectionImageJob): Promise<void>;
  findById(jobId: string): Promise<SectionImageJob | null>;
  findActive(
    ownerId: string,
    courseId: string,
    sectionKey: string,
  ): Promise<SectionImageJob | null>;
  prune(olderThan: Date): Promise<void>;
}
