import { IconName } from '@/components/ui';

export type ReportTone = 'green' | 'yellow' | 'red' | 'mint';

export type StatCard = {
  id: string;
  label: string;
  value: number;
  tone: ReportTone;
  icon: IconName;
};
