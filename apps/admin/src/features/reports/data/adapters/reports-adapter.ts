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
    reportNumber: fallback.reportNumber,
    status: fallback.status,
    priority: 'MEDIUM',
    title: fallback.name,
    description: `Review details for ${fallback.name}.`,
    location: fallback.location,
    submittedAt: fallback.dateReportedAt,
    reporterAlias: 'Citizen (unverified)',
    reporterTrust: 'Bronze',
    evidence: [
      {
        id: `${fallback.id}-ev-1`,
        label: 'Submitted photo evidence',
        kind: 'image',
        sizeLabel: '2.1 MB',
        uploadedAt: fallback.dateReportedAt,
        previewUrl: '/mock/reports/r-1-photo-1.svg',
        previewAlt: 'Submitted evidence image preview',
      },
    ],
    timeline: [
      {
        id: `${fallback.id}-tl-1`,
        title: 'Report submitted',
        detail: 'Report received through citizen reporting flow.',
        actor: 'Citizen',
        occurredAt: fallback.dateReportedAt,
        tone: 'info',
      },
      {
        id: `${fallback.id}-tl-2`,
        title: 'Added to moderation queue',
        detail: 'Queued for manual moderation review.',
        actor: 'System',
        occurredAt: fallback.dateReportedAt,
        tone: 'neutral',
      },
    ],
    moderation: {
      queueLabel: 'General Queue',
      slaLabel: '4h remaining',
      assignedTeam: 'City Moderation',
    },
    mapPin: {
      latitude: 41.9981,
      longitude: 21.4254,
      label: fallback.location,
    },
  };
}
