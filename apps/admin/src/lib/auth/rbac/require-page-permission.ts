import 'server-only';

import { getMeProfile, type MeProfile } from '@/features/auth/data/me-adapter';
import { requirePermission } from './require-permission';
import type { AdminPermission } from './permissions';

export type { MeProfile };

export async function requirePagePermission(permission: AdminPermission): Promise<MeProfile> {
  const profile = await getMeProfile();
  requirePermission(profile.role, permission);
  return profile;
}
