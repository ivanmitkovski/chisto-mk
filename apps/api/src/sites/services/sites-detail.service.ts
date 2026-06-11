import { Injectable, NotFoundException } from '@nestjs/common';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import {
  signPrivateObjectKeysDeduped,
  signPublicMediaUrlsDeduped,
} from '../../storage/util/batch-private-object-sign';
import { SiteStatus } from '../../prisma-client';
import { SiteDetailRepository } from '../repositories/site-detail.repository';
import { buildSiteCoReporterSummaries } from '../util/site-co-reporter-summaries.util';
import { projectPublicReporter, viewerIsModerator } from '../../common/projections/public-identity.projection';

@Injectable()
export class SitesDetailService {
  private static readonly DETAIL_REPORTS_LIMIT = 50;
  private static readonly DETAIL_EVENTS_LIMIT = 50;

  constructor(
    private readonly siteDetailRepository: SiteDetailRepository,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  async findOne(
    siteId: string,
    user?: AuthenticatedUser,
  ) {
    const site = await this.siteDetailRepository.findByIdWithRelations(
      siteId,
      SitesDetailService.DETAIL_REPORTS_LIMIT,
      SitesDetailService.DETAIL_EVENTS_LIMIT,
    );

    if (!site) {
      throw new NotFoundException({
        code: 'SITE_NOT_FOUND',
        message: `Site with id '${siteId}' was not found`,
      });
    }

    if (site.status === SiteStatus.REPORTED) {
      const viewerUserId = user?.userId ?? null;
      if (!viewerUserId) {
        throw new NotFoundException({
          code: 'SITE_NOT_FOUND',
          message: `Site with id '${siteId}' was not found`,
        });
      }
      const canView = await this.siteDetailRepository.viewerCanAccessReportedSite(
        siteId,
        viewerUserId,
      );
      if (!canView) {
        throw new NotFoundException({
          code: 'SITE_NOT_FOUND',
          message: `Site with id '${siteId}' was not found`,
        });
      }
    }

    const [reportsTotal, eventsTotal] = await Promise.all([
      this.siteDetailRepository.countReports(siteId),
      this.siteDetailRepository.countEvents(siteId),
    ]);

    const privateKeys: (string | null | undefined)[] = [];
    const flatMedia: string[] = [];
    privateKeys.push(site.heroReport?.reporter?.avatarObjectKey);
    for (const r of site.reports) {
      privateKeys.push(r.reporter?.avatarObjectKey);
      for (const cr of r.coReporters) {
        privateKeys.push(cr.user?.avatarObjectKey);
      }
      for (const u of r.mediaUrls ?? []) {
        if (typeof u === 'string' && u.trim().length > 0) {
          flatMedia.push(u.trim());
        }
      }
    }
    for (const u of site.heroReport?.mediaUrls ?? []) {
      if (typeof u === 'string' && u.trim().length > 0) {
        flatMedia.push(u.trim());
      }
    }
    const [avatarUrlByKey, mediaUrlByOriginal] = await Promise.all([
      signPrivateObjectKeysDeduped(privateKeys, (k) => this.reportsUploadService.signPrivateObjectKey(k)),
      signPublicMediaUrlsDeduped(flatMedia, (urls) => this.reportsUploadService.signUrls(urls)),
    ]);

    const isModerator = viewerIsModerator(user?.role);
    const reportsWithSignedUrls = site.reports.map((r) => {
      const mediaUrls = (r.mediaUrls ?? []).map((u) => {
        const t = typeof u === 'string' ? u.trim() : '';
        if (t.length === 0) return u;
        return mediaUrlByOriginal.get(t) ?? u;
      });
      const reporterPublic = projectPublicReporter(r.reporterId, r.reporter, user, isModerator);
      const reporter =
        reporterPublic == null
          ? null
          : {
              displayLabel: reporterPublic.displayLabel ?? 'Anonymous',
              isSelf: reporterPublic.isSelf,
              isDeleted: reporterPublic.isDeleted,
              isAnonymous: reporterPublic.isAnonymous,
              firstName: r.reporter?.firstName ?? '',
              lastName: r.reporter?.lastName ?? '',
              avatarUrl: r.reporter?.avatarObjectKey
                ? (avatarUrlByKey.get(r.reporter.avatarObjectKey) ?? null)
                : null,
            };
      const coReporters = r.coReporters.map((cr) => {
        const coPublic = projectPublicReporter(cr.userId, cr.user, user, isModerator);
        return {
          id: cr.id,
          createdAt: cr.createdAt,
          reportedAt: cr.reportedAt,
          reportId: cr.reportId,
          ...(isModerator || coPublic?.isSelf ? { userId: cr.userId } : {}),
          displayLabel: coPublic?.displayLabel ?? 'Anonymous',
          isDeleted: coPublic?.isDeleted ?? false,
          isAnonymous: coPublic?.isAnonymous ?? false,
          user: cr.user
            ? {
                displayLabel: coPublic?.displayLabel ?? 'Anonymous',
                isDeleted: coPublic?.isDeleted ?? false,
                isAnonymous: coPublic?.isAnonymous ?? false,
                firstName: cr.user.firstName,
                lastName: cr.user.lastName,
                avatarUrl: cr.user.avatarObjectKey
                  ? (avatarUrlByKey.get(cr.user.avatarObjectKey) ?? null)
                  : null,
              }
            : null,
        };
      });
      return {
        id: r.id,
        createdAt: r.createdAt,
        reportNumber: r.reportNumber,
        siteId: r.siteId,
        ...(isModerator || user?.userId === r.reporterId ? { reporterId: r.reporterId } : {}),
        title: r.title,
        description: r.description,
        mediaUrls,
        category: r.category,
        severity: r.severity,
        cleanupEffort: r.cleanupEffort,
        status: r.status,
        moderatedAt: r.moderatedAt,
        moderationReason: r.moderationReason,
        moderatedById: r.moderatedById,
        potentialDuplicateOfId: r.potentialDuplicateOfId,
        reporter,
        coReporters,
        mergedDuplicateChildCount: r.mergedDuplicateChildCount,
      };
    });

    const mergedDuplicateChildCountTotal = reportsWithSignedUrls.reduce(
      (n, r) => n + (r.mergedDuplicateChildCount ?? 0),
      0,
    );

    let isUpvotedByMe = false;
    let isSavedByMe = false;
    if (user) {
      const [vote, save] = await Promise.all([
        this.siteDetailRepository.findVoteBySiteAndUser(siteId, user.userId),
        this.siteDetailRepository.findSaveBySiteAndUser(siteId, user.userId),
      ]);
      isUpvotedByMe = Boolean(vote);
      isSavedByMe = Boolean(save);
    }

    const coReporterSummaries = isModerator
      ? buildSiteCoReporterSummaries(
          site.reports.map((r) => ({
            coReporters: r.coReporters.map((cr) => ({
              userId: cr.userId,
              reportedAt: cr.reportedAt,
              user: cr.user
                ? {
                    firstName: cr.user.firstName,
                    lastName: cr.user.lastName,
                    status: cr.user.status,
                    avatarUrl: cr.user.avatarObjectKey
                      ? (avatarUrlByKey.get(cr.user.avatarObjectKey) ?? null)
                      : null,
                  }
                : null,
            })),
          })),
        )
      : [];

    const canonicalReportId = site.heroReportId ?? null;
    const heroMediaUrls = (site.heroReport?.mediaUrls ?? []).map((u) => {
      const t = typeof u === 'string' ? u.trim() : '';
      if (t.length === 0) return u;
      return mediaUrlByOriginal.get(t) ?? u;
    });
    const heroReporterRaw = site.heroReport?.reporter ?? null;
    const heroReporterPublic = projectPublicReporter(
      site.heroReport?.reporterId ?? null,
      heroReporterRaw,
      user,
      isModerator,
    );
    const heroReporter =
      heroReporterPublic == null
        ? null
        : {
            displayLabel: heroReporterPublic.displayLabel ?? 'Anonymous',
            isSelf: heroReporterPublic.isSelf,
            isDeleted: heroReporterPublic.isDeleted,
            isAnonymous: heroReporterPublic.isAnonymous,
            firstName: heroReporterRaw?.firstName ?? '',
            lastName: heroReporterRaw?.lastName ?? '',
            avatarUrl: heroReporterRaw?.avatarObjectKey
              ? (avatarUrlByKey.get(heroReporterRaw.avatarObjectKey) ?? null)
              : null,
          };

    return {
      ...site,
      reports: reportsWithSignedUrls,
      canonicalReportId,
      heroMediaUrls,
      heroReporter,
      hasMoreReports: reportsTotal > reportsWithSignedUrls.length,
      hasMoreEvents: eventsTotal > site.events.length,
      coReporterNames: coReporterSummaries.map((s) => s.name),
      coReporterSummaries,
      mergedDuplicateChildCountTotal,
      upvotesCount: site.upvotesCount,
      commentsCount: site.commentsCount,
      savesCount: site.savesCount,
      sharesCount: site.sharesCount,
      isUpvotedByMe,
      isSavedByMe,
    };
  }
}
