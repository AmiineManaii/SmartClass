import type { EmailPort } from '../domain/email.port.js';
import { logger } from '../../../shared/infrastructure/logger.js';

export interface SentEmail {
  to: string;
  type: 'VERIFICATION' | 'PASSWORD_RESET';
  code: string;
  sentAt: Date;
}

export class ConsoleEmailAdapter implements EmailPort {
  private readonly sentEmails: SentEmail[] = [];

  public async sendVerificationEmail(email: string, firstName: string, code: string): Promise<void> {
    this.sentEmails.push({
      to: email,
      type: 'VERIFICATION',
      code,
      sentAt: new Date(),
    });

    logger.info(
      {
        to: email,
        recipient: firstName,
        otp: code,
      },
      `📧 [EMAIL] Verification code for ${firstName} (${email}): >>> ${code} <<< (valid for 15 minutes)`,
    );
  }

  public async sendPasswordResetEmail(email: string, firstName: string, code: string): Promise<void> {
    this.sentEmails.push({
      to: email,
      type: 'PASSWORD_RESET',
      code,
      sentAt: new Date(),
    });

    logger.info(
      {
        to: email,
        recipient: firstName,
        otp: code,
      },
      `🔑 [EMAIL] Password reset code for ${firstName} (${email}): >>> ${code} <<< (valid for 15 minutes)`,
    );
  }

  public getSentEmails(): SentEmail[] {
    return [...this.sentEmails];
  }

  public clear(): void {
    this.sentEmails.length = 0;
  }
}
