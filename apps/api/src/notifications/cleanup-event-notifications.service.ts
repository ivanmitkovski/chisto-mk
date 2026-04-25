import { Injectable, Logger } from '@nestjs/common';
import { NotificationType, Role, UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ObservabilityStore } from '../observability/observability.store';
import { NotificationDispatcherService } from './notification-dispatcher.service';
import { notificationLocalesByUserId } from '../common/i18n/notification-locale.resolver';
import {
  cleanupAudienceEventPublishedPush,
  cleanupOrganizerApprovedPush,
  cleanupOrganizerDeclinedPush,
  cleanupOrganizerReturnedToPendingPush,
  cleanupStaffPendingReviewPush,
} from '../common/i18n/event-user-notification.copy';

const STAFF_ROLES: Role[] = [Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN];
const MAX_PUBLISH_RECIPIENTS = 500;

@Injectable()
export class CleanupEventNotificationsService {
  private readonly logger = new Logger(CleanupEventNotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly dispatcher: NotificationDispatcherService,
  ) {}

  private static formatDispatchErr(err: unknown): string {
    return err instanceof Error ? err.message : String(err);
  }

  async notifyStaffPendingReview(params: {
    eventId: string;
    siteId: string;
    title: string;
  }): Promise<void> {
    const staff = await this.prisma.user.findMany({
      where: { role: { in: STAFF_ROLES }, status: UserStatus.ACTIVE },
      select: { id: true },
      take: 200,
    });
    const localeByUser = await notificationLocalesByUserId(
      this.prisma,
      staff.map((s) => s.id),
    );
    for (const { id } of staff) {
      const locale = localeByUser.get(id) ?? 'mk';
      const { title, body } = cleanupStaffPendingReviewPush(locale, params.title);
      void this.dispatcher
        .dispatchToUser(id, {
          title,
          body,
          type: NotificationType.CLEANUP_EVENT,
          data: {
            kind: 'pending_review',
            eventId: params.eventId,
            siteId: params.siteId,
          },
          threadKey: `staff_pending:${params.eventId}`,
          groupKey: `cleanup_event:${params.eventId}`,
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `Staff pending notification failed for ${id}: ${CleanupEventNotificationsService.formatDispatchErr(err)}`,
          );
        });
    }
    ObservabilityStore.recordCleanupEventStaffPendingSignals(staff.length);
  }

  async notifyOrganizerReturnedToPending(params: {
    organizerId: string;
    eventId: string;
  }): Promise<void> {
    const localeByUser = await notificationLocalesByUserId(this.prisma, [params.organizerId]);
    const locale = localeByUser.get(params.organizerId) ?? 'mk';
    const { title, body } = cleanupOrganizerReturnedToPendingPush(locale);
    void this.dispatcher
      .dispatchToUser(params.organizerId, {
        title,
        body,
        type: NotificationType.CLEANUP_EVENT,
        data: { kind: 'pending_review', eventId: params.eventId },
        threadKey: `organizer_pending_review:${params.eventId}:${Date.now()}`,
        groupKey: `cleanup_event:${params.eventId}`,
      })
      .catch((err: unknown) => {
        this.logger.warn(
          `Organizer re-review notification failed: ${CleanupEventNotificationsService.formatDispatchErr(err)}`,
        );
      });
  }

  async notifyAudienceEventPublished(params: {
    eventId: string;
    siteId: string;
    title: string;
    organizerId: string | null;
    dedupeKey: string;
  }): Promise<void> {
    const recipientIds = await this.resolveSiteEngagedUserIds(params.siteId, params.organizerId);
    const localeByUser = await notificationLocalesByUserId(this.prisma, recipientIds);
    let sent = 0;
    for (const userId of recipientIds) {
      const locale = localeByUser.get(userId) ?? 'mk';
      const { title, body } = cleanupAudienceEventPublishedPush(locale, params.title);
      void this.dispatcher
        .dispatchToUser(userId, {
          title,
          body,
          type: NotificationType.CLEANUP_EVENT,
          data: {
            kind: 'published',
            eventId: params.eventId,
            siteId: params.siteId,
          },
          threadKey: `published:${params.eventId}:${params.dedupeKey}`,
          groupKey: `cleanup_event:${params.eventId}`,
        })
        .catch((err: unknown) => {
          this.logger.warn(
            `Published event notification failed for ${userId}: ${CleanupEventNotificationsService.formatDispatchErr(err)}`,
          );
        });
      sent += 1;
    }
    ObservabilityStore.recordCleanupEventPublishedAudienceBatch(sent);
  }

  async notifyOrganizerApproved(params: {
    organizerId: string;
    eventId: string;
    title: string;
  }): Promise<void> {
    const localeByUser = await notificationLocalesByUserId(this.prisma, [params.organizerId]);
    const locale = localeByUser.get(params.organizerId) ?? 'mk';
    const { title, body } = cleanupOrganizerApprovedPush(locale, params.title);
    void this.dispatcher
      .dispatchToUser(params.organizerId, {
        title,
        body,
        type: NotificationType.CLEANUP_EVENT,
        data: { kind: 'approved', eventId: params.eventId },
        threadKey: `organizer_approved:${params.eventId}`,
        groupKey: `cleanup_event:${params.eventId}`,
      })
      .catch((err: unknown) => {
        this.logger.warn(
          `Organizer approval notification failed: ${CleanupEventNotificationsService.formatDispatchErr(err)}`,
        );
      });
  }

  async notifyOrganizerDeclined(params: {
    organizerId: string;
    eventId: string;
    title: string;
  }): Promise<void> {
    const localeByUser = await notificationLocalesByUserId(this.prisma, [params.organizerId]);
    const locale = localeByUser.get(params.organizerId) ?? 'mk';
    const { title, body } = cleanupOrganizerDeclinedPush(locale, params.title);
    void this.dispatcher
      .dispatchToUser(params.organizerId, {
        title,
        body,
        type: NotificationType.CLEANUP_EVENT,
        data: { kind: 'declined', eventId: params.eventId },
        threadKey: `organizer_declined:${params.eventId}`,
        groupKey: `cleanup_event:${params.eventId}`,
      })
      .catch((err: unknown) => {
        this.logger.warn(
          `Organizer decline notification failed: ${CleanupEventNotificationsService.formatDispatchErr(err)}`,
        );
      });
  }

  private async resolveSiteEngagedUserIds(
    siteId: string,
    organizerId: string | null,
  ): Promise<string[]> {
    const [savers, reports, coAuthors, participants] = await Promise.all([
      this.prisma.siteSave.findMany({
        where: { siteId },
        select: { userId: true },
        take: 200,
      }),
      this.prisma.report.findMany({
        where: { siteId, reporterId: { not: null } },
        select: { reporterId: true },
        take: 400,
      }),
      this.prisma.reportCoReporter.findMany({
        where: { report: { siteId } },
        select: { userId: true },
        take: 400,
      }),
      this.prisma.eventParticipant.findMany({
        where: { event: { siteId } },
        select: { userId: true },
        take: 400,
      }),
    ]);

    const ids = new Set<string>();
    for (const r of savers) {
      ids.add(r.userId);
    }
    for (const r of reports) {
      if (r.reporterId != null) {
        ids.add(r.reporterId);
      }
    }
    for (const r of coAuthors) {
      ids.add(r.userId);
    }
    for (const r of participants) {
      ids.add(r.userId);
    }
    if (organizerId != null) {
      ids.delete(organizerId);
    }
    return [...ids].slice(0, MAX_PUBLISH_RECIPIENTS);
  }
}
