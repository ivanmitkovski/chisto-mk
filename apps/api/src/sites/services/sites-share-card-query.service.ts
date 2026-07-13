import { Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SiteStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import type { SitePublicShareCardResponseDto } from '../dto/site-public-share-card.dto';
import {
  buildShareEvents,
  buildShareReporter,
  collectShareMediaUrls,
  pickPrimaryShareReport,
  publicShareDescription,
  publicShareSiteLabel,
  publicShareTitle,
} from '../util/sites-share-card.helpers';
import {
  collectCleanupEvidenceUrls,
  findPublicShareSiteRow,
} from '../util/sites-share-card-query.loader';
import {
  publicShareAvatarUrl,
  publicShareEvidenceUrl,
  publicShareMediaUrl,
  resolvePublicApiV1Base,
  shareMediaRedirectMaxAgeSeconds,
} from '../util/sites-share-public-media-url';

@Injectable()
export class SitesShareCardQueryService {
  private readonly publicApiV1Base: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUpload: ReportsUploadService,
    configService: ConfigService,
  ) {
    this.publicApiV1Base = resolvePublicApiV1Base(
      configService.get<string>('EMAIL_PUBLIC_API_BASE_URL'),
    );
  }

  /**
   * Public fields for HTTPS share landing (`GET /sites/:id/share-card`).
   * Media URLs are stable API redirects (never embed expiring S3 signatures in ISR HTML).
   */
  async findPublicShareCard(id: string): Promise<SitePublicShareCardResponseDto> {
    const row = await this.requirePublicShareSite(id);
    const primaryReport = pickPrimaryShareReport(row.heroReport, row.reports);
    const title = publicShareTitle(row.heroReport, row.reports, row.description);
    const siteLabel = publicShareSiteLabel(row);
    const description = publicShareDescription(row.description, primaryReport);
    const rawMedia = collectShareMediaUrls(row.heroReport, row.reports);
    const evidenceRaw =
      row.status === SiteStatus.CLEANED
        ? await collectCleanupEvidenceUrls(this.prisma, this.reportsUpload, id, row.resolutions)
        : [];

    const mediaUrls = rawMedia.map((_, index) =>
      publicShareMediaUrl(this.publicApiV1Base, row.id, index),
    );
    const cleanupEvidenceUrls = evidenceRaw.map((_, index) =>
      publicShareEvidenceUrl(this.publicApiV1Base, row.id, index),
    );
    const hasAvatar = Boolean(primaryReport?.reporter?.avatarObjectKey?.trim());
    const reporter = buildShareReporter(primaryReport, new Map());
    if (reporter != null && hasAvatar) {
      reporter.avatarUrl = publicShareAvatarUrl(this.publicApiV1Base, row.id);
    }

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
      events: buildShareEvents(row.events, siteLabel),
      cleanupEvidenceUrls,
      ogImageUrl: mediaUrls[0] ?? cleanupEvidenceUrls[0] ?? null,
    };
  }

  /** Fresh signed GET for share gallery slot — used by public media redirect. */
  async getShareMediaSignedUrl(siteId: string, index: number): Promise<string> {
    const row = await this.requirePublicShareSite(siteId);
    const rawMedia = collectShareMediaUrls(row.heroReport, row.reports);
    return this.signRawUrlAtIndex(rawMedia, index, 'SITE_SHARE_MEDIA_NOT_FOUND');
  }

  /** Fresh signed GET for cleanup evidence slot. */
  async getShareEvidenceSignedUrl(siteId: string, index: number): Promise<string> {
    const row = await this.requirePublicShareSite(siteId);
    if (row.status !== SiteStatus.CLEANED) {
      throw new NotFoundException({
        code: 'SITE_SHARE_EVIDENCE_NOT_FOUND',
        message: 'Cleanup evidence not found',
      });
    }
    const evidenceRaw = await collectCleanupEvidenceUrls(
      this.prisma,
      this.reportsUpload,
      siteId,
      row.resolutions,
    );
    return this.signRawUrlAtIndex(evidenceRaw, index, 'SITE_SHARE_EVIDENCE_NOT_FOUND');
  }

  /** Fresh signed GET for the primary reporter avatar on a public share card. */
  async getShareAvatarSignedUrl(siteId: string): Promise<string> {
    const row = await this.requirePublicShareSite(siteId);
    const primary = pickPrimaryShareReport(row.heroReport, row.reports);
    const key = primary?.reporter?.avatarObjectKey?.trim() ?? null;
    if (key == null || key.length === 0) {
      throw new NotFoundException({
        code: 'SITE_SHARE_AVATAR_NOT_FOUND',
        message: 'Share avatar not found',
      });
    }
    const signed = await this.reportsUpload.signPrivateObjectKey(key);
    if (signed == null || signed.length === 0) {
      throw new NotFoundException({
        code: 'SITE_SHARE_AVATAR_NOT_FOUND',
        message: 'Share avatar not available',
      });
    }
    return signed;
  }

  getMediaRedirectMaxAgeSeconds(): number {
    return shareMediaRedirectMaxAgeSeconds(this.reportsUpload.getSignedUrlTtlSeconds());
  }

  private async signRawUrlAtIndex(
    rawUrls: string[],
    index: number,
    notFoundCode: string,
  ): Promise<string> {
    if (!Number.isInteger(index) || index < 0 || index >= rawUrls.length) {
      throw new NotFoundException({
        code: notFoundCode,
        message: 'Media not found',
      });
    }
    const signed = await this.reportsUpload.signUrls([rawUrls[index]!]);
    const url = signed[0];
    if (url == null || url.length === 0) {
      throw new NotFoundException({
        code: notFoundCode,
        message: 'Media not available',
      });
    }
    return url;
  }

  private async requirePublicShareSite(id: string) {
    const row = await findPublicShareSiteRow(this.prisma, id);
    if (row == null) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: 'Site not found',
      });
    }
    return row;
  }
}
