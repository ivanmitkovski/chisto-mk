import { IconName } from '@/components/ui';

export type NotificationTone = 'success' | 'warning' | 'info' | 'neutral';

export type AdminNotification = {
  id: string;
  title: string;
  message: string;
  timeLabel: string;
  tone: NotificationTone;
  isUnread: boolean;
  category: 'reports' | 'system' | 'analytics';
  icon: IconName;
  href?: string | undefined;
};
