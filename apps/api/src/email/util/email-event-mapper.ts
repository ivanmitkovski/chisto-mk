import { NotificationType } from '../../prisma-client';
import type { NotificationEvent } from '../../notifications/types/notification-event.types';
import type { EmailTemplateId } from '../types/email.types';
import type { EmailLocale } from '../types/email.types';

export type MappedEmail = {
  templateId: EmailTemplateId;
  context: Record<string, unknown>;
};

function dataObj(data: Record<string, unknown> | undefined): Record<string, unknown> {
  return data ?? {};
}

/**
 * Maps push/inbox notification events to transactional email templates.
 * Returns null when no email should be sent for this event.
 */
export function mapNotificationEventToEmail(
  event: Omit<NotificationEvent, 'recipientUserIds'>,
): MappedEmail | null {
  const d = dataObj(event.data as Record<string, unknown> | undefined);

  if (event.type === NotificationType.SYSTEM && d.kind === 'report_received') {
    return {
      templateId: 'report_received',
      context: {
        reportNumber: typeof d.reportNumber === 'string' ? d.reportNumber : '',
        reportId: d.reportId,
        siteId: d.siteId,
      },
    };
  }

  if (event.type === NotificationType.REPORT_STATUS) {
    if (d.mergeRole === 'primary') {
      return {
        templateId: 'report_merged',
        context: { mergeRole: 'primary', reportNumber: d.reportNumber, reportId: d.reportId, siteId: d.siteId },
      };
    }
    if (d.mergeRole === 'merged_child') {
      return {
        templateId: 'report_merged',
        context: { mergeRole: 'merged_child', reportNumber: d.reportNumber, reportId: d.reportId, siteId: d.siteId },
      };
    }
    if (d.mergeRole === 'co_reporter_credited') {
      return {
        templateId: 'report_merged',
        context: { mergeRole: 'co_reporter_credited', reportNumber: d.reportNumber, reportId: d.reportId, siteId: d.siteId },
      };
    }
    const status = typeof d.status === 'string' ? d.status : '';
    if (status === 'APPROVED') {
      return {
        templateId: 'report_approved',
        context: { reportNumber: d.reportNumber, reportId: d.reportId, siteId: d.siteId },
      };
    }
    if (status === 'DELETED') {
      return {
        templateId: 'report_declined',
        context: {
          reportNumber: d.reportNumber,
          reportId: d.reportId,
          siteId: d.siteId,
          reason: typeof d.reason === 'string' ? d.reason : '',
        },
      };
    }
    return null;
  }

  if (event.type === NotificationType.CLEANUP_EVENT) {
    const kind = typeof d.kind === 'string' ? d.kind : '';
    const eventTitle =
      typeof d.eventTitle === 'string' && d.eventTitle.trim() !== ''
        ? d.eventTitle
        : event.title;
    if (kind === 'approved') {
      return {
        templateId: 'event_approved',
        context: { eventTitle, eventId: d.eventId },
      };
    }
    if (kind === 'declined') {
      return { templateId: 'event_declined', context: { eventTitle, eventId: d.eventId } };
    }
    if (kind === 'published') {
      return {
        templateId: 'event_published',
        context: { eventTitle, eventId: d.eventId, siteId: d.siteId },
      };
    }
    if (d.pointsAwarded != null && typeof d.pointsAwarded === 'number' && d.pointsAwarded > 0) {
      return {
        templateId: 'event_completed_award',
        context: { eventTitle, points: d.pointsAwarded, eventId: d.eventId },
      };
    }
    if (d.pointsAdjusted != null && typeof d.pointsAdjusted === 'number' && d.pointsAdjusted < 0) {
      return {
        templateId: 'event_completed_no_show',
        context: { eventTitle, points: d.pointsAdjusted, eventId: d.eventId },
      };
    }
    return null;
  }

  if (event.type === NotificationType.UPVOTE) {
    return { templateId: 'site_upvote', context: { siteId: d.siteId, siteLabel: '' } };
  }

  if (event.type === NotificationType.COMMENT) {
    const preview = typeof d.messagePreview === 'string' ? d.messagePreview : event.body;
    return { templateId: 'site_comment', context: { siteId: d.siteId, commentPreview: preview } };
  }

  return null;
}

export function resolveLocale(raw: string | null | undefined): EmailLocale {
  const s = raw?.trim().toLowerCase();
  return s === 'en' ? 'en' : 'mk';
}
