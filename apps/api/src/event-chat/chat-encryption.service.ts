import { Injectable, Logger, OnModuleInit, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

const ALGO = 'aes-256-gcm';
const IV_LEN = 12;
const TAG_LEN = 16;

@Injectable()
export class ChatEncryptionService implements OnModuleInit {
  private readonly logger = new Logger(ChatEncryptionService.name);
  private key: Buffer | null = null;
  private _enabled = false;

  constructor(@Optional() private readonly config: ConfigService | null) {}

  get enabled(): boolean {
    return this._enabled;
  }

  onModuleInit(): void {
    const hex =
      this.config?.get<string>('CHAT_ENCRYPTION_KEY')?.trim() ??
      process.env.CHAT_ENCRYPTION_KEY?.trim();
    if (!hex || hex.length !== 64) {
      this.logger.warn(
        'CHAT_ENCRYPTION_KEY missing or invalid (expected 64 hex chars / 32 bytes). ' +
          'Chat encryption is DISABLED.',
      );
      return;
    }
    this.key = Buffer.from(hex, 'hex');
    this._enabled = true;
    this.logger.log('Chat encryption enabled (AES-256-GCM)');
  }

  encrypt(plaintext: string): string {
    if (!this.key) return plaintext;
    const iv = randomBytes(IV_LEN);
    const cipher = createCipheriv(ALGO, this.key, iv);
    const encrypted = Buffer.concat([
      cipher.update(plaintext, 'utf8'),
      cipher.final(),
    ]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([iv, tag, encrypted]).toString('base64');
  }

  decrypt(ciphertext: string): string {
    if (!this.key) return ciphertext;
    const buf = Buffer.from(ciphertext, 'base64');
    if (buf.length < IV_LEN + TAG_LEN) {
      this.logger.warn('Ciphertext too short for AES-256-GCM');
      return ciphertext;
    }
    const iv = buf.subarray(0, IV_LEN);
    const tag = buf.subarray(IV_LEN, IV_LEN + TAG_LEN);
    const data = buf.subarray(IV_LEN + TAG_LEN);
    const decipher = createDecipheriv(ALGO, this.key, iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([
      decipher.update(data),
      decipher.final(),
    ]).toString('utf8');
  }
}
