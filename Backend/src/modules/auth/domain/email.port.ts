export interface EmailPort {
  sendVerificationEmail(email: string, firstName: string, code: string): Promise<void>;
  sendPasswordResetEmail(email: string, firstName: string, code: string): Promise<void>;
}
