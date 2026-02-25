import { MOCK_DELAY_MS } from '@/features/shared/constants/mock';
import { delay } from '@/features/shared/utils/delay';
import { ReportDetail, ReportRow } from '../../types';
import { reportDetail, reports } from '../mock-data';

export async function getReports(): Promise<ReportRow[]> {
  await delay(MOCK_DELAY_MS);
  return reports.map((report) => ({ ...report }));
}

export async function getReportDetail(reportId: string): Promise<ReportDetail> {
  await delay(MOCK_DELAY_MS);

  if (reportDetail.id === reportId) {
    return { ...reportDetail };
  }

  const fallback = reports.find((report) => report.id === reportId);

  if (!fallback) {
    throw new Error('Report not found');
  }

  return {
    id: fallback.id,
    status: fallback.status,
    title: fallback.name,
    description: `Review details for ${fallback.name}.`,
    location: fallback.location,
  };
}
