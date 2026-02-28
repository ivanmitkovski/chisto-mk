export { ReportReviewCard } from './components/report-review-card';
export { ReportsTable } from './components/reports-table';
export { DuplicateReportsWorkspace } from './components/duplicate-reports-workspace';
export {
  getDuplicateReportGroup,
  getDuplicateReportGroups,
  getReportDetail,
  getReports,
} from './data/adapters/reports-adapter';
export type {
  DuplicateReportGroup,
  DuplicateReportItem,
  MergeDuplicateReportsResult,
  ReportDetail,
  ReportRow,
  ReportStatus,
} from './types';
