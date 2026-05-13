import { Injectable } from '@nestjs/common';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { ListSiteUpvotesQueryDto } from './dto/list-site-upvotes-query.dto';
import { SiteEngagementService } from './site-engagement.service';
import { SiteUpvotesRepository } from './repositories/site-upvotes.repository';

@Injectable()
export class SitesSiteUpvotesListService {
  constructor(
    private readonly siteEngagement: SiteEngagementService,
    private readonly siteUpvotesRepository: SiteUpvotesRepository,
    private readonly reportsUploadService: ReportsUploadService,
  ) {}

  async findSiteUpvotes(siteId: string, query: ListSiteUpvotesQueryDto): Promise<{
    data: Array<{
      userId: string;
      displayName: string;
      avatarUrl: string | null;
      upvotedAt: string;
    }>;
    meta: { page: number; limit: number; total: number; hasMore: boolean };
  }> {
    await this.siteEngagement.ensureSiteExists(siteId);
    const skip = (query.page - 1) * query.limit;
    const [total, votes] = await Promise.all([
      this.siteUpvotesRepository.countBySiteId(siteId),
      this.siteUpvotesRepository.findPageBySiteId({
        siteId,
        skip,
        take: query.limit,
      }),
    ]);
    const data = await Promise.all(
      votes.map(async (vote) => {
        const displayName =
          `${vote.user.firstName ?? ''} ${vote.user.lastName ?? ''}`.trim() || 'Anonymous';
        const avatarUrl = await this.reportsUploadService.resolveUserAvatarUrl(
          vote.user.avatarObjectKey,
        );
        return {
          userId: vote.user.id,
          displayName,
          avatarUrl,
          upvotedAt: vote.createdAt.toISOString(),
        };
      }),
    );
    const loadedThrough = skip + data.length;
    return {
      data,
      meta: {
        page: query.page,
        limit: query.limit,
        total,
        hasMore: loadedThrough < total,
      },
    };
  }
}
