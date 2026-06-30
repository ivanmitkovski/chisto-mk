import { FeatureVectorV1 } from '../features/feature-vector.types';

export function reasonsFromFeatures(feature: FeatureVectorV1): string[] {
  const reasons: string[] = [];
  if (feature.freshnessHours <= 12) reasons.push('fresh_report');
  if (feature.distanceKm <= 5) reasons.push('near_your_area');
  if (feature.followsReporter > 0) reasons.push('follows_reporter');
  if (feature.engagementIntensity > 2) reasons.push('high_engagement');
  if (reasons.length === 0) reasons.push('personalized_blend');
  return reasons;
}
