export const SITES_STATUS_OPTIONS = [
  { value: '', labelKey: 'filters.allStatuses' },
  { value: 'REPORTED', labelKey: 'filters.reported' },
  { value: 'VERIFIED', labelKey: 'filters.verified' },
  { value: 'CLEANUP_SCHEDULED', labelKey: 'filters.cleanupScheduled' },
  { value: 'IN_PROGRESS', labelKey: 'filters.inProgress' },
  { value: 'CLEANED', labelKey: 'filters.cleaned' },
  { value: 'DISPUTED', labelKey: 'filters.disputed' },
] as const;
