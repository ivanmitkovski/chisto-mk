/** Mirrors API `ADMIN_WRITE_ROLES` for `/admin/news` write endpoints. */
export function canWriteNews(role: string): boolean {
  return role === 'ADMIN' || role === 'SUPER_ADMIN';
}
