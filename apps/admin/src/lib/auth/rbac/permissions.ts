/**
 * Admin permission strings — UI gates use these; API enforces via PermissionsGuard.
 */
export const ADMIN_PERMISSIONS = {
  // Dashboard & read
  'dashboard:view': 'dashboard:view',
  'reports:read': 'reports:read',
  'reports:moderate': 'reports:moderate',
  'reports:merge': 'reports:merge',
  'users:read': 'users:read',
  'users:write': 'users:write',
  'users:role:write': 'users:role:write',
  'sites:read': 'sites:read',
  'sites:write': 'sites:write',
  'sites:bulk': 'sites:bulk',
  'sites:resolve': 'sites:resolve',
  'events:read': 'events:read',
  'events:write': 'events:write',
  'events:bulk': 'events:bulk',
  'moderation:read': 'moderation:read',
  'moderation:write': 'moderation:write',
  'content:takedown': 'content:takedown',
  'audit:read': 'audit:read',
  'notifications:read': 'notifications:read',
  'notifications:broadcast': 'notifications:broadcast',
  'operations:read': 'operations:read',
  'operations:write': 'operations:write',
  'config:read': 'config:read',
  'config:write': 'config:write',
  'feature-flags:read': 'feature-flags:read',
  'feature-flags:write': 'feature-flags:write',
  'gamification:read': 'gamification:read',
  'gamification:write': 'gamification:write',
  'comms:read': 'comms:read',
  'comms:write': 'comms:write',
  'map:read': 'map:read',
  'settings:read': 'settings:read',
  'settings:security': 'settings:security',
  'app-config:read': 'app-config:read',
  'app-config:write': 'app-config:write',
  'team:read': 'team:read',
  'team:write': 'team:write',
  'analytics:read': 'analytics:read',
} as const;

export type AdminPermission = (typeof ADMIN_PERMISSIONS)[keyof typeof ADMIN_PERMISSIONS];

export type AdminRole = 'SUPPORT' | 'ADMIN' | 'SUPER_ADMIN';

const SUPPORT: AdminPermission[] = [
  ADMIN_PERMISSIONS['dashboard:view'],
  ADMIN_PERMISSIONS['reports:read'],
  ADMIN_PERMISSIONS['reports:moderate'],
  ADMIN_PERMISSIONS['users:read'],
  ADMIN_PERMISSIONS['sites:read'],
  ADMIN_PERMISSIONS['events:read'],
  ADMIN_PERMISSIONS['moderation:read'],
  ADMIN_PERMISSIONS['audit:read'],
  ADMIN_PERMISSIONS['notifications:read'],
  ADMIN_PERMISSIONS['operations:read'],
  ADMIN_PERMISSIONS['config:read'],
  ADMIN_PERMISSIONS['feature-flags:read'],
  ADMIN_PERMISSIONS['gamification:read'],
  ADMIN_PERMISSIONS['comms:read'],
  ADMIN_PERMISSIONS['map:read'],
  ADMIN_PERMISSIONS['settings:read'],
  ADMIN_PERMISSIONS['settings:security'],
  ADMIN_PERMISSIONS['app-config:read'],
  ADMIN_PERMISSIONS['analytics:read'],
];

const ADMIN_ROLE: AdminPermission[] = [
  ...SUPPORT,
  ADMIN_PERMISSIONS['reports:merge'],
  ADMIN_PERMISSIONS['users:write'],
  ADMIN_PERMISSIONS['sites:write'],
  ADMIN_PERMISSIONS['sites:bulk'],
  ADMIN_PERMISSIONS['sites:resolve'],
  ADMIN_PERMISSIONS['events:write'],
  ADMIN_PERMISSIONS['events:bulk'],
  ADMIN_PERMISSIONS['moderation:write'],
  ADMIN_PERMISSIONS['content:takedown'],
  ADMIN_PERMISSIONS['operations:write'],
  ADMIN_PERMISSIONS['feature-flags:write'],
  ADMIN_PERMISSIONS['gamification:write'],
  ADMIN_PERMISSIONS['comms:write'],
  ADMIN_PERMISSIONS['notifications:broadcast'],
  ADMIN_PERMISSIONS['app-config:write'],
];

const SUPER_ADMIN: AdminPermission[] = [
  ...ADMIN_ROLE,
  ADMIN_PERMISSIONS['users:role:write'],
  ADMIN_PERMISSIONS['config:write'],
  ADMIN_PERMISSIONS['team:read'],
  ADMIN_PERMISSIONS['team:write'],
];

export const ROLE_PERMISSIONS: Record<AdminRole, ReadonlySet<AdminPermission>> = {
  SUPPORT: new Set(SUPPORT),
  ADMIN: new Set(ADMIN_ROLE),
  SUPER_ADMIN: new Set(SUPER_ADMIN),
};

export function permissionsForRole(role: string | null | undefined): AdminPermission[] {
  if (role === 'SUPER_ADMIN') return [...SUPER_ADMIN];
  if (role === 'ADMIN') return [...ADMIN_ROLE];
  if (role === 'SUPPORT') return [...SUPPORT];
  return [];
}

export function can(role: string | null | undefined, permission: AdminPermission): boolean {
  if (role === 'SUPER_ADMIN') return ROLE_PERMISSIONS.SUPER_ADMIN.has(permission);
  if (role === 'ADMIN') return ROLE_PERMISSIONS.ADMIN.has(permission);
  if (role === 'SUPPORT') return ROLE_PERMISSIONS.SUPPORT.has(permission);
  return false;
}

export function canAny(role: string | null | undefined, permissions: AdminPermission[]): boolean {
  return permissions.some((p) => can(role, p));
}

export function canAll(role: string | null | undefined, permissions: AdminPermission[]): boolean {
  return permissions.every((p) => can(role, p));
}

/** Nav item → required permission */
export const NAV_PERMISSIONS: Record<string, AdminPermission> = {
  dashboard: ADMIN_PERMISSIONS['dashboard:view'],
  reports: ADMIN_PERMISSIONS['reports:read'],
  duplicates: ADMIN_PERMISSIONS['reports:read'],
  users: ADMIN_PERMISSIONS['users:read'],
  sites: ADMIN_PERMISSIONS['sites:read'],
  resolutions: ADMIN_PERMISSIONS['sites:read'],
  map: ADMIN_PERMISSIONS['map:read'],
  events: ADMIN_PERMISSIONS['events:read'],
  moderation: ADMIN_PERMISSIONS['moderation:read'],
  operations: ADMIN_PERMISSIONS['operations:read'],
  audit: ADMIN_PERMISSIONS['audit:read'],
  notifications: ADMIN_PERMISSIONS['notifications:read'],
  settings: ADMIN_PERMISSIONS['settings:read'],
  broadcasts: ADMIN_PERMISSIONS['notifications:broadcast'],
  gamification: ADMIN_PERMISSIONS['gamification:read'],
  'app-config': ADMIN_PERMISSIONS['app-config:read'],
  'risk-signals': ADMIN_PERMISSIONS['events:read'],
  'email-suppressions': ADMIN_PERMISSIONS['comms:read'],
  'webhook-logs': ADMIN_PERMISSIONS['comms:read'],
  team: ADMIN_PERMISSIONS['team:read'],
  'active-users': ADMIN_PERMISSIONS['analytics:read'],
};
