import { IconName } from '@/components/ui';

export type NotificationTone = 'success' | 'warning' | 'info' | 'neutral';

export type AdminNotification = {
  id: string;
  title: string;
  message: string;
  timeLabel: string;
  createdAt?: string;
  tone: NotificationTone;
  isUnread: boolean;
  category: 'reports' | 'system' | 'analytics';
  icon: IconName;
  href?: string | undefined;
  /** When set, admin UI can render a localized template instead of inline title/message. */
  messageTemplateKey?: string | null;
  messageTemplateParams?: Record<string, unknown> | null;
};
