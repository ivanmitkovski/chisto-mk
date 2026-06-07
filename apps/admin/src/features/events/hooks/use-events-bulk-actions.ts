'use client';

import { useCallback, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';

type BulkModerateResult = {
  processed: number;
  failed: Array<{ id: string; code?: string; message?: string }>;
};

type UseEventsBulkActionsOptions = {
  canWriteCleanupEvents: boolean;
  selectedIds: Set<string>;
  clearSelection: () => void;
  refresh: () => void;
};

export function useEventsBulkActions({
  canWriteCleanupEvents,
  selectedIds,
  clearSelection,
  refresh,
}: UseEventsBulkActionsOptions) {
  const { showToast, clearToast } = useToast();
  const t = useTranslations('events.bulkModerate');
  const [bulkBusy, setBulkBusy] = useState(false);
  const [bulkDeclineOpen, setBulkDeclineOpen] = useState(false);
  const [bulkDeclineReason, setBulkDeclineReason] = useState('');
  const [bulkDeclineError, setBulkDeclineError] = useState<string | null>(null);

  function summarizeBulkModeration(result: BulkModerateResult, action: 'approve' | 'decline') {
    const failedCount = result.failed.length;
    if (failedCount === 0) {
      return {
        tone: 'success' as const,
        title: t(`${action}.completeTitle`),
        message: t(`${action}.completeMessage`, { count: result.processed }),
      };
    }
    if (result.processed > 0) {
      return {
        tone: 'warning' as const,
        title: t(`${action}.partialTitle`),
        message: t(`${action}.partialMessage`, { processed: result.processed, failed: failedCount }),
      };
    }
    return {
      tone: 'warning' as const,
      title: t(`${action}.failedTitle`),
      message: t(`${action}.failedMessage`, { failed: failedCount }),
    };
  }

  function closeBulkDeclineModal() {
    setBulkDeclineOpen(false);
    setBulkDeclineReason('');
    setBulkDeclineError(null);
  }

  const [bulkApproveOpen, setBulkApproveOpen] = useState(false);

  const bulkApprove = useCallback(async () => {
    if (!canWriteCleanupEvents || selectedIds.size === 0) return;
    setBulkBusy(true);
    clearToast();
    try {
      const clientJobId = crypto.randomUUID();
      const result = await adminBrowserFetch<BulkModerateResult>('/admin/cleanup-events/bulk-moderate', {
        method: 'POST',
        body: { eventIds: [...selectedIds], action: 'APPROVED', clientJobId },
      });
      const toast = summarizeBulkModeration(result, 'approve');
      showToast(toast);
      if (result.failed.length === 0) {
        clearSelection();
      }
      refresh();
    } catch {
      showToast({
        tone: 'warning',
        title: t('approve.errorTitle'),
        message: t('approve.errorMessage'),
      });
    } finally {
      setBulkBusy(false);
    }
  }, [canWriteCleanupEvents, clearSelection, clearToast, refresh, selectedIds, showToast, t]);

  const openBulkDeclineModal = useCallback(() => {
    if (!canWriteCleanupEvents || selectedIds.size === 0) return;
    setBulkDeclineReason('');
    setBulkDeclineError(null);
    setBulkDeclineOpen(true);
  }, [canWriteCleanupEvents, selectedIds]);

  const submitBulkDecline = useCallback(async () => {
    const reason = bulkDeclineReason.trim();
    if (reason.length < 3) {
      setBulkDeclineError(t('declineReasonMinLength'));
      return;
    }
    setBulkBusy(true);
    clearToast();
    try {
      const clientJobId = crypto.randomUUID();
      const result = await adminBrowserFetch<BulkModerateResult>('/admin/cleanup-events/bulk-moderate', {
        method: 'POST',
        body: {
          eventIds: [...selectedIds],
          action: 'DECLINED',
          declineReason: reason,
          clientJobId,
        },
      });
      const toast = summarizeBulkModeration(result, 'decline');
      showToast(toast);
      closeBulkDeclineModal();
      if (result.failed.length === 0) {
        clearSelection();
      }
      refresh();
    } catch {
      showToast({
        tone: 'warning',
        title: t('decline.errorTitle'),
        message: t('decline.errorMessage'),
      });
    } finally {
      setBulkBusy(false);
    }
  }, [bulkDeclineReason, clearSelection, clearToast, refresh, selectedIds, showToast, t]);

  return {
    bulkBusy,
    bulkDeclineOpen,
    bulkDeclineReason,
    setBulkDeclineReason,
    bulkDeclineError,
    setBulkDeclineError,
    closeBulkDeclineModal,
    bulkApproveOpen,
    setBulkApproveOpen,
    bulkApprove,
    openBulkDeclineModal,
    submitBulkDecline,
  };
}
