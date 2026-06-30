import { Injectable } from '@nestjs/common';
import { FeedCandidate, FeedUserState } from '../feed-v2.types';

@Injectable()
export class PersonalizationRerank {
  apply(rows: FeedCandidate[], userState: FeedUserState): FeedCandidate[] {
    return rows
      .filter((row) => !userState.hiddenSiteIds.has(row.siteId))
      .map((row) => {
        let score = row.rankingScore;
        const category = row.latestReportCategory?.toUpperCase();
        if (category && userState.mutedCategoryIds.has(category)) {
          score -= 0.2;
        }
        if (row.latestReportReporterId && userState.followReporterIds.has(row.latestReportReporterId)) {
          score += 0.12;
        }
        if (userState.seenSiteIds.has(row.siteId)) {
          score -= 0.05;
        }
        return { ...row, rankingScore: score };
      });
  }
}
