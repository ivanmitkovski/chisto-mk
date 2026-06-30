import type { ReportStatus } from '../types';

export type QueueMetaTranslator = {
  (key: 'queuePriority.Critical' | 'queuePriority.High' | 'queuePriority.Normal'): string;
  (key: 'sla.newRemaining' | 'sla.inReviewRemaining' | 'sla.completed'): string;
};

export function queueMeta(
  status: ReportStatus,
  t: QueueMetaTranslator,
): { priority: 'Critical' | 'High' | 'Normal'; slaLabel: string } {
  if (status === 'NEW') {
    return { priority: 'Critical', slaLabel: t('sla.newRemaining') };
  }
  if (status === 'IN_REVIEW') {
    return { priority: 'High', slaLabel: t('sla.inReviewRemaining') };
  }
  return { priority: 'Normal', slaLabel: t('sla.completed') };
}

export function formatQueuePriority(
  priority: 'Critical' | 'High' | 'Normal',
  t: QueueMetaTranslator,
): string {
  return t(`queuePriority.${priority}`);
}
