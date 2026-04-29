import { Injectable } from '@nestjs/common';
import { FeedCandidateWithStage } from '../feed-v2.types';
import { GeoRetriever } from './geo.retriever';
import { FreshnessRetriever } from './freshness.retriever';
import { EngagementRetriever } from './engagement.retriever';
import { PersonalRetriever } from './personal.retriever';

export type CandidateRequestContext = {
  userId?: string;
  lat?: number;
  lng?: number;
  radiusKm?: number;
  limit?: number;
  status?: 'REPORTED' | 'VERIFIED' | 'CLEANUP_SCHEDULED' | 'IN_PROGRESS' | 'CLEANED' | 'DISPUTED';
};

@Injectable()
export class CandidateGenerator {
  constructor(
    private readonly geo: GeoRetriever,
    private readonly freshness: FreshnessRetriever,
    private readonly engagement: EngagementRetriever,
    private readonly personal: PersonalRetriever,
  ) {}

  async generate(context: CandidateRequestContext): Promise<FeedCandidateWithStage[]> {
    const [geo, freshness, engagement, personal] = await Promise.all([
      this.geo.retrieve(context),
      this.freshness.retrieve(context),
      this.engagement.retrieve(context),
      this.personal.retrieve(context),
    ]);
    const merged = [...geo, ...freshness, ...engagement, ...personal];
    const deduped = new Map<string, FeedCandidateWithStage>();
    for (const row of merged) {
      const current = deduped.get(row.siteId);
      if (!current || row.candidateStage.scoreHint > current.candidateStage.scoreHint) {
        deduped.set(row.siteId, row);
      }
    }
    return [...deduped.values()].slice(0, 400);
  }
}
