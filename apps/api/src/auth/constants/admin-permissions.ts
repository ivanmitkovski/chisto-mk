import { Role } from '../../prisma-client';

export const ADMIN_PANEL_ROLES: Role[] = [Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN];

export const ADMIN_WRITE_ROLES: Role[] = [Role.ADMIN, Role.SUPER_ADMIN];

export const SUPER_ADMIN_ROLES: Role[] = [Role.SUPER_ADMIN];

export const ADMIN_PERMISSIONS = {
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
} as const;

export type AdminPermission = (typeof ADMIN_PERMISSIONS)[keyof typeof ADMIN_PERMISSIONS];

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
];

const ADMIN_ROLE: AdminPermission[] = [
  ...SUPPORT,
  ADMIN_PERMISSIONS['reports:merge'],
  ADMIN_PERMISSIONS['users:write'],
  ADMIN_PERMISSIONS['sites:write'],
  ADMIN_PERMISSIONS['sites:bulk'],
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

export function permissionsForRole(role: Role): AdminPermission[] {
  switch (role) {
    case Role.SUPER_ADMIN:
      return [...SUPER_ADMIN];
    case Role.ADMIN:
      return [...ADMIN_ROLE];
    case Role.SUPPORT:
      return [...SUPPORT];
    default:
      return [];
  }
}

export function roleHasPermission(role: Role, permission: AdminPermission): boolean {
  return permissionsForRole(role).includes(permission);
}
