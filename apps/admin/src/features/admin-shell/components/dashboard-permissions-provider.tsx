'use client';

import { PermissionsProvider } from '@/lib/auth/rbac';

export function DashboardPermissionsProvider({
  role,
  children,
}: {
  role: string | null;
  children: React.ReactNode;
}) {
  return <PermissionsProvider role={role}>{children}</PermissionsProvider>;
}
