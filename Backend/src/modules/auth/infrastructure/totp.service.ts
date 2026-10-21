import crypto from 'node:crypto';
import QRCode from 'qrcode';

const BASE32_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

export class TotpService {
  /**
   * Generates a 20-byte random secret encoded as Base32 (32 characters).
   */
  public generateSecret(): string {
    const bytes = crypto.randomBytes(20);
    let secret = '';
    for (let i = 0; i < 20; i++) {
      secret += BASE32_ALPHABET[bytes[i]! % 32];
    }
    return secret;
  }

  /**
   * Formats the standard RFC 6238 Key URI.
   */
  public getOtpAuthUrl(email: string, secret: string, issuer: string = 'SmartClass'): string {
    const encodedIssuer = encodeURIComponent(issuer);
    const encodedLabel = encodeURIComponent(`${issuer}:${email}`);
    return `otpauth://totp/${encodedLabel}?secret=${secret}&issuer=${encodedIssuer}&algorithm=SHA1&digits=6&period=30`;
  }

  /**
   * Generates a QR Code as a PNG data URL (data:image/png;base64,...).
   */
  public async generateQrCodeDataUrl(otpAuthUrl: string): Promise<string> {
    return QRCode.toDataURL(otpAuthUrl, {
      errorCorrectionLevel: 'M',
      margin: 2,
      width: 256,
      color: {
        dark: '#0F172A',
        light: '#FFFFFF',
      },
    });
  }

  /**
   * Decodes a Base32 string into a Buffer.
   */
  private decodeBase32(encoded: string): Buffer {
    const clean = encoded.toUpperCase().replace(/[\s=-]/g, '');
    let bits = 0;
    let value = 0;
    const bytes: number[] = [];

    for (let i = 0; i < clean.length; i++) {
      const idx = BASE32_ALPHABET.indexOf(clean[i]!);
      if (idx === -1) continue;
      value = (value << 5) | idx;
      bits += 5;

      if (bits >= 8) {
        bytes.push((value >>> (bits - 8)) & 255);
        bits -= 8;
      }
    }

    return Buffer.from(bytes);
  }

  /**
   * Generates a 6-digit TOTP code for a specific time counter.
   */
  public generateCode(secret: string, time: number = Date.now()): string {
    const counter = Math.floor(time / 1000 / 30);
    const counterBuf = Buffer.alloc(8);
    counterBuf.writeBigInt64BE(BigInt(counter));

    const key = this.decodeBase32(secret);
    const hmac = crypto.createHmac('sha1', key).update(counterBuf).digest();

    const offset = hmac[hmac.length - 1]! & 0x0f;
    const binary =
      ((hmac[offset]! & 0x7f) << 24) |
      ((hmac[offset + 1]! & 0xff) << 16) |
      ((hmac[offset + 2]! & 0xff) << 8) |
      (hmac[offset + 3]! & 0xff);

    const otp = binary % 1000000;
    return otp.toString().padStart(6, '0');
  }

  /**
   * Verifies a 6-digit TOTP code with time drift window tolerance (default ±1 window = ±30s).
   */
  public verifyCode(secret: string, token: string, window: number = 1): boolean {
    const sanitizedToken = token.trim().replace(/\s+/g, '');
    if (!/^\d{6}$/.test(sanitizedToken)) {
      return false;
    }

    const now = Date.now();
    for (let i = -window; i <= window; i++) {
      const testTime = now + i * 30 * 1000;
      const expected = this.generateCode(secret, testTime);
      if (crypto.timingSafeEqual(Buffer.from(sanitizedToken), Buffer.from(expected))) {
        return true;
      }
    }
    return false;
  }

  /**
   * Generates emergency one-time recovery codes (e.g. 8 codes formatted as XXXX-XXXX).
   */
  public generateRecoveryCodes(count: number = 8): string[] {
    const codes: string[] = [];
    for (let i = 0; i < count; i++) {
      const hex = crypto.randomBytes(4).toString('hex').toUpperCase();
      codes.push(`${hex.slice(0, 4)}-${hex.slice(4, 8)}`);
    }
    return codes;
  }

  /**
   * Hashes a recovery code for safe persistence.
   */
  public hashRecoveryCode(code: string): string {
    return crypto.createHash('sha256').update(code.trim().toUpperCase()).digest('hex');
  }
}
