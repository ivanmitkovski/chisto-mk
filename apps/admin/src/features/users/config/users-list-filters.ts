export const USERS_ROLE_OPTIONS = [
  { value: '', labelKey: 'filters.allRoles' },
  { value: 'USER', labelKey: 'filters.roleUser' },
  { value: 'MODERATOR', labelKey: 'filters.roleModerator' },
  { value: 'ADMIN', labelKey: 'filters.roleAdmin' },
  { value: 'SUPER_ADMIN', labelKey: 'filters.roleSuperAdmin' },
] as const;

export const USERS_STATUS_OPTIONS = [
  { value: '', labelKey: 'filters.allStatuses' },
  { value: 'ACTIVE', labelKey: 'filters.active' },
  { value: 'SUSPENDED', labelKey: 'filters.suspended' },
] as const;
