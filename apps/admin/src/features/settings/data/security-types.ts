import type { IconName } from '@/components/ui';

export type AdminSession = {
  id: string;
  device: string;
  location: string;
  ipAddress: string;
  lastActiveLabel: string;
  isCurrent: boolean;
};

export type SecurityActivityTone = 'success' | 'warning' | 'info';

export type SecurityActivityEvent = {
  id: string;
  title: string;
  detail: string;
  occurredAtLabel: string;
  tone: SecurityActivityTone;
  icon: IconName;
};
