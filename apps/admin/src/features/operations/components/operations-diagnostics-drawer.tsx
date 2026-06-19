'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Drawer, MetadataView, SectionState, StatusPill } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import styles from './operations-diagnostics-drawer.module.css';

type DiagnosticsBundle = {
  systemInfo: Record<string, unknown>;
  readiness: { status: string; database: string; redis: string; s3: string };
  pushDiagnostics: {
    fcmEnabled: boolean;
    fcmReady: boolean;
    projectId: string | null;
    credentialStatus: string;
    deadLetterTotal: number;
    topErrorCodes: Array<{ code: string; count: number }>;
    remediation: string | null;
  };
  pushHealth: { status: string; alerts: string[] };
  emailHealth: { status: string; alerts: string[] };
  feedDiagnostics: {
    reasonCodes: Array<{ code: string; count: number }>;
    recentIntegrityDemotions: number;
  };
};

export function OperationsDiagnosticsDrawer() {
  const t = useTranslations('operations');
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [payload, setPayload] = useState<DiagnosticsBundle | null>(null);

  async function runDiagnostics() {
    setLoading(true);
    setError(null);
    try {
      const bundle = await adminBrowserFetch<DiagnosticsBundle>('/admin/operations/diagnostics-bundle', {
        method: 'GET',
      });
      setPayload(bundle);
    } catch (fetchError) {
      setError(fetchError instanceof Error ? fetchError.message : t('diagnostics.failed'));
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <Button
        variant="outline"
        onClick={() => {
          setOpen(true);
          void runDiagnostics();
        }}
      >
        {t('diagnostics.button')}
      </Button>
      <Drawer open={open} title={t('diagnostics.title')} onClose={() => setOpen(false)}>
        {loading ? <SectionState variant="loading" message={t('diagnostics.running')} /> : null}
        {error ? (
          <>
            <SectionState variant="error" message={error} />
            <Button variant="outline" onClick={() => void runDiagnostics()}>
              {t('diagnostics.retry')}
            </Button>
          </>
        ) : null}
        {payload ? (
          <div className={styles.stack}>
            <div>
              <h3>{t('diagnostics.pushDelivery')}</h3>
              <p>
                <StatusPill status={payload.pushHealth.status === 'ok' ? 'OK' : 'DEGRADED'} />
              </p>
              <MetadataView
                value={{
                  fcmEnabled: payload.pushDiagnostics.fcmEnabled,
                  fcmReady: payload.pushDiagnostics.fcmReady,
                  projectId: payload.pushDiagnostics.projectId,
                  credentialStatus: payload.pushDiagnostics.credentialStatus,
                  deadLetterTotal: payload.pushDiagnostics.deadLetterTotal,
                }}
              />
              {payload.pushDiagnostics.topErrorCodes.length > 0 ? (
                <ul className={styles.errorCodeList}>
                  {payload.pushDiagnostics.topErrorCodes.map((row) => (
                    <li key={row.code}>
                      <strong>{row.code}</strong> — {row.count}
                    </li>
                  ))}
                </ul>
              ) : null}
              {payload.pushDiagnostics.remediation ? (
                <p className={styles.remediation}>{payload.pushDiagnostics.remediation}</p>
              ) : null}
            </div>
            <div>
              <h3>{t('diagnostics.emailDelivery')}</h3>
              <p>
                <StatusPill status={payload.emailHealth.status === 'ok' ? 'OK' : 'DEGRADED'} />
              </p>
              {payload.emailHealth.alerts.length > 0 ? (
                <p className={styles.remediation}>{payload.emailHealth.alerts.join(', ')}</p>
              ) : null}
            </div>
            <div>
              <h3>{t('diagnostics.feedIntegrity')}</h3>
              <MetadataView
                value={{
                  recentIntegrityDemotions: payload.feedDiagnostics.recentIntegrityDemotions,
                  reasonCodes: payload.feedDiagnostics.reasonCodes.length,
                }}
              />
            </div>
            <div>
              <h3>{t('diagnostics.readiness')}</h3>
              <p>
                <StatusPill status={payload.readiness.status === 'ok' ? 'OK' : 'DEGRADED'} />
              </p>
              <MetadataView value={payload.readiness} />
            </div>
            <div>
              <h3>{t('diagnostics.systemInfo')}</h3>
              <MetadataView value={payload.systemInfo} />
            </div>
          </div>
        ) : null}
      </Drawer>
    </>
  );
}
