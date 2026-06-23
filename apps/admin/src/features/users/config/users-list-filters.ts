export const USERS_ROLE_OPTIONS = [
  { value: '', labelKey: 'filters.allRoles' },
  { value: 'USER', labelKey: 'filters.roleUser' },
  { value: 'SUPPORT', labelKey: 'filters.roleSupport' },
  { value: 'ADMIN', labelKey: 'filters.roleAdmin' },
  { value: 'SUPER_ADMIN', labelKey: 'filters.roleSuperAdmin' },
] as const;

export const USERS_STATUS_OPTIONS = [
  { value: '', labelKey: 'filters.allStatuses' },
  { value: 'ACTIVE', labelKey: 'filters.active' },
  { value: 'SUSPENDED', labelKey: 'filters.suspended' },
  { value: 'DELETED', labelKey: 'filters.deleted' },
] as const;

export const USERS_QUICK_STATUS_FILTERS = [
  { value: '' as const, labelKey: 'filters.allStatuses' },
  { value: 'ACTIVE' as const, labelKey: 'filters.active' },
  { value: 'SUSPENDED' as const, labelKey: 'filters.suspended' },
  { value: 'DELETED' as const, labelKey: 'filters.deleted' },
] as const;
