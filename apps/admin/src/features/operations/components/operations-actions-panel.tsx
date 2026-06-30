'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Modal, StatusDot, useToast } from '@/components/ui';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import { OperationsDiagnosticsDrawer } from './operations-diagnostics-drawer';
import { OperationsMetricsDrawer } from './operations-metrics-drawer';
import styles from './operations-actions-panel.module.css';

type TestPushResult = {
  success: boolean;
  funnel: {
    inboxCreated: boolean;
    pushEnabled: boolean;
    fcmReady: boolean;
    activeTokenCount: number;
    outboxEnqueued: number;
    notificationId: string | null;
  };
  remediation: string | null;
};

export function OperationsActionsPanel() {
  const t = useTranslations('operations');
  const [busy, setBusy] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [resultOpen, setResultOpen] = useState(false);
  const [result, setResult] = useState<TestPushResult | null>(null);
  const { showToast } = useToast();

  async function sendTestPush() {
    setBusy(true);
    try {
      const response = await adminBrowserFetch<TestPushResult>('/notifications/admin/test-push', {
        method: 'POST',
      });
      setResult(response);
      setConfirmOpen(false);
      setResultOpen(true);
      showToast({
        tone: response.funnel.outboxEnqueued > 0 ? 'success' : 'warning',
        title: t('testPush.successTitle'),
        message: t('testPush.successMessage'),
      });
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
        description={`${t('testPush.confirmDescription')} ${t('testPush.funnelHint')}`}
        confirmLabel={t('testPush.confirmLabel')}
        isConfirming={busy}
        onCancel={() => setConfirmOpen(false)}
        onConfirm={() => void sendTestPush()}
      />

      <Modal
        open={resultOpen}
        title={t('testPush.resultTitle')}
        onClose={() => setResultOpen(false)}
      >
        {result ? (
          <ul className={styles.funnelList}>
            <li>
              <StatusDot status={result.funnel.inboxCreated ? 'ok' : 'critical'} label={t('testPush.inboxCreated')} />
            </li>
            <li>
              <StatusDot status={result.funnel.pushEnabled ? 'ok' : 'warn'} label={t('testPush.pushEnabled')} />
            </li>
            <li>
              <StatusDot status={result.funnel.fcmReady ? 'ok' : 'critical'} label={t('testPush.fcmReady')} />
            </li>
            <li>{t('testPush.activeTokens', { count: result.funnel.activeTokenCount })}</li>
            <li>{t('testPush.outboxEnqueued', { count: result.funnel.outboxEnqueued })}</li>
          </ul>
        ) : null}
        {result?.remediation ? <p className={styles.funnelRemediation}>{result.remediation}</p> : null}
        <p className={styles.funnelHint}>{t('testPush.funnelHint')}</p>
      </Modal>
    </>
  );
}
