import { IconName } from '@/components/ui';
import { formatAdminDate } from '@/lib/i18n/format-admin-datetime';
import { ADMIN_LOCALE_BCP47, DEFAULT_ADMIN_LOCALE } from '@/lib/preferences/admin-locale';
import { ReportStatus } from '../types';

/** Report statuses that represent a final decision (no further approve/reject actions). */
const FINAL_STATUSES: ReportStatus[] = ['APPROVED', 'DELETED'];

export function isReportFinalStatus(status: ReportStatus): boolean {
  return FINAL_STATUSES.includes(status);
}

export function formatReportDate(
  value: string,
  locale: string = ADMIN_LOCALE_BCP47[DEFAULT_ADMIN_LOCALE],
) {
  return formatAdminDate(value, locale);
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
