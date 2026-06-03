import type { NotificationEvent } from '../../notifications/types/notification-event.types';
import type { EmailTemplateId } from '../types/email.types';
import { mapNotificationEventToEmail } from './email-event-mapper';

/**
 * Channel policy (push-first, email for important events only).
 *
 * | Channel | Scope |
 * |---------|-------|
 * | In-app inbox | All notification types (unless user muted the type) |
 * | Push (FCM) | Primary real-time channel for all non-muted types |
 * | Email (Postmark) | Only templates in IMPORTANT_EMAIL_TEMPLATE_IDS |
 *
 * Auth/security mail (`welcome`, `password_reset`, `password_changed`, email-change)
 * bypasses this policy — sent directly via EmailService.sendAuthTemplate / sendTemplate
 * with skipPreferenceCheck where appropriate.
 *
 * Push + inbox only (no email): report_received, report_approved/declined/merged,
 * event_approved/declined/published, site_upvote, site_comment, chat, reminders, etc.
 *
 * Push + inbox + email: event_completed_award, event_completed_no_show (points ledger).
 *
 * To promote an event to email: add its template ID to IMPORTANT_EMAIL_TEMPLATE_IDS.
 */
export const IMPORTANT_EMAIL_TEMPLATE_IDS: ReadonlySet<EmailTemplateId> = new Set([
  'event_completed_award',
  'event_completed_no_show',
]);

export function isImportantNotificationEmail(
  event: Omit<NotificationEvent, 'recipientUserIds'>,
): boolean {
  const mapped = mapNotificationEventToEmail(event);
  return mapped != null && IMPORTANT_EMAIL_TEMPLATE_IDS.has(mapped.templateId);
}
