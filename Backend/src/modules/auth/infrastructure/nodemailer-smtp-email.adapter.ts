import nodemailer, { type Transporter } from 'nodemailer';
import type { EmailPort } from '../domain/email.port.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type { Env } from '../../../config/env.js';

export interface SmtpConfig {
  host: string;
  port: number;
  secure: boolean;
  user: string;
  pass?: string;
  from: string;
}

export class NodemailerSmtpEmailAdapter implements EmailPort {
  private transporter: Transporter | null = null;
  private readonly config: SmtpConfig;

  constructor(env: Env) {
    this.config = {
      host: env.SMTP_HOST,
      port: env.SMTP_PORT,
      secure: env.SMTP_SECURE,
      user: env.SMTP_USER,
      pass: env.SMTP_PASS,
      from: env.SMTP_FROM,
    };

    if (this.config.pass && this.config.pass.trim().length > 0) {
      this.transporter = nodemailer.createTransport({
        host: this.config.host,
        port: this.config.port,
        secure: this.config.secure,
        auth: {
          user: this.config.user,
          pass: this.config.pass,
        },
      });
    }
  }

  public async sendVerificationEmail(email: string, firstName: string, code: string): Promise<void> {
    const subject = 'SmartClass — Votre code de confirmation de compte';
    const text = `Bonjour ${firstName},\n\nBienvenue sur SmartClass !\nVotre code de vérification est : ${code}\nCe code est valide pendant 15 minutes.\n\nSi vous n'êtes pas à l'origine de cette demande, vous pouvez ignorer cet email.\n\nL'équipe SmartClass`;
    const html = this.buildHtmlTemplate({
      title: 'Vérification de votre compte SmartClass',
      firstName,
      message: 'Bienvenue sur la plateforme SmartClass. Veuillez utiliser le code à 6 chiffres ci-dessous pour confirmer votre adresse email et activer votre compte :',
      code,
      expiryMinutes: 15,
    });

    await this.dispatchEmail(email, subject, text, html, code, 'verification');
  }

  public async sendPasswordResetEmail(email: string, firstName: string, code: string): Promise<void> {
    const subject = 'SmartClass — Réinitialisation de votre mot de passe';
    const text = `Bonjour ${firstName},\n\nUne demande de réinitialisation de mot de passe a été initiée pour votre compte SmartClass.\nVotre code de réinitialisation est : ${code}\nCe code est valide pendant 15 minutes.\n\nSi vous n'avez pas demandé cette réinitialisation, veuillez ignorer cet email.\n\nL'équipe SmartClass`;
    const html = this.buildHtmlTemplate({
      title: 'Réinitialisation de mot de passe',
      firstName,
      message: 'Une demande de réinitialisation de mot de passe a été reçue. Utilisez le code à 6 chiffres suivant pour définir un nouveau mot de passe sécurisé :',
      code,
      expiryMinutes: 15,
    });

    await this.dispatchEmail(email, subject, text, html, code, 'password-reset');
  }

  private async dispatchEmail(
    to: string,
    subject: string,
    text: string,
    html: string,
    code: string,
    type: 'verification' | 'password-reset',
  ): Promise<void> {
    if (this.transporter && this.config.pass) {
      try {
        await this.transporter.sendMail({
          from: this.config.from,
          to,
          subject,
          text,
          html,
        });

        logger.info(
          { to, type, sender: this.config.user },
          `📧 [SMTP LIVE] Email sent successfully to ${to} via ${this.config.user}`,
        );
        return;
      } catch (err) {
        logger.error(
          { err, to, type },
          `❌ [SMTP ERROR] Failed to send email via SMTP, falling back to local log`,
        );
      }
    }

    // Fallback: Log code clearly when SMTP password is not provided or in dev/test
    logger.info(
      { to, recipient: to, otp: code, type, sender: this.config.user },
      `📧 [SMTP MOCK/DEV] (${type.toUpperCase()}) Code for ${to}: >>> ${code} <<< [Configured sender: ${this.config.user} | Configure SMTP_PASS in .env to deliver real emails]`,
    );
  }

  private buildHtmlTemplate(params: {
    title: string;
    firstName: string;
    message: string;
    code: string;
    expiryMinutes: number;
  }): string {
    return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${params.title}</title>
  <style>
    body { margin: 0; padding: 0; background-color: #f4f6fb; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1e2233; }
    .container { max-width: 560px; margin: 30px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.06); }
    .header { background: linear-gradient(135deg, #2d3e8c 0%, #4a5fc1 100%); color: #ffffff; padding: 32px 24px; text-align: center; }
    .header h1 { margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.5px; }
    .content { padding: 32px 28px; line-height: 1.6; }
    .greeting { font-size: 17px; font-weight: 600; margin-bottom: 12px; }
    .code-box { background: #eef2ff; border: 2px dashed #4a5fc1; border-radius: 10px; padding: 20px; text-align: center; margin: 26px 0; }
    .otp-code { font-family: 'Consolas', 'Monaco', monospace; font-size: 36px; font-weight: 800; color: #2d3e8c; letter-spacing: 8px; margin: 0; }
    .expiry { color: #6b7280; font-size: 13px; margin-top: 8px; }
    .warning { font-size: 12px; color: #9ca3af; margin-top: 24px; border-top: 1px solid #f3f4f6; padding-top: 16px; }
    .footer { text-align: center; font-size: 12px; color: #9ca3af; padding: 16px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>SmartClass</h1>
    </div>
    <div class="content">
      <div class="greeting">Bonjour ${params.firstName},</div>
      <p>${params.message}</p>
      <div class="code-box">
        <p class="otp-code">${params.code}</p>
        <div class="expiry">Ce code expire dans ${params.expiryMinutes} minutes.</div>
      </div>
      <div class="warning">
        🔒 <strong>Sécurité :</strong> Ne partagez ce code avec personne. L'équipe SmartClass ne vous demandera jamais votre code par message ou téléphone.
      </div>
    </div>
    <div class="footer">
      © ${new Date().getFullYear()} SmartClass. Plateforme intelligente et collaborative d'apprentissage.
    </div>
  </div>
</body>
</html>`;
  }
}
