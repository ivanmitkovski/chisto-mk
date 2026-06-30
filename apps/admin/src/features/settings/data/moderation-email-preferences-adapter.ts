import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { ModerationEmailPreferenceRow } from './moderation-email-preferences.types';

export type { ModerationEmailCategory, ModerationEmailPreferenceRow } from './moderation-email-preferences.types';

export async function getModerationEmailPreferences(): Promise<ModerationEmailPreferenceRow[]> {
  return serverAuthenticatedFetch<ModerationEmailPreferenceRow[]>('/admin/me/moderation-email-preferences', {
    method: 'GET',
  });
}
