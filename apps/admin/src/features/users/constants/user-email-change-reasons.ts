export const USER_EMAIL_CHANGE_REASONS = [
  { value: 'user_request', labelKey: 'detail.changeEmail.reasons.userRequest' },
  { value: 'typo_correction', labelKey: 'detail.changeEmail.reasons.typoCorrection' },
  { value: 'account_recovery', labelKey: 'detail.changeEmail.reasons.accountRecovery' },
  { value: 'merged_account', labelKey: 'detail.changeEmail.reasons.mergedAccount' },
  { value: 'other', labelKey: 'detail.changeEmail.reasons.other' },
] as const;

export type UserEmailChangeReasonCode = (typeof USER_EMAIL_CHANGE_REASONS)[number]['value'];
