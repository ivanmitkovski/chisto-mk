import type { Prisma } from '../prisma-client';

export type FeedSiteRow = Prisma.SiteGetPayload<{
  include: {
    reports: {
      orderBy: { createdAt: 'desc' };
      take: 1;
      select: {
        title: true;
        description: true;
        mediaUrls: true;
        category: true;
        createdAt: true;
        reportNumber: true;
        reporter: {
          select: { id: true; firstName: true; lastName: true; avatarObjectKey: true };
        };
      };
    };
    votes: { where: { userId: string }; select: { id: true }; take: 1 } | false;
    saves: { where: { userId: string }; select: { id: true }; take: 1 } | false;
    _count: { select: { reports: true } };
  };
}>;

export type SitesFeedCandidateBundle = {
  sites: FeedSiteRow[];
  velocityBySite: Map<string, number>;
  duplicateTitleCounts: Map<string, number>;
  /** Base filter (status + geo) for `site.count` — excludes cursor clause. */
  where: Prisma.SiteWhereInput;
};
