export const MAP_STATUS_FILTER_OPTIONS = [
  { value: '', labelKey: 'statusFilters.all' },
  { value: 'REPORTED', labelKey: 'statusFilters.reported' },
  { value: 'VERIFIED', labelKey: 'statusFilters.verified' },
  { value: 'CLEANUP_SCHEDULED', labelKey: 'statusFilters.cleanupScheduled' },
  { value: 'IN_PROGRESS', labelKey: 'statusFilters.inProgress' },
  { value: 'CLEANED', labelKey: 'statusFilters.cleaned' },
  { value: 'DISPUTED', labelKey: 'statusFilters.disputed' },
] as const;
