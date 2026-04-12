import { Injectable } from '@nestjs/common';
import { CleanupEventStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import {
  categoryToMobile,
  difficultyToMobile,
  lifecycleToMobile,
  scaleToMobile,
} from './events-mobile.mapper';
import type { LoadedEvent } from './events-query.include';

@Injectable()
export class EventsMobileMapperService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly uploads: ReportsUploadService,
  ) {}

  async toMobileEvent(row: LoadedEvent): Promise<Record<string, unknown>> {
    const participant = row.participants[0];
    const viewerCheckIn = row.checkIns[0];
    const isJoined = participant != null;
    const reminderEnabled = participant?.reminderEnabled ?? false;
    const reminderAt = participant?.reminderAt ?? null;

    const signedAfter = await this.uploads.signUrls(
      this.uploads.getPublicUrlsForKeys(row.afterImageKeys),
    );

    const organizerName = row.organizer
      ? `${row.organizer.firstName} ${row.organizer.lastName}`.trim()
      : '';

    const organizerAvatarUrl = row.organizer
      ? await this.uploads.signPrivateObjectKey(row.organizer.avatarObjectKey)
      : null;

    let recurrenceSeriesTotal: number | null = null;
    let recurrenceSeriesPosition: number | null = null;
    let recurrencePrevEventId: string | null = null;
    let recurrenceNextEventId: string | null = null;

    if (row.recurrenceRule != null || row.parentEventId != null) {
      const rootId = row.parentEventId ?? row.id;
      const series = await this.prisma.cleanupEvent.findMany({
        where: {
          OR: [{ id: rootId }, { parentEventId: rootId }],
        },
        select: { id: true, scheduledAt: true },
        orderBy: [{ scheduledAt: 'asc' }, { id: 'asc' }],
      });
      const total = series.length;
      const idx = series.findIndex((s) => s.id === row.id);
      recurrenceSeriesTotal = total;
      if (idx >= 0) {
        recurrenceSeriesPosition = idx + 1;
        if (idx > 0) {
          recurrencePrevEventId = series[idx - 1]!.id;
        }
        if (idx < total - 1) {
          recurrenceNextEventId = series[idx + 1]!.id;
        }
      }
    }

    return {
      id: row.id,
      title: row.title,
      description: row.description,
      category: categoryToMobile(row.category),
      moderationApproved: row.status === CleanupEventStatus.APPROVED,
      siteId: row.siteId,
      siteName: this.siteDisplayName(row.site),
      siteImageUrl: await this.resolveSiteCoverImageUrl(row.site),
      siteDistanceKm: 0,
      siteLat: row.site?.latitude ?? null,
      siteLng: row.site?.longitude ?? null,
      organizerId: row.organizerId ?? '',
      organizerName,
      organizerAvatarUrl,
      scheduledAt: row.scheduledAt.toISOString(),
      endAt: row.endAt?.toISOString() ?? null,
      status: lifecycleToMobile(row.lifecycleStatus),
      participantCount: row.participantCount,
      maxParticipants: row.maxParticipants,
      isJoined,
      gear: row.gear,
      scale: scaleToMobile(row.scale),
      difficulty: difficultyToMobile(row.difficulty),
      reminderEnabled,
      reminderAt: reminderAt?.toISOString() ?? null,
      afterImagePaths: signedAfter,
      createdAt: row.createdAt.toISOString(),
      activeCheckInSessionId: row.checkInSessionId,
      isCheckInOpen: row.checkInOpen,
      checkedInCount: row.checkedInCount,
      attendeeCheckInStatus:
        viewerCheckIn != null ? 'checkedIn' : 'notCheckedIn',
      attendeeCheckedInAt: viewerCheckIn?.checkedInAt.toISOString() ?? null,
      recurrenceRule: row.recurrenceRule ?? null,
      parentEventId: row.parentEventId ?? null,
      recurrenceIndex: row.recurrenceIndex ?? null,
      recurrenceSeriesTotal,
      recurrenceSeriesPosition,
      recurrencePrevEventId,
      recurrenceNextEventId,
    };
  }

  private siteDisplayName(site: LoadedEvent['site']): string {
    const a = site.address?.trim();
    if (a != null && a.length > 0) {
      return a;
    }
    const d = site.description?.trim();
    if (d != null && d.length > 0) {
      return d;
    }
    return 'Site';
  }

  private pickFirstSiteReportMediaUrl(site: LoadedEvent['site']): string {
    const urls = site.reports[0]?.mediaUrls;
    if (urls == null || urls.length === 0) {
      return '';
    }
    for (const raw of urls) {
      const t = typeof raw === 'string' ? raw.trim() : '';
      if (t.length > 0) {
        return t;
      }
    }
    return '';
  }

  private async resolveSiteCoverImageUrl(site: LoadedEvent['site']): Promise<string> {
    const raw = this.pickFirstSiteReportMediaUrl(site);
    if (raw.length === 0) {
      return '';
    }
    const urls =
      raw.startsWith('http://') || raw.startsWith('https://')
        ? [raw]
        : this.uploads.getPublicUrlsForKeys([raw]);
    const signed = await this.uploads.signUrls(urls);
    return signed[0] ?? raw;
  }
}
