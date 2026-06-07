import 'server-only';

import { serverAuthenticatedFetch } from '../server-api-with-refresh';
import { requirePermission } from './require-permission';
import type { AdminPermission } from './permissions';

export type MeProfile = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  role: string;
  mfaEnabled?: boolean;
};

export async function requirePagePermission(permission: AdminPermission): Promise<MeProfile> {
  const profile = await serverAuthenticatedFetch<MeProfile>('/auth/me', { method: 'GET' });
  requirePermission(profile.role, permission);
  return profile;
}
