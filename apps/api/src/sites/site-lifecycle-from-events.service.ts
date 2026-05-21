import { Injectable } from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  SiteStatus,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { SiteEventsService } from '../admin-realtime/site-events.service';
import { SiteHistoryWriterService } from './history/site-history-writer.service';
import { SiteHistoryEventRecorderService } from './history/site-history-event-recorder.service';
import { SitesFeedService } from './sites-feed.service';
import { SitesMapQueryService } from './sites-map-query.service';
import type { Prisma } from '../prisma-client';

const FLAG_KEY = 'site_lifecycle_from_events';

const SCHEDULE_FROM: SiteStatus[] = [SiteStatus.REPORTED, SiteStatus.VERIFIED];
const IN_PROGRESS_FROM: SiteStatus[] = [
  SiteStatus.REPORTED,
  SiteStatus.VERIFIED,
  SiteStatus.CLEANUP_SCHEDULED,
];
const REVERT_FROM: SiteStatus[] = [SiteStatus.CLEANUP_SCHEDULED, SiteStatus.IN_PROGRESS];

@Injectable()
export class SiteLifecycleFromEventsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly featureFlags: FeatureFlagsService,
    private readonly historyWriter: SiteHistoryWriterService,
    private readonly historyEventRecorder: SiteHistoryEventRecorderService,
    private readonly audit: AuditService,
    private readonly siteEventsService: SiteEventsService,
    private readonly sitesFeed: SitesFeedService,
    private readonly sitesMapQuery: SitesMapQueryService,
  ) {}

  async isEnabled(): Promise<boolean> {
    const map = await this.featureFlags.getPublicMap();
    return map[FLAG_KEY] === true;
  }

  async onEventLinkedToSite(
    siteId: string,
    cleanupEventId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<void> {
    if (!(await this.isEnabled())) return;

    const db = tx ?? this.prisma;
    const site = await db.site.findUnique({
      where: { id: siteId },
      select: { id: true, status: true },
    });
    if (!site || !SCHEDULE_FROM.includes(site.status)) {
      await this.historyEventRecorder.recordEventScheduled(
        { siteId, cleanupEventId, occurredAt: new Date() },
        tx,
      );
      return;
    }

    await this.applyStatusTransition({
      siteId,
      from: site.status,
      to: SiteStatus.CLEANUP_SCHEDULED,
      cleanupEventId,
      trigger: 'EVENT_SCHEDULED',
      ...(tx != null ? { tx } : {}),
    });
    await this.historyEventRecorder.recordEventScheduled(
      { siteId, cleanupEventId, occurredAt: new Date() },
      tx,
    );
  }

  async onEventLifecycleChanged(
    siteId: string,
    cleanupEventId: string,
    lifecycle: EcoEventLifecycleStatus,
    tx?: Prisma.TransactionClient,
  ): Promise<void> {
    if (!(await this.isEnabled())) {
      await this.recordLifecycleHistoryOnly(siteId, cleanupEventId, lifecycle, tx);
      return;
    }

    const now = new Date();
    if (lifecycle === EcoEventLifecycleStatus.IN_PROGRESS) {
      const site = await (tx ?? this.prisma).site.findUnique({
        where: { id: siteId },
        select: { status: true },
      });
      if (site && IN_PROGRESS_FROM.includes(site.status)) {
        await this.applyStatusTransition({
          siteId,
          from: site.status,
          to: SiteStatus.IN_PROGRESS,
          cleanupEventId,
          trigger: 'EVENT_STARTED',
          ...(tx != null ? { tx } : {}),
        });
      }
      await this.historyEventRecorder.recordEventStarted(
        { siteId, cleanupEventId, occurredAt: now },
        tx,
      );
      return;
    }

    if (lifecycle === EcoEventLifecycleStatus.COMPLETED) {
      await this.historyEventRecorder.recordEventCompleted(
        { siteId, cleanupEventId, occurredAt: now },
        tx,
      );
      return;
    }

    if (lifecycle === EcoEventLifecycleStatus.CANCELLED) {
      await this.historyEventRecorder.recordEventCancelled(
        { siteId, cleanupEventId, occurredAt: now },
        tx,
      );
      const hasOtherActive = await this.hasOtherActiveEvents(siteId, cleanupEventId, tx);
      if (!hasOtherActive) {
        const site = await (tx ?? this.prisma).site.findUnique({
          where: { id: siteId },
          select: { status: true },
        });
        if (site && REVERT_FROM.includes(site.status)) {
          await this.applyStatusTransition({
            siteId,
            from: site.status,
            to: SiteStatus.VERIFIED,
            cleanupEventId,
            trigger: 'EVENT_CANCELLED',
            ...(tx != null ? { tx } : {}),
          });
        }
      }
    }
  }

  private async recordLifecycleHistoryOnly(
    siteId: string,
    cleanupEventId: string,
    lifecycle: EcoEventLifecycleStatus,
    tx?: Prisma.TransactionClient,
  ): Promise<void> {
    const now = new Date();
    if (lifecycle === EcoEventLifecycleStatus.IN_PROGRESS) {
      await this.historyEventRecorder.recordEventStarted({ siteId, cleanupEventId, occurredAt: now }, tx);
    } else if (lifecycle === EcoEventLifecycleStatus.COMPLETED) {
      await this.historyEventRecorder.recordEventCompleted({ siteId, cleanupEventId, occurredAt: now }, tx);
    } else if (lifecycle === EcoEventLifecycleStatus.CANCELLED) {
      await this.historyEventRecorder.recordEventCancelled({ siteId, cleanupEventId, occurredAt: now }, tx);
    }
  }

  private async hasOtherActiveEvents(
    siteId: string,
    excludeEventId: string,
    tx?: Prisma.TransactionClient,
  ): Promise<boolean> {
    const db = tx ?? this.prisma;
    const count = await db.cleanupEvent.count({
      where: {
        siteId,
        id: { not: excludeEventId },
        status: CleanupEventStatus.APPROVED,
        lifecycleStatus: {
          in: [EcoEventLifecycleStatus.UPCOMING, EcoEventLifecycleStatus.IN_PROGRESS],
        },
      },
    });
    return count > 0;
  }

  private async applyStatusTransition(params: {
    siteId: string;
    from: SiteStatus;
    to: SiteStatus;
    cleanupEventId: string;
    trigger: string;
    tx?: Prisma.TransactionClient;
  }): Promise<void> {
    const { siteId, from, to, cleanupEventId, trigger, tx } = params;
    const db = tx ?? this.prisma;

    const site = await db.site.findUnique({
      where: { id: siteId },
      select: { status: true, latitude: true, longitude: true },
    });
    if (!site || site.status !== from) {
      return;
    }

    const updated = await db.site.update({
      where: { id: siteId },
      data: { status: to },
      select: {
        id: true,
        status: true,
        latitude: true,
        longitude: true,
        updatedAt: true,
      },
    });

    await this.historyWriter.recordStatusChanged(
      {
        siteId,
        fromStatus: from,
        toStatus: to,
        cleanupEventId,
        metadata: { trigger },
        actor: { userId: null, role: 'system' },
      },
      tx,
    );

    if (!tx) {
      await this.audit.log({
        actorId: null,
        action: 'SITE_STATUS_UPDATED',
        resourceType: 'Site',
        resourceId: siteId,
        metadata: { from, to, trigger, automated: true },
      });
      this.siteEventsService.emitSiteUpdated(siteId, {
        kind: 'status_changed',
        status: updated.status,
        latitude: updated.latitude,
        longitude: updated.longitude,
        updatedAt: updated.updatedAt,
      });
      this.sitesFeed.invalidateFeedCache('site_status_auto');
      this.sitesMapQuery.invalidateMapCache('site_status_auto', siteId);
      this.historyWriter.emitHistoryAppended(siteId, '');
    }
  }
}
