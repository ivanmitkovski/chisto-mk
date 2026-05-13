import { Injectable } from '@nestjs/common';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import { SitesFeedCandidatesService } from './sites-feed-candidates.service';
import { SitesFeedEnrichmentService } from './sites-feed-enrichment.service';
import type { SitesFeedListResult } from './sites-feed.types';

@Injectable()
export class SitesFeedQueryService {
  constructor(
    private readonly candidates: SitesFeedCandidatesService,
    private readonly enrichment: SitesFeedEnrichmentService,
  ) {}

  async computeFeedList(
    query: ListSitesQueryDto,
    user: AuthenticatedUser | undefined,
    opts: { startedAt: number; nowMs: number; cacheKey: string },
  ): Promise<SitesFeedListResult> {
    const bundle = await this.candidates.loadCandidateSites(query, user);
    return this.enrichment.buildFeedListResponse(bundle, query, user, opts);
  }
}
