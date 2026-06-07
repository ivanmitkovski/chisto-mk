import 'server-only';

import { redirect } from 'next/navigation';
import { can, type AdminPermission, type AdminRole } from './permissions';

export class PermissionDeniedError extends Error {
  readonly permission: AdminPermission;

  constructor(permission: AdminPermission) {
    super(`Permission denied: ${permission}`);
    this.name = 'PermissionDeniedError';
    this.permission = permission;
  }
}

export function hasPermission(
  role: string | null | undefined,
  permission: AdminPermission,
): boolean {
  if (!role) return false;
  return can(role as AdminRole, permission);
}

/**
 * Redirects to dashboard with a forbidden flag when the role lacks permission.
 * Use at the top of sensitive RSC pages after loading the user profile.
 */
export function requirePermission(
  role: string | null | undefined,
  permission: AdminPermission,
): void {
  if (!hasPermission(role, permission)) {
    redirect('/dashboard?access=forbidden');
  }
}

export function requireAnyPermission(
  role: string | null | undefined,
  permissions: AdminPermission[],
): void {
  if (!role || !permissions.some((permission) => can(role as AdminRole, permission))) {
    redirect('/dashboard?access=forbidden');
  }
}
