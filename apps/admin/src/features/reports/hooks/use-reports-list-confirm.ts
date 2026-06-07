'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import type { ReportRow } from '@/features/reports/types';
import { useReportsListActions } from '@/features/reports/hooks/use-reports-list-actions';

type PendingAction =
  | { kind: 'approve'; report: ReportRow }
  | { kind: 'reject'; report: ReportRow };

type UseReportsListConfirmOptions = {
  onOptimisticStatus?: (id: string, status: ReportRow['status']) => void;
  onRollbackStatus?: (id: string, status: ReportRow['status']) => void;
};

export function useReportsListConfirm(options: UseReportsListConfirmOptions = {}) {
  const tRejection = useTranslations('reports.rejectionReasons');
  const [pendingAction, setPendingAction] = useState<PendingAction | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [rejectionNotes, setRejectionNotes] = useState('');
  const [rejectionReasonError, setRejectionReasonError] = useState<string | null>(null);

  const { approveReport, rejectReport, isPending } = useReportsListActions(options);

  function openApproveModal(report: ReportRow) {
    setPendingAction({ kind: 'approve', report });
    setRejectionReason('');
    setRejectionNotes('');
    setRejectionReasonError(null);
  }

  function openRejectModal(report: ReportRow) {
    setPendingAction({ kind: 'reject', report });
    setRejectionReason('');
    setRejectionNotes('');
    setRejectionReasonError(null);
  }

  function closeConfirmModal() {
    if (isPending) return;
    setPendingAction(null);
    setRejectionReason('');
    setRejectionNotes('');
    setRejectionReasonError(null);
  }

  async function confirmAction() {
    if (!pendingAction || isPending) return;
    const { report } = pendingAction;
    if (pendingAction.kind === 'approve') {
      const ok = await approveReport(report.id, report.status);
      if (ok) closeConfirmModal();
      return;
    }
    if (!rejectionReason.trim()) {
      setRejectionReasonError(tRejection('required'));
      return;
    }
    const composedReason = rejectionNotes.trim()
      ? `${rejectionReason.trim()}. Notes: ${rejectionNotes.trim()}`
      : rejectionReason.trim();
    const ok = await rejectReport(report.id, composedReason, report.status);
    if (ok) closeConfirmModal();
  }

  return {
    pendingAction,
    rejectionReason,
    setRejectionReason,
    rejectionNotes,
    setRejectionNotes,
    rejectionReasonError,
    setRejectionReasonError,
    isConfirming: isPending,
    openApproveModal,
    openRejectModal,
    closeConfirmModal,
    confirmAction,
  };
}
