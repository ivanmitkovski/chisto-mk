import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';

export type FeatureFlagRow = {
  key: string;
  enabled: boolean;
  metadata: unknown;
  updatedAt: string;
};

export async function getFeatureFlags(): Promise<FeatureFlagRow[]> {
  return serverAuthenticatedFetch<FeatureFlagRow[]>('/admin/feature-flags', {
    method: 'GET',
  });
}
