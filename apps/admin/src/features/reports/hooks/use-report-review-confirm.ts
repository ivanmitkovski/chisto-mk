'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';

export type PendingReportAction = 'set-in-review' | 'approve' | 'reject';

type UseReportReviewConfirmOptions = {
  isUpdating: boolean;
  setInReview: () => Promise<boolean>;
  approveReport: () => Promise<boolean>;
  rejectReport: (reason: string) => Promise<boolean>;
  otherViewersCount?: number;
};

export function useReportReviewConfirm({
  isUpdating,
  setInReview,
  approveReport,
  rejectReport,
  otherViewersCount = 0,
}: UseReportReviewConfirmOptions) {
  const tConfirm = useTranslations('reports.confirm');
  const tRejection = useTranslations('reports.rejectionReasons');
  const [pendingAction, setPendingAction] = useState<PendingReportAction | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [rejectionNotes, setRejectionNotes] = useState('');
  const [rejectionReasonError, setRejectionReasonError] = useState<string | null>(null);

  function closeConfirmModal() {
    if (isUpdating) {
      return;
    }

    setPendingAction(null);
    setRejectionReasonError(null);
    setRejectionReason('');
    setRejectionNotes('');
  }

  async function confirmAction() {
    if (!pendingAction) {
      return;
    }

    if (pendingAction === 'reject') {
      if (!rejectionReason) {
        setRejectionReasonError(tRejection('required'));
        return;
      }

      setRejectionReasonError(null);
      const composedReason = rejectionNotes.trim()
        ? `${rejectionReason}. Notes: ${rejectionNotes.trim()}`
        : rejectionReason;
      const ok = await rejectReport(composedReason);
      if (ok) closeConfirmModal();
      return;
    }

    if (pendingAction === 'approve') {
      const ok = await approveReport();
      if (ok) closeConfirmModal();
      return;
    }

    const ok = await setInReview();
    if (ok) closeConfirmModal();
  }

  const modalTitle =
    pendingAction === 'approve'
      ? tConfirm('approvalTitle')
      : pendingAction === 'reject'
        ? tConfirm('rejectionTitle')
        : tConfirm('statusUpdateTitle');

  const baseDescription =
    pendingAction === 'approve'
      ? tConfirm('approvalDescription')
      : pendingAction === 'reject'
        ? tConfirm('rejectionDescription')
        : tConfirm('statusUpdateDescription');

  const concurrentWarning =
    pendingAction !== null && otherViewersCount > 0
      ? tConfirm('concurrentViewersWarning', { count: otherViewersCount })
      : '';

  const modalDescription = concurrentWarning
    ? `${baseDescription} ${concurrentWarning}`
    : baseDescription;
  const confirmLabel =
    pendingAction === 'approve'
      ? tConfirm('approveLabel')
      : pendingAction === 'reject'
        ? tConfirm('rejectLabel')
        : tConfirm('setInReviewLabel');

  return {
    pendingAction,
    setPendingAction,
    rejectionReason,
    rejectionNotes,
    rejectionReasonError,
    setRejectionReason,
    setRejectionNotes,
    setRejectionReasonError,
    closeConfirmModal,
    confirmAction,
    modalTitle,
    modalDescription,
    confirmLabel,
  };
}
