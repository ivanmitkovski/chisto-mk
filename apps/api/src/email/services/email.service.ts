import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationType } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { DEFAULT_EMAIL_FROM_ADDRESS, DEFAULT_EMAIL_FROM_NAME } from '../constants/email.constants';
import { EmailFooterLinksService } from './email-footer-links.service';
import { EmailSendEligibilityService } from './email-send-eligibility.service';
import { EmailPostmarkTransportService } from './email-postmark-transport.service';
import { EmailTemplateService } from './email-template.service';
import { mapNotificationEventToEmail, resolveLocale } from '../util/email-event-mapper';
import { isImportantNotificationEmail } from '../util/email-importance.policy';
import type { NotificationEvent } from '../../notifications/types/notification-event.types';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import type { EmailLocale, EmailTemplateId } from '../types/email.types';
import type { EmailSendPayload } from '../types/email-transport.types';
import { emailSendTotal } from '../../observability/util/prom-registry';

/**
 * Orchestrates transactional email: eligibility, templating, and Postmark delivery.
 * JWT unsubscribe signing, transport, and URL resolution live in dedicated services.
 */
@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly eligibility: EmailSendEligibilityService,
    private readonly footerLinks: EmailFooterLinksService,
    private readonly transport: EmailPostmarkTransportService,
    private readonly templates: EmailTemplateService,
  ) {}

  async sendForNotificationEvent(
    userId: string,
    event: Omit<NotificationEvent, 'recipientUserIds'>,
  ): Promise<void> {
    if (!(await this.eligibility.isGloballyEnabled())) return;
    if (!isImportantNotificationEmail(event)) return;

    const mapped = mapNotificationEventToEmail(event);
    if (!mapped) return;

    if (await this.eligibility.isMutedForType(userId, event.type)) return;

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true, firstName: true, status: true },
    });
    if (!user || user.status !== 'ACTIVE') return;

    const localeBy = await notificationLocalesByUserId(this.prisma, [userId]);
    const locale = resolveLocale(localeBy.get(userId));

    const ctx = {
      ...mapped.context,
      firstName: user.firstName,
    };

    await this.sendTemplate({
      to: user.email,
      userId,
      notificationType: event.type,
      templateId: mapped.templateId,
      locale,
      context: ctx,
    });
  }

  async sendTemplate(params: {
    to: string;
    userId: string;
    notificationType: NotificationType;
    templateId: EmailTemplateId;
    locale: EmailLocale;
    context: Record<string, unknown>;
    /** When true, do not suppress by per-type email preference (used for security-critical mail). */
    skipPreferenceCheck?: boolean;
  }): Promise<void> {
    if (!(await this.eligibility.isGloballyEnabled())) return;
    if (!params.skipPreferenceCheck) {
      if (await this.eligibility.isMutedForType(params.userId, params.notificationType)) return;
    }

    const to = params.to.trim();
    if (!(await this.eligibility.canSendToAddress(to))) {
      this.logger.warn(
        `Skipping email send: suppressed or invalid recipient for template=${params.templateId}`,
      );
      return;
    }

    /** Product policy: all transactional mail is sent from this address only. */
    const fromAddress = DEFAULT_EMAIL_FROM_ADDRESS;
    const fromName = this.config.get<string>('EMAIL_FROM_NAME')?.trim() || DEFAULT_EMAIL_FROM_NAME;
    const fromHeader = `${fromName.replace(/"/g, '')} <${fromAddress}>`;

    const prefsUrl = this.footerLinks.preferencesUrl();
    const unsubscribeUrl = this.footerLinks.unsubscribeUrl(params.userId, params.notificationType);
    const { appBaseUrl, logoUrl, inlineAttachment } = this.footerLinks.brandingUrls();

    const { html, text, subject } = this.templates.render({
      templateId: params.templateId,
      locale: params.locale,
      context: params.context,
      prefsUrl,
      unsubscribeUrl,
      appBaseUrl,
      logoUrl,
    });

    const sendPayload: EmailSendPayload = {
      fromHeader,
      to,
      subject,
      text,
      html,
      listUnsubscribeUrl: unsubscribeUrl,
      templateId: params.templateId,
    };
    if (inlineAttachment) {
      sendPayload.inlineAttachments = [inlineAttachment];
    }
    const sent = await this.transport.send(sendPayload);
    emailSendTotal.inc({
      result: sent ? 'success' : 'failure',
      template: params.templateId,
    });
  }

  async sendAuthTemplate(params: {
    userId: string;
    to: string;
    firstName: string;
    templateId: Extract<EmailTemplateId, 'welcome' | 'password_reset' | 'password_changed'>;
    locale: EmailLocale;
    context?: Record<string, unknown>;
  }): Promise<void> {
    if (!(await this.eligibility.isGloballyEnabled())) return;
    const isSecurity =
      params.templateId === 'password_changed' || params.templateId === 'password_reset';
    await this.sendTemplate({
      to: params.to,
      userId: params.userId,
      notificationType: params.templateId === 'welcome' ? NotificationType.WELCOME : NotificationType.SYSTEM,
      templateId: params.templateId,
      locale: params.locale,
      context: { firstName: params.firstName, ...params.context },
      skipPreferenceCheck: isSecurity,
    });
  }

  async sendAdminInviteEmail(
    to: string,
    ctx: {
      firstName: string;
      lastName: string;
      roleLabel: string;
      inviteUrl: string;
      expiresAt: string;
    },
  ): Promise<void> {
    if (!(await this.eligibility.isGloballyEnabled())) return;

    const trimmed = to.trim();
    if (!(await this.eligibility.canSendToAddress(trimmed))) {
      this.logger.warn(
        `Skipping admin invite email: suppressed or invalid recipient address=${trimmed}`,
      );
      return;
    }

    const fromAddress = DEFAULT_EMAIL_FROM_ADDRESS;
    const fromName = this.config.get<string>('EMAIL_FROM_NAME')?.trim() || DEFAULT_EMAIL_FROM_NAME;
    const fromHeader = `${fromName.replace(/"/g, '')} <${fromAddress}>`;

    const { appBaseUrl, logoUrl, inlineAttachment } = this.footerLinks.brandingUrls();
    const locale: EmailLocale = 'en';

    const { html, text, subject } = this.templates.render({
      templateId: 'admin_invite',
      locale,
      context: {
        firstName: ctx.firstName,
        lastName: ctx.lastName,
        roleLabel: ctx.roleLabel,
        inviteUrl: ctx.inviteUrl,
        expiresAt: ctx.expiresAt,
      },
      prefsUrl: this.footerLinks.preferencesUrl(),
      unsubscribeUrl: this.footerLinks.preferencesUrl(),
      appBaseUrl,
      logoUrl,
    });

    const sendPayload: EmailSendPayload = {
      fromHeader,
      to: trimmed,
      subject,
      text,
      html,
      templateId: 'admin_invite',
    };
    if (inlineAttachment) {
      sendPayload.inlineAttachments = [inlineAttachment];
    }
    const sent = await this.transport.send(sendPayload);
    emailSendTotal.inc({
      result: sent ? 'success' : 'failure',
      template: 'admin_invite',
    });
  }

  async sendAdminModerationEmail(
    to: string,
    ctx: {
      firstName: string;
      templateId: EmailTemplateId;
      locale: EmailLocale;
      context: Record<string, unknown>;
      unsubscribeUrl: string;
    },
  ): Promise<void> {
    if (!(await this.eligibility.isGloballyEnabled())) return;

    const trimmed = to.trim();
    if (!(await this.eligibility.canSendToAddress(trimmed))) {
      this.logger.warn(
        `Skipping admin moderation email: suppressed or invalid recipient address=${trimmed} template=${ctx.templateId}`,
      );
      return;
    }

    const fromAddress = DEFAULT_EMAIL_FROM_ADDRESS;
    const fromName = this.config.get<string>('EMAIL_FROM_NAME')?.trim() || DEFAULT_EMAIL_FROM_NAME;
    const fromHeader = `${fromName.replace(/"/g, '')} <${fromAddress}>`;

    const { appBaseUrl, logoUrl, inlineAttachment } = this.footerLinks.brandingUrls();

    const { html, text, subject } = this.templates.render({
      templateId: ctx.templateId,
      locale: ctx.locale,
      context: ctx.context,
      prefsUrl: this.footerLinks.preferencesUrl(),
      unsubscribeUrl: ctx.unsubscribeUrl,
      appBaseUrl,
      logoUrl,
    });

    const sendPayload: EmailSendPayload = {
      fromHeader,
      to: trimmed,
      subject,
      text,
      html,
      templateId: ctx.templateId,
      listUnsubscribeUrl: ctx.unsubscribeUrl,
    };
    if (inlineAttachment) {
      sendPayload.inlineAttachments = [inlineAttachment];
    }
    const sent = await this.transport.send(sendPayload);
    emailSendTotal.inc({
      result: sent ? 'success' : 'failure',
      template: ctx.templateId,
    });
  }
}
