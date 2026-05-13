import { ReportStatus } from '../../src/prisma-client';

type ReportRow = {
  id: string;
  siteId: string;
  authorId: string;
  status: ReportStatus;
  createdAt: Date;
  updatedAt: Date;
};

export function buildReportRow(overrides: Partial<ReportRow> = {}): ReportRow {
  const id = overrides.id ?? 'report_row_1';
  const now = overrides.createdAt ?? new Date('2026-02-01T12:00:00.000Z');
  return {
    id,
    siteId: overrides.siteId ?? 'site_row_1',
    authorId: overrides.authorId ?? 'user_row_1',
    status: overrides.status ?? ReportStatus.NEW,
    createdAt: overrides.createdAt ?? now,
    updatedAt: overrides.updatedAt ?? now,
  };
}
