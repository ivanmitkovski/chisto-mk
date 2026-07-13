import { Injectable, NotFoundException } from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  EventEvidenceKind,
  ReportStatus,
  SiteResolutionStatus,
  SiteStatus,
} from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import {
  signPrivateObjectKeysDeduped,
  signPublicMediaUrlsDeduped,
} from '../../storage/util/batch-private-object-sign';
import type { SitePublicShareCardResponseDto } from '../dto/site-public-share-card.dto';
import {
  SHARE_CARD_EVIDENCE_CAP,
  SHARE_CARD_EVENTS_CAP,
  buildShareEvents,
  buildShareReporter,
  collectShareMediaUrls,
  pickPrimaryShareReport,
  publicShareDescription,
  publicShareSiteLabel,
  publicShareTitle,
  pushUniqueUrls,
} from '../util/sites-share-card.helpers';

@Injectable()
export class SitesShareCardQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUpload: ReportsUploadService,
  ) {}

  /**
   * Public fields for HTTPS share landing (`GET /sites/:id/share-card`).
   * Public map visibility only (non-REPORTED, not admin-archived; no reporter ids/emails).
   */
  async findPublicShareCard(id: string): Promise<SitePublicShareCardResponseDto> {
    const row = await this.prisma.site.findFirst({
      where: {
        id,
        status: { not: SiteStatus.REPORTED },
        isArchivedByAdmin: false,
      },
      select: {
        id: true,
        address: true,
        description: true,
        status: true,
        latitude: true,
        longitude: true,
        upvotesCount: true,
        commentsCount: true,
        sharesCount: true,
        savesCount: true,
        heroReport: {
          select: {
            title: true,
            description: true,
            mediaUrls: true,
            category: true,
            severity: true,
            cleanupEffort: true,
            createdAt: true,
            reporterId: true,
            reporter: {
              select: {
                firstName: true,
                lastName: true,
                avatarObjectKey: true,
                status: true,
              },
            },
          },
        },
        reports: {
          where: { status: ReportStatus.APPROVED },
          orderBy: { createdAt: 'asc' },
          take: 8,
          select: {
            title: true,
            description: true,
            mediaUrls: true,
            category: true,
            severity: true,
            cleanupEffort: true,
            createdAt: true,
            reporterId: true,
            reporter: {
              select: {
                firstName: true,
                lastName: true,
                avatarObjectKey: true,
                status: true,
              },
            },
          },
        },
        events: {
          where: {
            status: CleanupEventStatus.APPROVED,
            lifecycleStatus: {
              in: [EcoEventLifecycleStatus.UPCOMING, EcoEventLifecycleStatus.IN_PROGRESS],
            },
          },
          orderBy: { scheduledAt: 'asc' },
          take: SHARE_CARD_EVENTS_CAP,
          select: {
            id: true,
            title: true,
            scheduledAt: true,
            participantCount: true,
            maxParticipants: true,
            lifecycleStatus: true,
          },
        },
        resolutions: {
          where: { status: SiteResolutionStatus.APPROVED },
          orderBy: { createdAt: 'asc' },
          take: 6,
          select: { mediaUrls: true },
        },
      },
    });
    if (row == null) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: 'Site not found',
      });
    }

    const primaryReport = pickPrimaryShareReport(row.heroReport, row.reports);
    const title = publicShareTitle(row.heroReport, row.reports, row.description);
    const siteLabel = publicShareSiteLabel(row);
    const description = publicShareDescription(row.description, primaryReport);
    const rawMedia = collectShareMediaUrls(row.heroReport, row.reports);
    const evidenceRaw =
      row.status === SiteStatus.CLEANED
        ? await this.collectCleanupEvidenceUrls(id, row.resolutions)
        : [];

    const avatarKey = primaryReport?.reporter?.avatarObjectKey ?? null;
    const [mediaByUrl, avatarByKey] = await Promise.all([
      signPublicMediaUrlsDeduped([...rawMedia, ...evidenceRaw], (urls) =>
        this.reportsUpload.signUrls(urls),
      ),
      signPrivateObjectKeysDeduped([avatarKey], (k) => this.reportsUpload.signPrivateObjectKey(k)),
    ]);

    const mediaUrls = rawMedia.map((u) => mediaByUrl.get(u) ?? u);
    const cleanupEvidenceUrls = evidenceRaw.map((u) => mediaByUrl.get(u) ?? u);

    return {
      id: row.id,
      title,
      siteLabel,
      status: row.status,
      description,
      address: row.address?.trim() || null,
      latitude: row.latitude,
      longitude: row.longitude,
      mediaUrls,
      category: primaryReport?.category ?? null,
      severity: primaryReport?.severity ?? null,
      cleanupEffort: primaryReport?.cleanupEffort ?? null,
      upvotesCount: row.upvotesCount,
      commentsCount: row.commentsCount,
      sharesCount: row.sharesCount,
      savesCount: row.savesCount,
      reportedAt: primaryReport?.createdAt?.toISOString() ?? null,
      reporter: buildShareReporter(primaryReport, avatarByKey),
      events: buildShareEvents(row.events, siteLabel),
      cleanupEvidenceUrls,
      ogImageUrl: mediaUrls[0] ?? cleanupEvidenceUrls[0] ?? null,
    };
  }

  /** Resolution + event after-photos, aligned with SiteCleanupEvidenceService sources. */
  private async collectCleanupEvidenceUrls(
    siteId: string,
    resolutions: { mediaUrls: string[] }[],
  ): Promise<string[]> {
    const seen = new Set<string>();
    const out: string[] = [];
    for (const resolution of resolutions) {
      pushUniqueUrls(out, seen, resolution.mediaUrls ?? [], SHARE_CARD_EVIDENCE_CAP);
      if (out.length >= SHARE_CARD_EVIDENCE_CAP) return out;
    }

    const events = await this.prisma.cleanupEvent.findMany({
      where: { siteId },
      select: {
        afterImageKeys: true,
        evidencePhotos: {
          where: { kind: EventEvidenceKind.AFTER },
          select: { objectKey: true },
          take: SHARE_CARD_EVIDENCE_CAP,
        },
      },
      take: 20,
    });

    for (const event of events) {
      const fromKeys = event.afterImageKeys.map(
        (key) => this.reportsUpload.getPublicUrlsForKeys([key])[0] ?? key,
      );
      pushUniqueUrls(out, seen, fromKeys, SHARE_CARD_EVIDENCE_CAP);
      if (out.length >= SHARE_CARD_EVIDENCE_CAP) return out;

      const fromPhotos = event.evidencePhotos.map(
        (photo) =>
          this.reportsUpload.getPublicUrlsForKeys([photo.objectKey])[0] ?? photo.objectKey,
      );
      pushUniqueUrls(out, seen, fromPhotos, SHARE_CARD_EVIDENCE_CAP);
      if (out.length >= SHARE_CARD_EVIDENCE_CAP) return out;
    }

    return out;
  }
}
