import type { NotificationType } from '../prisma-client';

export type EmailLocale = 'mk' | 'en';

/** JWT payload for one-click email unsubscribe links. */
export type EmailUnsubscribeJwtPayload = {
  sub: string;
  typ: 'email_unsub';
  notificationType: NotificationType | 'ALL';
  v: number;
};

export type EmailTemplateId =
  | 'welcome'
  | 'password_reset'
  | 'password_changed'
  | 'report_received'
  | 'report_approved'
  | 'report_declined'
  | 'report_merged'
  | 'event_approved'
  | 'event_declined'
  | 'event_published'
  | 'event_completed_award'
  | 'event_completed_no_show'
  | 'site_upvote'
  | 'site_comment';
