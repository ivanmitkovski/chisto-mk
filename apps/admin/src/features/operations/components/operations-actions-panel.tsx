'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, useToast } from '@/components/ui';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import { OperationsDiagnosticsDrawer } from './operations-diagnostics-drawer';
import { OperationsMetricsDrawer } from './operations-metrics-drawer';
import styles from './operations-actions-panel.module.css';

export function OperationsActionsPanel() {
  const t = useTranslations('operations');
  const [busy, setBusy] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const { showToast } = useToast();

  async function sendTestPush() {
    setBusy(true);
    try {
      await adminBrowserFetch('/notifications/admin/test-push', { method: 'POST' });
      showToast({
        tone: 'success',
        title: t('testPush.successTitle'),
        message: t('testPush.successMessage'),
      });
      setConfirmOpen(false);
    } catch (error) {
      showToast({
        tone: 'warning',
        title: t('testPush.failedTitle'),
        message: error instanceof Error ? error.message : t('testPush.failedMessage'),
      });
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <div className={styles.toolbar}>
        <Can permission="operations:write">
          <Button variant="outline" disabled={busy} onClick={() => setConfirmOpen(true)}>
            {t('testPush.button')}
          </Button>
        </Can>
        <OperationsDiagnosticsDrawer />
        <OperationsMetricsDrawer />
      </div>

      <ActionConfirmModal
        isOpen={confirmOpen}
        title={t('testPush.confirmTitle')}
        description={t('testPush.confirmDescription')}
        confirmLabel={t('testPush.confirmLabel')}
        isConfirming={busy}
        onCancel={() => setConfirmOpen(false)}
        onConfirm={() => void sendTestPush()}
      />
    </>
  );
}
