import { useState } from 'react';
import { SnackState } from '@/components/ui';
import { MOCK_DELAY_MS } from '@/features/shared/constants/mock';
import { delay } from '@/features/shared/utils/delay';
import { ReportDetail, ReportStatus } from '../types';

type ReviewAction = 'approve' | 'reject';

export function useReportReview(initialReport: ReportDetail) {
  const [report, setReport] = useState<ReportDetail>(initialReport);
  const [isUpdating, setIsUpdating] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  async function mutateStatus(nextStatus: ReportStatus, action: ReviewAction) {
    setIsUpdating(true);
    await delay(MOCK_DELAY_MS + 60);
    setReport((prev) => ({ ...prev, status: nextStatus }));
    setSnack(
      action === 'approve'
        ? {
            tone: 'success',
            title: 'Report approved',
            message: 'This report has been accepted successfully.',
          }
        : {
            tone: 'warning',
            title: 'Report rejected',
            message: 'This report has been rejected and marked removed.',
          },
    );
    setIsUpdating(false);
  }

  return {
    report,
    isUpdating,
    snack,
    approveReport: () => mutateStatus('APPROVED', 'approve'),
    rejectReport: () => mutateStatus('DELETED', 'reject'),
    clearSnack: () => setSnack(null),
  };
}
