import { IconName } from '@/components/ui';

export type ReportTone = 'green' | 'yellow' | 'red' | 'mint';

export type StatCardGroup = 'reports' | 'platform' | 'cleanups';

export type StatCard = {
  id: string;
  label: string;
  value: number;
  tone: ReportTone;
  icon: IconName;
  trend?: 'up' | 'down' | 'neutral';
  trendLabel?: string;
  group?: StatCardGroup;
  highlight?: boolean;
  /** When set, the stat is rendered as a link to this href */
  href?: string;
};

export type RecentActivityItem = {
  id: string;
  createdAt: string;
  action: string;
  resourceType: string;
  resourceId: string | null;
  actorEmail: string | null;
};

export type ReportsTrendItem = {
  date: string;
  count: number;
};
