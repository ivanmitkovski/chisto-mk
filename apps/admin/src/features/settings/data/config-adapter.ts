import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { Schema } from '@/lib/api';

export type ConfigEntry = Schema<'SystemConfigEntryDto'> & { updatedAt?: string };

export async function getSystemConfig(): Promise<ConfigEntry[]> {
  return serverAuthenticatedFetch<ConfigEntry[]>('/admin/config', {
    method: 'GET',
  });
}
