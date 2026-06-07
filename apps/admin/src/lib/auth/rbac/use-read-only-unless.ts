'use client';

import { usePermissions } from './use-permissions';
import type { AdminPermission } from './permissions';

/** Returns true when the current user should treat fields as read-only (lacks permission). */
export function useReadOnlyUnless(permission: AdminPermission): boolean {
  const { can } = usePermissions();
  return !can(permission);
}

/** Returns true when the user has the given permission. */
export function useCanWrite(permission: AdminPermission): boolean {
  const { can } = usePermissions();
  return can(permission);
}
