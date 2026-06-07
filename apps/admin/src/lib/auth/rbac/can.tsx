'use client';

import type { ReactNode } from 'react';
import { usePermissions } from './use-permissions';
import type { AdminPermission } from './permissions';

type CanProps = {
  permission: AdminPermission | AdminPermission[];
  mode?: 'any' | 'all';
  children: ReactNode;
  fallback?: ReactNode;
};

export function Can({ permission, mode = 'any', children, fallback = null }: CanProps) {
  const { can, canAny, canAll } = usePermissions();
  const perms = Array.isArray(permission) ? permission : [permission];
  const allowed =
    mode === 'all' ? canAll(perms) : perms.length === 1 ? can(perms[0]!) : canAny(perms);
  return allowed ? <>{children}</> : <>{fallback}</>;
}
