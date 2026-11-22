export interface ClassMembershipPort {
  listEnrolledClassGroupIds(userId: string): Promise<string[]>;
}
