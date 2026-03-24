import type { ReportStatus } from '../types';

export function queueMeta(status: ReportStatus): { priority: 'Critical' | 'High' | 'Normal'; slaLabel: string } {
  if (status === 'NEW') return { priority: 'Critical', slaLabel: '2h remaining' };
  if (status === 'IN_REVIEW') return { priority: 'High', slaLabel: '1h remaining' };
  return { priority: 'Normal', slaLabel: 'Completed' };
}
