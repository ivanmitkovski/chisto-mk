export type UgcModerationAction =
  | 'mark_reviewed'
  | 'dismiss'
  | 'escalate'
  | 'hide_subject'
  | 'restore_subject';

export const UGC_MODERATION_ACTION_IDS: UgcModerationAction[] = [
  'mark_reviewed',
  'dismiss',
  'escalate',
  'hide_subject',
  'restore_subject',
];

const ACTION_MESSAGE_KEYS: Record<UgcModerationAction, string> = {
  mark_reviewed: 'actions.markReviewed',
  dismiss: 'actions.dismiss',
  escalate: 'actions.escalate',
  hide_subject: 'actions.hideSubject',
  restore_subject: 'actions.restoreSubject',
};

const ACTION_TONES: Record<UgcModerationAction, 'neutral' | 'success' | 'warning' | 'danger'> = {
  mark_reviewed: 'success',
  dismiss: 'neutral',
  escalate: 'warning',
  hide_subject: 'danger',
  restore_subject: 'success',
};

export const UGC_STATUS_FILTER_VALUES = [
  '',
  'OPEN',
  'ESCALATED',
  'REVIEWED',
  'DISMISSED',
  'HIDDEN',
] as const;

export const UGC_SUBJECT_TYPE_FILTER_VALUES = [
  '',
  'user',
  'site',
  'event',
  'site_comment',
  'event_chat_message',
  'safety_issue',
] as const;

const STATUS_FILTER_MESSAGE_KEYS: Record<(typeof UGC_STATUS_FILTER_VALUES)[number], string> = {
  '': 'statusOptions.all',
  OPEN: 'statusOptions.open',
  ESCALATED: 'statusOptions.escalated',
  REVIEWED: 'statusOptions.reviewed',
  DISMISSED: 'statusOptions.dismissed',
  HIDDEN: 'statusOptions.hidden',
};

const SUBJECT_TYPE_KEYS = new Set([
  'user',
  'site',
  'event',
  'site_comment',
  'event_chat_message',
  'safety_issue',
]);

export function getUgcModerationActions(t: (key: string) => string) {
  return UGC_MODERATION_ACTION_IDS.map((id) => ({
    id,
    label: t(ACTION_MESSAGE_KEYS[id]),
    tone: ACTION_TONES[id],
  }));
}

export function getUgcStatusFilterOptions(t: (key: string) => string) {
  return UGC_STATUS_FILTER_VALUES.map((value) => ({
    value,
    label: t(STATUS_FILTER_MESSAGE_KEYS[value]),
  }));
}

const SUBJECT_TYPE_FILTER_MESSAGE_KEYS: Record<(typeof UGC_SUBJECT_TYPE_FILTER_VALUES)[number], string> = {
  '': 'subjectTypeOptions.all',
  user: 'subjectTypes.user',
  site: 'subjectTypes.site',
  event: 'subjectTypes.event',
  site_comment: 'subjectTypes.site_comment',
  event_chat_message: 'subjectTypes.event_chat_message',
  safety_issue: 'subjectTypes.safety_issue',
};

export function getUgcSubjectTypeFilterOptions(t: (key: string) => string) {
  return UGC_SUBJECT_TYPE_FILTER_VALUES.map((value) => ({
    value,
    label: t(SUBJECT_TYPE_FILTER_MESSAGE_KEYS[value]),
  }));
}

export function formatUgcLabel(value: string): string {
  return value.replace(/_/g, ' ').replace(/\b\w/g, (char) => char.toUpperCase());
}

export function formatUgcSubjectType(subjectType: string, t?: (key: string) => string): string {
  if (t && SUBJECT_TYPE_KEYS.has(subjectType)) {
    return t(`subjectTypes.${subjectType}`);
  }
  return formatUgcLabel(subjectType);
}

export function getUgcSubjectDashboardHref(subjectType: string, subjectId: string): string | null {
  switch (subjectType) {
    case 'user':
      return `/dashboard/users/${encodeURIComponent(subjectId)}`;
    case 'site':
      return `/dashboard/sites/${encodeURIComponent(subjectId)}`;
    case 'event':
      return `/dashboard/events/${encodeURIComponent(subjectId)}`;
    default:
      return null;
  }
}

export function getUgcSubjectPreviewLabel(subjectType: string, t: (key: string) => string): string {
  if (SUBJECT_TYPE_KEYS.has(subjectType)) {
    return t(`subjectTypes.${subjectType}`);
  }
  return formatUgcLabel(subjectType);
}

export function ugcActionRequiresPolicyReason(action: UgcModerationAction): boolean {
  return (
    action === 'dismiss' ||
    action === 'escalate' ||
    action === 'hide_subject' ||
    action === 'restore_subject'
  );
}

export function isUgcActionAllowed(action: UgcModerationAction, status: string): boolean {
  switch (status) {
    case 'OPEN':
      return action !== 'restore_subject';
    case 'ESCALATED':
      return action === 'mark_reviewed' || action === 'dismiss' || action === 'hide_subject';
    case 'HIDDEN':
      return action === 'restore_subject';
    case 'REVIEWED':
    case 'DISMISSED':
      return false;
    default:
      return false;
  }
}

export function ugcBadgeTone(status: string): 'neutral' | 'success' | 'warning' | 'danger' | 'info' {
  if (status === 'OPEN') return 'warning';
  if (status === 'ESCALATED') return 'danger';
  if (status === 'HIDDEN') return 'info';
  if (status === 'REVIEWED') return 'success';
  return 'neutral';
}
