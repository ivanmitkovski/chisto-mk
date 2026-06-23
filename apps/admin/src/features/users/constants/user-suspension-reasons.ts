export const USER_SUSPENSION_REASONS = [
  { value: 'spam', labelKey: 'detail.suspensionReasons.spam' },
  { value: 'harassment', labelKey: 'detail.suspensionReasons.harassment' },
  { value: 'tos_violation', labelKey: 'detail.suspensionReasons.tosViolation' },
  { value: 'fraud_abuse', labelKey: 'detail.suspensionReasons.fraudAbuse' },
  { value: 'admin_request', labelKey: 'detail.suspensionReasons.adminRequest' },
  { value: 'other', labelKey: 'detail.suspensionReasons.other' },
] as const;

export type UserSuspensionReasonCode = (typeof USER_SUSPENSION_REASONS)[number]['value'];
