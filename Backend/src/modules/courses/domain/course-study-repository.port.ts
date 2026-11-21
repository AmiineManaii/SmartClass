import type {
  CourseStudyArtifact,
  CourseStudyArtifactKind,
  CourseStudyLanguage,
  CourseTutorCitation,
  CourseTutorConversation,
  CourseTutorMessage,
} from './course-study.entity.js';

export interface CreateCourseStudyArtifactParams {
  courseId: string;
  userId: string;
  kind: CourseStudyArtifactKind;
  title: string;
  language: CourseStudyLanguage;
  config: Record<string, unknown>;
  content: Record<string, unknown>;
  modelUsed: string | null;
}

export interface CreateCourseTutorConversationParams {
  courseId: string;
  userId: string;
  title: string;
}

export interface AppendCourseTutorMessageParams {
  conversationId: string;
  role: 'user' | 'assistant';
  content: string;
  citations?: CourseTutorCitation[];
  inScope?: boolean;
  modelUsed?: string | null;
}

/** Persistence for student study artifacts and private tutor threads. */
export interface CourseStudyRepositoryPort {
  listArtifacts(courseId: string, userId: string): Promise<CourseStudyArtifact[]>;
  createArtifact(params: CreateCourseStudyArtifactParams): Promise<CourseStudyArtifact>;
  /** Scoped by owner: one student never deletes another's artifact. */
  deleteArtifact(artifactId: string, userId: string): Promise<boolean>;

  listConversations(courseId: string, userId: string): Promise<CourseTutorConversation[]>;
  findConversation(
    conversationId: string,
    userId: string,
  ): Promise<CourseTutorConversation | null>;
  createConversation(
    params: CreateCourseTutorConversationParams,
  ): Promise<CourseTutorConversation>;
  appendMessage(params: AppendCourseTutorMessageParams): Promise<CourseTutorMessage>;
}
