export const EMAIL_SUPPRESSION_REASON_VALUES = [
  '',
  'HardBounce',
  'SpamComplaint',
  'ManualSuppression',
  'SubscriptionChange',
] as const;

export const EMAIL_SUPPRESSION_SOURCE_VALUES = ['', 'postmark'] as const;

export const WEBHOOK_LOG_ACTION_VALUES = [
  '',
  'WEBHOOK_TWILIO_STATUS',
  'WEBHOOK_POSTMARK',
  'EMAIL_SUPPRESSION_CREATED',
] as const;

export type EmailSuppressionReasonValue = (typeof EMAIL_SUPPRESSION_REASON_VALUES)[number];
export type EmailSuppressionSourceValue = (typeof EMAIL_SUPPRESSION_SOURCE_VALUES)[number];
export type WebhookLogActionValue = (typeof WEBHOOK_LOG_ACTION_VALUES)[number];

export function emailSuppressionReasonKey(value: EmailSuppressionReasonValue) {
  if (value === '') return 'all' as const;
  if (value === 'HardBounce') return 'hardBounce' as const;
  if (value === 'SpamComplaint') return 'spamComplaint' as const;
  if (value === 'ManualSuppression') return 'manualSuppression' as const;
  return 'subscriptionChange' as const;
}

export function emailSuppressionSourceKey(value: EmailSuppressionSourceValue) {
  return value === '' ? ('all' as const) : ('postmark' as const);
}

export function webhookLogActionKey(value: WebhookLogActionValue) {
  if (value === '') return 'all' as const;
  if (value === 'WEBHOOK_TWILIO_STATUS') return 'twilioStatus' as const;
  if (value === 'WEBHOOK_POSTMARK') return 'postmark' as const;
  return 'suppressionCreated' as const;
}
