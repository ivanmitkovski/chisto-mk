import { SortKey, StatusFilter } from '../types';

export const statusFilterOptions: ReadonlyArray<{ key: StatusFilter; label: string }> = [
  { key: 'ALL', label: 'All' },
  { key: 'NEW', label: 'New' },
  { key: 'IN_REVIEW', label: 'In review' },
  { key: 'APPROVED', label: 'Approved' },
  { key: 'DELETED', label: 'Rejected' },
];

export const columns: ReadonlyArray<{ key: SortKey; label: string }> = [
  { key: 'reportNumber', label: 'Report #' },
  { key: 'name', label: 'Name' },
  { key: 'location', label: 'Location' },
  { key: 'dateReportedAt', label: 'Date reported' },
  { key: 'status', label: 'Status' },
];
