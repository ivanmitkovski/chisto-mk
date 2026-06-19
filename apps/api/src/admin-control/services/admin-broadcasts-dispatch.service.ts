import { Injectable } from '@nestjs/common';
import { AuditService } from '../../audit/services/audit.service';
import { NotificationDispatcherService } from '../../notifications/services/notification-dispatcher.service';
import { NotificationType } from '../../prisma-client';
import { AdminBroadcastsService } from './admin-broadcasts.service';
import { AdminBroadcastsAudienceResolver } from './admin-broadcasts-audience.resolver';
import type { BroadcastCampaign } from '../types/admin-broadcasts.types';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';

const DISPATCH_CHUNK_SIZE = 50;

@Injectable()
export class AdminBroadcastsDispatchService {
  constructor(
    private readonly broadcasts: AdminBroadcastsService,
    private readonly audienceResolver: AdminBroadcastsAudienceResolver,
    private readonly dispatcher: NotificationDispatcherService,
    private readonly audit?: AuditService,
  ) {}

  async send(
    id: string,
    actor?: AuthenticatedUser,
  ): Promise<{ sentCount: number; failedCount: number }> {
    const campaign = await this.broadcasts.claimForSend(id);
    const result = await this.dispatchNotifications(campaign);
    await this.broadcasts.updateSentCount(id, result.sentCount);

    await this.audit?.log({
      actorId: actor?.userId ?? null,
      action: 'BROADCAST_SENT',
      resourceType: 'BroadcastCampaign',
      resourceId: id,
      metadata: {
        sentCount: result.sentCount,
        failedCount: result.failedCount,
        audience: campaign.audience,
        scheduled: actor == null,
      },
    });

    return result;
  }

  private async dispatchNotifications(
    campaign: BroadcastCampaign,
  ): Promise<{ sentCount: number; failedCount: number }> {
    const userIds = await this.audienceResolver.resolveAudienceUserIds(campaign);
    let sentCount = 0;
    let failedCount = 0;

    for (let offset = 0; offset < userIds.length; offset += DISPATCH_CHUNK_SIZE) {
      const chunk = userIds.slice(offset, offset + DISPATCH_CHUNK_SIZE);
      const results = await Promise.all(
        chunk.map(async (userId) => {
          try {
            await this.dispatcher.dispatchToUser(userId, {
              title: campaign.title,
              body: campaign.body,
              type: NotificationType.SYSTEM,
              data: {
                kind: 'admin_broadcast',
                deeplink: campaign.deeplink ?? '',
                campaignId: campaign.id,
              },
            });
            return true;
          } catch {
            return false;
          }
        }),
      );
      sentCount += results.filter(Boolean).length;
      failedCount += results.filter((ok) => !ok).length;
    }

    return { sentCount, failedCount };
  }
}
