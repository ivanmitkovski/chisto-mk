export const REJECTION_REASON_VALUES = [
  'False report',
  'Duplicate submission',
  'Insufficient evidence',
  'Out of jurisdiction',
  'Policy violation',
] as const;

export type RejectionReasonValue = (typeof REJECTION_REASON_VALUES)[number];
