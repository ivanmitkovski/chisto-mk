export type ReportStatus = 'NEW' | 'IN_REVIEW' | 'APPROVED' | 'DELETED';

export type ReportRow = {
  id: string;
  reportNumber: string;
  name: string;
  location: string;
  dateReportedAt: string;
  status: ReportStatus;
};

export type ReportDetail = {
  id: string;
  status: ReportStatus;
  title: string;
  description: string;
  location: string;
};

export type StatusFilter = 'ALL' | ReportStatus;
export type SortDirection = 'asc' | 'desc';
export type SortKey = 'reportNumber' | 'name' | 'location' | 'dateReportedAt' | 'status';
