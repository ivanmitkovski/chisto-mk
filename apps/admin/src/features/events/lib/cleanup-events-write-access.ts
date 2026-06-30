/** Mirrors API `ADMIN_WRITE_ROLES` for `/admin/cleanup-events` POST/PATCH (see `apps/api/src/auth/admin-roles.ts`). */
export function canWriteCleanupEvents(role: string): boolean {
  return role === 'ADMIN' || role === 'SUPER_ADMIN';
}
