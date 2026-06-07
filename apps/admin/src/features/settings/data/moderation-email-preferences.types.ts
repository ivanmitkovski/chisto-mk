export type ModerationEmailCategory =
  | 'NEW_REPORT'
  | 'EVENT_PENDING'
  | 'UGC_REPORT'
  | 'CHECKIN_RISK';

export type ModerationEmailPreferenceRow = {
  category: ModerationEmailCategory;
  enabled: boolean;
  source: 'default' | 'explicit';
};
