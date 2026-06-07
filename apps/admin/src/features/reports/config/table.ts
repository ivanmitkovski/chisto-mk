import { SortKey, StatusFilter } from '../types';

export const STATUS_FILTER_KEYS: StatusFilter[] = [
  'ALL',
  'DUPLICATES',
  'NEW',
  'IN_REVIEW',
  'APPROVED',
  'DELETED',
];

export const COLUMN_KEYS: SortKey[] = [
  'reportNumber',
  'name',
  'location',
  'dateReportedAt',
  'status',
];

const STATUS_FILTER_MESSAGE_KEYS: Record<StatusFilter, string> = {
  ALL: 'filters.all',
  DUPLICATES: 'filters.duplicates',
  NEW: 'filters.new',
  IN_REVIEW: 'filters.inReview',
  APPROVED: 'filters.approved',
  DELETED: 'filters.rejected',
};

const COLUMN_MESSAGE_KEYS: Record<SortKey, string> = {
  reportNumber: 'columns.reportNumber',
  name: 'columns.name',
  location: 'columns.location',
  dateReportedAt: 'columns.dateReported',
  status: 'columns.status',
};

export function getStatusFilterLabel(key: StatusFilter, t: (messageKey: string) => string): string {
  return t(STATUS_FILTER_MESSAGE_KEYS[key]);
}

export function getColumnLabel(key: SortKey, t: (messageKey: string) => string): string {
  return t(COLUMN_MESSAGE_KEYS[key]);
}

export function getStatusFilterOptions(t: (messageKey: string) => string) {
  return STATUS_FILTER_KEYS.map((key) => ({ key, label: getStatusFilterLabel(key, t) }));
}

export function getColumnOptions(t: (messageKey: string) => string) {
  return COLUMN_KEYS.map((key) => ({ key, label: getColumnLabel(key, t) }));
}
