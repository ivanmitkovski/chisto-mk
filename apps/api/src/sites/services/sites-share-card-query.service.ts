import { Injectable, NotFoundException } from '@nestjs/common';
import {
  CleanupEventStatus,
  EcoEventLifecycleStatus,
  EventEvidenceKind,
  ReportStatus,
  SiteResolutionStatus,
  SiteStatus,
  UserStatus,
} from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { projectPublicReporter } from '../../common/projections/public-identity.projection';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import {
  signPrivateObjectKeysDeduped,
  signPublicMediaUrlsDeduped,
} from '../../storage/util/batch-private-object-sign';
import type {
  SitePublicShareCardResponseDto,
  SitePublicShareEventDto,
  SitePublicShareReporterDto,
} from '../dto/site-public-share-card.dto';

const MEDIA_CAP = 12;
const EVENTS_CAP = 5;
const EVIDENCE_CAP = 12;

type ApprovedReportRow = {
  title: string;
  description: string | null;
  mediaUrls: string[];
  category: string | null;
  severity: number | null;
  cleanupEffort: string | null;
  createdAt: Date;
  reporterId: string | null;
  reporter: {
    firstName: string;
    lastName: string;
    avatarObjectKey: string | null;
    status: UserStatus;
  } | null;
};

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
          take: EVENTS_CAP,
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

    const primaryReport = this.pickPrimaryReport(row.heroReport, row.reports);
    const title = this.publicShareTitle(row.heroReport, row.reports, row.description);
    const siteLabel = this.publicShareSiteLabel(row);
    const description = this.publicDescription(row.description, primaryReport);

    const rawMedia = this.collectMediaUrls(row.heroReport, row.reports);
    const evidenceRaw =
      row.status === SiteStatus.CLEANED
        ? await this.collectCleanupEvidenceUrls(id, row.resolutions)
        : [];

    const flatToSign = [...rawMedia, ...evidenceRaw];
    const avatarKey = primaryReport?.reporter?.avatarObjectKey ?? null;

    const [mediaByUrl, avatarByKey] = await Promise.all([
      signPublicMediaUrlsDeduped(flatToSign, (urls) => this.reportsUpload.signUrls(urls)),
      signPrivateObjectKeysDeduped([avatarKey], (k) => this.reportsUpload.signPrivateObjectKey(k)),
    ]);

    const mediaUrls = rawMedia.map((u) => mediaByUrl.get(u) ?? u);
    const cleanupEvidenceUrls = evidenceRaw.map((u) => mediaByUrl.get(u) ?? u);
    const ogImageUrl = mediaUrls[0] ?? cleanupEvidenceUrls[0] ?? null;

    const reporter = this.buildReporter(primaryReport, avatarByKey);
    const events = this.buildEvents(row.events, siteLabel);

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
      reporter,
      events,
      cleanupEvidenceUrls,
      ogImageUrl,
    };
  }

  /** Resolution + event after-photos, aligned with SiteCleanupEvidenceService sources. */
  private async collectCleanupEvidenceUrls(
    siteId: string,
    resolutions: { mediaUrls: string[] }[],
  ): Promise<string[]> {
    const seen = new Set<string>();
    const out: string[] = [];
    const push = (url: string | null | undefined) => {
      const u = typeof url === 'string' ? url.trim() : '';
      if (u.length === 0 || seen.has(u)) return;
      seen.add(u);
      out.push(u);
    };

    for (const resolution of resolutions) {
      for (const url of resolution.mediaUrls ?? []) {
        push(url);
        if (out.length >= EVIDENCE_CAP) return out;
      }
    }

    const events = await this.prisma.cleanupEvent.findMany({
      where: { siteId },
      select: {
        afterImageKeys: true,
        evidencePhotos: {
          where: { kind: EventEvidenceKind.AFTER },
          select: { objectKey: true },
          take: EVIDENCE_CAP,
        },
      },
      take: 20,
    });

    for (const event of events) {
      for (const key of event.afterImageKeys) {
        const publicUrl = this.reportsUpload.getPublicUrlsForKeys([key])[0] ?? key;
        push(publicUrl);
        if (out.length >= EVIDENCE_CAP) return out;
      }
      for (const photo of event.evidencePhotos) {
        const publicUrl =
          this.reportsUpload.getPublicUrlsForKeys([photo.objectKey])[0] ?? photo.objectKey;
        push(publicUrl);
        if (out.length >= EVIDENCE_CAP) return out;
      }
    }

    return out;
  }

  private pickPrimaryReport(
    hero: ApprovedReportRow | null,
    reports: ApprovedReportRow[],
  ): ApprovedReportRow | null {
    if (hero != null) return hero;
    return reports[0] ?? null;
  }

  private publicShareTitle(
    hero: { title: string } | null,
    reports: { title: string }[],
    description: string | null,
  ): string {
    const heroTitle = hero?.title?.trim();
    if (heroTitle != null && heroTitle.length > 0) {
      return heroTitle;
    }
    const reportTitle = reports[0]?.title?.trim();
    if (reportTitle != null && reportTitle.length > 0) {
      return reportTitle;
    }
    const desc = description?.trim();
    if (desc != null && desc.length > 0) {
      return desc.length > 120 ? `${desc.slice(0, 117)}…` : desc;
    }
    return 'Pollution site';
  }

  private publicShareSiteLabel(site: {
    address: string | null;
    description: string | null;
  }): string {
    const address = site.address?.trim();
    if (address != null && address.length > 0) {
      return address;
    }
    const description = site.description?.trim();
    if (description != null && description.length > 0) {
      return description.length > 120 ? `${description.slice(0, 117)}…` : description;
    }
    return 'Site';
  }

  private publicDescription(
    siteDescription: string | null,
    primary: ApprovedReportRow | null,
  ): string | null {
    const fromReport = primary?.description?.trim();
    if (fromReport != null && fromReport.length > 0) {
      return fromReport;
    }
    const fromSite = siteDescription?.trim();
    if (fromSite != null && fromSite.length > 0) {
      return fromSite;
    }
    return null;
  }

  private collectMediaUrls(
    hero: { mediaUrls: string[] } | null,
    reports: { mediaUrls: string[] }[],
  ): string[] {
    const seen = new Set<string>();
    const out: string[] = [];
    const push = (urls: string[] | undefined) => {
      for (const raw of urls ?? []) {
        const u = typeof raw === 'string' ? raw.trim() : '';
        if (u.length === 0 || seen.has(u)) continue;
        seen.add(u);
        out.push(u);
        if (out.length >= MEDIA_CAP) return;
      }
    };
    push(hero?.mediaUrls);
    for (const r of reports) {
      if (out.length >= MEDIA_CAP) break;
      push(r.mediaUrls);
    }
    return out;
  }

  private buildReporter(
    primary: ApprovedReportRow | null,
    avatarByKey: Map<string, string | null>,
  ): SitePublicShareReporterDto | null {
    if (primary == null) return null;
    const view = projectPublicReporter(primary.reporterId, primary.reporter, undefined, false);
    if (view == null) return null;
    const key = primary.reporter?.avatarObjectKey ?? null;
    return {
      displayLabel: view.displayLabel,
      avatarUrl: key != null ? (avatarByKey.get(key) ?? null) : null,
      isDeleted: view.isDeleted,
      isAnonymous: view.isAnonymous,
    };
  }

  private buildEvents(
    events: {
      id: string;
      title: string;
      scheduledAt: Date;
      participantCount: number;
      maxParticipants: number | null;
      lifecycleStatus: EcoEventLifecycleStatus;
    }[],
    city: string,
  ): SitePublicShareEventDto[] {
    return events.map((e) => ({
      id: e.id,
      title: e.title,
      scheduledAt: e.scheduledAt.toISOString(),
      city,
      participantCount: e.participantCount,
      maxParticipants: e.maxParticipants,
      status: e.lifecycleStatus,
    }));
  }
}
