export type ModerationEmailCategory =
  | 'NEW_REPORT'
  | 'EVENT_PENDING'
  | 'UGC_REPORT'
  | 'CHECKIN_RISK'
  | 'SITE_RESOLUTION';

export type ModerationEmailPreferenceRow = {
  category: ModerationEmailCategory;
  enabled: boolean;
  source: 'default' | 'explicit';
};
