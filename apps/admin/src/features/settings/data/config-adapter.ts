import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';

export type ConfigEntry = {
  key: string;
  value: string;
  updatedAt: string;
};

export async function getSystemConfig(): Promise<ConfigEntry[]> {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch<ConfigEntry[]>('/admin/config', {
    method: 'GET',
    authToken: token,
  });
}
