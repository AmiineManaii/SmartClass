import type { ClassAccessContext } from './video-session-policy.js';

export interface ClassAccessPort {
  getClassAccess(userId: string, classGroupId: string): Promise<ClassAccessContext>;
  getUserClassGroupIds(userId: string): Promise<string[]>;
  getClassMemberUserIds(classGroupId: string): Promise<string[]>;
}
