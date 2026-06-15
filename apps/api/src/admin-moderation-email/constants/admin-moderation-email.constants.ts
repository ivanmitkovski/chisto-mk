import { AdminModerationCategory } from '../../prisma-client';
import type { AdminPermission } from '../../auth/constants/admin-permissions';
import { ADMIN_PERMISSIONS } from '../../auth/constants/admin-permissions';
import type { EmailTemplateId } from '../../email/types/email.types';

export const ADMIN_MODERATION_EMAIL_FLAG = 'admin_moderation_email_enabled';

export const CATEGORY_TEMPLATE_ID: Record<AdminModerationCategory, EmailTemplateId> = {
  [AdminModerationCategory.NEW_REPORT]: 'admin_moderation_new_report',
  [AdminModerationCategory.EVENT_PENDING]: 'admin_moderation_event_pending',
  [AdminModerationCategory.UGC_REPORT]: 'admin_moderation_ugc_report',
  [AdminModerationCategory.CHECKIN_RISK]: 'admin_moderation_checkin_risk',
  [AdminModerationCategory.SITE_RESOLUTION]: 'admin_moderation_site_resolution',
};

/** Permission required for smart-default “enabled” when no explicit preference row exists. */
export const CATEGORY_VIEW_PERMISSION: Record<AdminModerationCategory, AdminPermission> = {
  [AdminModerationCategory.NEW_REPORT]: ADMIN_PERMISSIONS['reports:read'],
  [AdminModerationCategory.EVENT_PENDING]: ADMIN_PERMISSIONS['events:read'],
  [AdminModerationCategory.UGC_REPORT]: ADMIN_PERMISSIONS['moderation:read'],
  [AdminModerationCategory.CHECKIN_RISK]: ADMIN_PERMISSIONS['events:read'],
  [AdminModerationCategory.SITE_RESOLUTION]: ADMIN_PERMISSIONS['sites:resolve'],
};

export const ALL_ADMIN_MODERATION_CATEGORIES: AdminModerationCategory[] = [
  AdminModerationCategory.NEW_REPORT,
  AdminModerationCategory.EVENT_PENDING,
  AdminModerationCategory.UGC_REPORT,
  AdminModerationCategory.CHECKIN_RISK,
  AdminModerationCategory.SITE_RESOLUTION,
];
