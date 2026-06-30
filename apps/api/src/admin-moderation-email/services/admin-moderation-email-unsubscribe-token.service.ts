import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import { AdminModerationCategory } from '../../prisma-client';
import type { AdminModerationEmailUnsubscribeJwtPayload } from '../../email/types/email.types';

@Injectable()
export class AdminModerationEmailUnsubscribeTokenService {
  constructor(private readonly config: ConfigService) {}

  sign(userId: string, category: AdminModerationCategory): string {
    const secret = this.requireJwtSecret('JWT_SECRET is required for admin moderation email unsubscribe tokens');
    const payload: AdminModerationEmailUnsubscribeJwtPayload = {
      sub: userId,
      typ: 'admin_mod_email_unsub',
      category,
      v: 1,
    };
    return jwt.sign(payload, secret, { expiresIn: '180d' });
  }

  verify(token: string): AdminModerationEmailUnsubscribeJwtPayload {
    const secret = this.requireJwtSecret('JWT_SECRET is not configured');
    const decoded = jwt.verify(token, secret) as jwt.JwtPayload &
      Partial<AdminModerationEmailUnsubscribeJwtPayload>;
    if (decoded.typ !== 'admin_mod_email_unsub' || typeof decoded.sub !== 'string') {
      throw new Error('Invalid unsubscribe token');
    }
    const category = decoded.category;
    if (!Object.values(AdminModerationCategory).includes(category as AdminModerationCategory)) {
      throw new Error('Invalid moderation category');
    }
    return {
      sub: decoded.sub,
      typ: 'admin_mod_email_unsub',
      category: category as AdminModerationCategory,
      v: 1,
    };
  }

  buildUnsubscribeUrl(userId: string, category: AdminModerationCategory): string {
    const token = this.sign(userId, category);
    const base = this.publicApiBase();
    return `${base}/admin/moderation-email/unsubscribe?token=${encodeURIComponent(token)}`;
  }

  private publicApiBase(): string {
    const raw =
      this.config.get<string>('EMAIL_PUBLIC_API_BASE_URL')?.trim() ||
      this.config.get<string>('SHARE_BASE_URL')?.trim() ||
      'https://chisto.mk';
    return raw.replace(/\/+$/, '');
  }

  private requireJwtSecret(missingMessage: string): string {
    const secret = this.config.get<string>('JWT_SECRET');
    if (!secret) {
      throw new Error(missingMessage);
    }
    return secret;
  }
}
