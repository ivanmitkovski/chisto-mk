import { Injectable, NotFoundException } from '@nestjs/common';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { SiteDetailRepository } from './repositories/site-detail.repository';

@Injectable()
export class SitesDetailService {
  private static readonly DETAIL_REPORTS_LIMIT = 50;
  private static readonly DETAIL_EVENTS_LIMIT = 50;

  constructor(
    private readonly siteDetailRepository: SiteDetailRepository,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  private buildSiteCoReporterSummaries(
    reports: Array<{
      coReporters: Array<{
        userId: string;
        reportedAt: Date;
        user: { firstName: string; lastName: string; avatarUrl: string | null } | null;
      }>;
    }>,
  ): { userId: string; name: string; avatarUrl: string | null }[] {
    const anonymous = 'Anonymous';
    const pickRicher = (a: string, b: string): string => {
      if (a === anonymous && b !== anonymous) return b;
      if (b === anonymous && a !== anonymous) return a;
      return a;
    };
    const pickAvatar = (a: string | null, b: string | null): string | null => {
      const x = a?.trim() ?? '';
      const y = b?.trim() ?? '';
      if (x.length > 0) return x;
      if (y.length > 0) return y;
      return null;
    };
    const display = (user: { firstName: string; lastName: string; avatarUrl: string | null } | null): string => {
      if (!user) return anonymous;
      const n = `${user.firstName} ${user.lastName}`.trim();
      return n.length > 0 ? n : anonymous;
    };
    const byUser = new Map<
      string,
      { name: string; reportedAt: Date; avatarUrl: string | null }
    >();
    for (const r of reports) {
      for (const cr of r.coReporters) {
        const name = display(cr.user);
        const reportedAt = cr.reportedAt;
        const avatarUrl = cr.user?.avatarUrl?.trim() ? cr.user.avatarUrl : null;
        const prev = byUser.get(cr.userId);
        if (!prev) {
          byUser.set(cr.userId, { name, reportedAt, avatarUrl });
          continue;
        }
        const incomingEarlier = reportedAt < prev.reportedAt;
        const nextAt = incomingEarlier ? reportedAt : prev.reportedAt;
        const nextName = incomingEarlier ? pickRicher(name, prev.name) : pickRicher(prev.name, name);
        const nextAvatar = incomingEarlier
          ? pickAvatar(avatarUrl, prev.avatarUrl)
          : pickAvatar(prev.avatarUrl, avatarUrl);
        byUser.set(cr.userId, { name: nextName, reportedAt: nextAt, avatarUrl: nextAvatar });
      }
    }
    return [...byUser.entries()]
      .sort(([, av], [, bv]) => {
        if (av.reportedAt < bv.reportedAt) return -1;
        if (av.reportedAt > bv.reportedAt) return 1;
        return av.name.localeCompare(bv.name);
      })
      .map(([userId, v]) => ({ userId, name: v.name, avatarUrl: v.avatarUrl }));
  }

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

    const [reportsTotal, eventsTotal] = await Promise.all([
      this.siteDetailRepository.countReports(siteId),
      this.siteDetailRepository.countEvents(siteId),
    ]);

    const reportsWithSignedUrls = await Promise.all(
      site.reports.map(async (r) => {
        const mediaUrls = await this.reportsUploadService.signUrls(r.mediaUrls);
        const reporter =
          r.reporter == null
            ? null
            : {
                firstName: r.reporter.firstName,
                lastName: r.reporter.lastName,
                avatarUrl: await this.reportsUploadService.signPrivateObjectKey(
                  r.reporter.avatarObjectKey,
                ),
              };
        const coReporters = await Promise.all(
          r.coReporters.map(async (cr) => ({
            id: cr.id,
            createdAt: cr.createdAt,
            reportedAt: cr.reportedAt,
            reportId: cr.reportId,
            userId: cr.userId,
            user: cr.user
              ? {
                  firstName: cr.user.firstName,
                  lastName: cr.user.lastName,
                  avatarUrl: await this.reportsUploadService.signPrivateObjectKey(cr.user.avatarObjectKey),
                }
              : null,
          })),
        );
        return {
          id: r.id,
          createdAt: r.createdAt,
          reportNumber: r.reportNumber,
          siteId: r.siteId,
          reporterId: r.reporterId,
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
      }),
    );

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

    const coReporterSummaries = this.buildSiteCoReporterSummaries(reportsWithSignedUrls);
    return {
      ...site,
      reports: reportsWithSignedUrls,
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
