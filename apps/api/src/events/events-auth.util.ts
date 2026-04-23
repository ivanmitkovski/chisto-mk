import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES } from '../auth/admin-roles';

export function isEventsStaff(user: AuthenticatedUser): boolean {
  return ADMIN_PANEL_ROLES.includes(user.role);
}
