import { Injectable } from '@nestjs/common';
import { RankerProvider } from './ranker.provider';
import { FeatureVectorV1 } from '../features/feature-vector.types';

@Injectable()
export class RulesFallbackRanker implements RankerProvider {
  async score(features: FeatureVectorV1[]): Promise<number[]> {
    return features.map((f) => {
      const freshnessBoost = Math.max(0, 1 - f.freshnessHours / 72);
      const distanceBoost = f.distanceKm >= 999 ? 0.2 : Math.max(0, 1 - f.distanceKm / 30);
      return (
        f.engagementIntensity * 0.35 +
        freshnessBoost * 0.25 +
        distanceBoost * 0.15 +
        f.statusTrust * 0.15 +
        f.followsReporter * 0.1 -
        f.wasSeenRecently * 0.05
      );
    });
  }

  modelVersion(): string {
    return 'rules-fallback-v1';
  }
}
