export const FEATURE_VECTOR_VERSION = 'v1';

export type FeatureVectorV1 = {
  version: typeof FEATURE_VECTOR_VERSION;
  siteId: string;
  engagementVelocity24h: number;
  engagementIntensity: number;
  freshnessHours: number;
  distanceKm: number;
  statusTrust: number;
  severityIndex: number;
  discussionRatio: number;
  intentRatio: number;
  reportCount: number;
  wasSeenRecently: number;
  followsReporter: number;
};
