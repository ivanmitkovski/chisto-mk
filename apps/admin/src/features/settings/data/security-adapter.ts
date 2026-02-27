import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import type { AdminSession, SecurityActivityEvent } from './security';

export type AdminSecurityOverviewResponse = {
  sessions: AdminSession[];
  activity: SecurityActivityEvent[];
};

export async function getAdminSecurityOverview(): Promise<AdminSecurityOverviewResponse> {
  const token = await getAdminAuthTokenFromCookies();

  return apiFetch<AdminSecurityOverviewResponse>('/admin/security/overview', {
    method: 'GET',
    authToken: token,
  });
}

