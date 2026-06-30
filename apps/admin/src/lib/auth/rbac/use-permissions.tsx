'use client';

import { createContext, useContext, useMemo, type ReactNode } from 'react';
import {
  can,
  canAll,
  canAny,
  permissionsForRole,
  type AdminPermission,
} from './permissions';

type PermissionsContextValue = {
  role: string | null;
  permissions: AdminPermission[];
  can: (permission: AdminPermission) => boolean;
  canAny: (permissions: AdminPermission[]) => boolean;
  canAll: (permissions: AdminPermission[]) => boolean;
};

const PermissionsContext = createContext<PermissionsContextValue | null>(null);

export function PermissionsProvider({
  role,
  children,
}: {
  role: string | null | undefined;
  children: ReactNode;
}) {
  const normalizedRole = role ?? null;
  const value = useMemo<PermissionsContextValue>(
    () => ({
      role: normalizedRole,
      permissions: permissionsForRole(normalizedRole ?? undefined),
      can: (permission) => can(normalizedRole, permission),
      canAny: (perms) => canAny(normalizedRole, perms),
      canAll: (perms) => canAll(normalizedRole, perms),
    }),
    [normalizedRole],
  );

  return <PermissionsContext.Provider value={value}>{children}</PermissionsContext.Provider>;
}

export function usePermissions(): PermissionsContextValue {
  const ctx = useContext(PermissionsContext);
  if (!ctx) {
    return {
      role: null,
      permissions: [],
      can: () => false,
      canAny: () => false,
      canAll: () => false,
    };
  }
  return ctx;
}
