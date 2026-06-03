import { NotificationType } from '../../prisma-client';

export type NotificationEvent = {
  recipientUserIds: string[];
  title: string;
  body: string;
  /** Shown as APNS subtitle / Android subtext when set. */
  subtitle?: string;
  type: NotificationType;
  data?: Record<string, unknown>;
  threadKey?: string;
  groupKey?: string;
};
