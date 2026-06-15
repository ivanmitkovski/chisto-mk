import type { AdminModerationCategory, NotificationType } from '../../prisma-client';

export type EmailLocale = 'mk' | 'en';

/** JWT payload for one-click email unsubscribe links. */
export type EmailUnsubscribeJwtPayload = {
  sub: string;
  typ: 'email_unsub';
  notificationType: NotificationType | 'ALL';
  v: number;
};

/** JWT payload for admin moderation email unsubscribe links. */
export type AdminModerationEmailUnsubscribeJwtPayload = {
  sub: string;
  typ: 'admin_mod_email_unsub';
  category: AdminModerationCategory;
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
  | 'site_comment'
  | 'admin_invite'
  | 'admin_moderation_new_report'
  | 'admin_moderation_event_pending'
  | 'admin_moderation_ugc_report'
  | 'admin_moderation_checkin_risk'
  | 'admin_moderation_site_resolution';
