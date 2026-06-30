import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { AdminSession, SecurityActivityEvent } from './security-types';

export type AdminSecurityOverviewResponse = {
  sessions: AdminSession[];
  activity: SecurityActivityEvent[];
};

export async function getAdminSecurityOverview(): Promise<AdminSecurityOverviewResponse> {

  return serverAuthenticatedFetch<AdminSecurityOverviewResponse>('/admin/security/overview', {
    method: 'GET',
  });
}

