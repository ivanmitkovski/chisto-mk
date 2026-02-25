import { IconName } from '@/components/ui';
import { ReportStatus } from '../types';

export function formatReportDate(value: string) {
  return new Intl.DateTimeFormat('en-GB').format(new Date(value));
}

export function formatReportStatus(status: ReportStatus) {
  if (status === 'IN_REVIEW') {
    return 'In review';
  }

  if (status === 'DELETED') {
    return 'Rejected';
  }

  return status.charAt(0) + status.slice(1).toLowerCase();
}

export function statusIconName(status: ReportStatus): IconName {
  if (status === 'APPROVED') {
    return 'check';
  }

  if (status === 'DELETED') {
    return 'trash';
  }

  return 'document-text';
}
