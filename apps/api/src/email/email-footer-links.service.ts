import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationType } from '../prisma-client';
import { EmailUnsubscribeTokenService } from './email-unsubscribe-token.service';
import { resolveAppBaseUrl, resolveLogoUrl } from './email-urls';

/**
 * Resolves configurable URLs embedded in transactional email (preferences, unsubscribe, branding CTAs).
 */
@Injectable()
export class EmailFooterLinksService {
  constructor(
    private readonly config: ConfigService,
    private readonly unsubscribeTokens: EmailUnsubscribeTokenService,
  ) {}

  preferencesUrl(): string {
    const trimmed = this.config.get<string>('EMAIL_PREFERENCES_INFO_URL')?.trim();
    if (trimmed) return trimmed;
    return `${this.publicApiBase()}/`;
  }

  unsubscribeUrl(userId: string, notificationType: NotificationType): string {
    const token = this.unsubscribeTokens.sign(userId, notificationType);
    return `${this.publicApiBase()}/notifications/email/unsubscribe?token=${encodeURIComponent(token)}`;
  }

  brandingUrls(): { appBaseUrl: string; logoUrl: string } {
    return {
      appBaseUrl: resolveAppBaseUrl({
        emailApp: this.config.get<string>('EMAIL_APP_BASE_URL'),
        share: this.config.get<string>('SHARE_BASE_URL'),
      }),
      logoUrl: resolveLogoUrl({
        logo: this.config.get<string>('EMAIL_LOGO_URL'),
      }),
    };
  }

  private publicApiBase(): string {
    const raw =
      this.config.get<string>('EMAIL_PUBLIC_API_BASE_URL')?.trim() ||
      this.config.get<string>('SHARE_BASE_URL')?.trim() ||
      'https://chisto.mk';
    return raw.replace(/\/+$/, '');
  }
}
