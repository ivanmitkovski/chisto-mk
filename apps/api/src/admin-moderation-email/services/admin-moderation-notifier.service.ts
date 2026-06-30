import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { FeatureFlagsService } from '../../feature-flags/services/feature-flags.service';
import { EmailSendEligibilityService } from '../../email/services/email-send-eligibility.service';
import { AuditService } from '../../audit/services/audit.service';
import type { AdminModerationNotifyParams } from '../types/admin-moderation-notify.types';
import { AdminModerationRecipientsService } from './admin-moderation-recipients.service';
import { AdminModerationEmailOutboxService } from './admin-moderation-email-outbox.service';

@Injectable()
export class AdminModerationNotifierService {
  private readonly logger = new Logger(AdminModerationNotifierService.name);

  constructor(
    private readonly featureFlags: FeatureFlagsService,
    private readonly eligibility: EmailSendEligibilityService,
    private readonly recipients: AdminModerationRecipientsService,
    private readonly outbox: AdminModerationEmailOutboxService,
    private readonly audit?: AuditService,
  ) {}

  notify(params: AdminModerationNotifyParams): void {
    void this.notifyAsync(params).catch((err: unknown) => {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.warn(
        `Admin moderation email notify failed category=${params.category} resourceId=${params.resourceId}: ${message}`,
      );
    });
  }

  private async notifyAsync(params: AdminModerationNotifyParams): Promise<void> {
    if (!(await this.isFeatureEnabled())) {
      return;
    }
    if (!(await this.eligibility.isGloballyEnabled())) {
      return;
    }

    const staff = await this.recipients.resolveForCategory(params.category);
    if (staff.length === 0) {
      return;
    }

    const enqueued = await this.outbox.enqueueMany(
      staff.map((user) => ({
        recipientUserId: user.userId,
        recipientEmail: user.email,
        category: params.category,
        resourceId: params.resourceId,
        payload: {
          firstName: user.firstName,
          deepLinkPath: params.deepLinkPath,
          emailContext: params.emailContext,
        },
      })),
    );

    await this.audit?.log({
      actorId: null,
      action: 'MODERATION_EMAIL_ENQUEUED',
      resourceType: 'AdminModerationEmail',
      resourceId: params.resourceId,
      metadata: {
        category: params.category,
        recipientCount: enqueued,
      } as Prisma.InputJsonValue,
    });
  }

  private async isFeatureEnabled(): Promise<boolean> {
    return this.featureFlags.isAdminModerationEmailEnabled();
  }
}
