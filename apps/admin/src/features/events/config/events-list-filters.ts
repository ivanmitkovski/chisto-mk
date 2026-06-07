export const EVENTS_STATUS_OPTIONS = [
  { value: '', labelKey: 'filters.completionAll' },
  { value: 'upcoming', labelKey: 'filters.completionUpcoming' },
  { value: 'completed', labelKey: 'filters.completionCompleted' },
] as const;

export const EVENTS_MODERATION_OPTIONS = [
  { value: '', labelKey: 'filters.moderationAll' },
  { value: 'PENDING', labelKey: 'filters.moderationPending' },
  { value: 'APPROVED', labelKey: 'filters.moderationApproved' },
  { value: 'DECLINED', labelKey: 'filters.moderationDeclined' },
] as const;
