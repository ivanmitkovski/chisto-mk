import { Injectable } from '@nestjs/common';
import { FeedCandidate } from '../feed-v2.types';

@Injectable()
export class PolicyRerank {
  apply(rows: FeedCandidate[]): FeedCandidate[] {
    return rows
      .map((row) => {
        let score = row.rankingScore;
        if (row.status === 'DISPUTED') score *= 0.35;
        if (row.status === 'VERIFIED') score *= 1.05;
        return { ...row, rankingScore: score };
      })
      .sort((a, b) => b.rankingScore - a.rankingScore);
  }
}
