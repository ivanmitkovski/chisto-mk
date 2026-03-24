import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';

export type FeatureFlagRow = {
  key: string;
  enabled: boolean;
  metadata: unknown;
  updatedAt: string;
};

export async function getFeatureFlags(): Promise<FeatureFlagRow[]> {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch<FeatureFlagRow[]>('/admin/feature-flags', {
    method: 'GET',
    authToken: token,
  });
}
