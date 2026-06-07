'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Drawer, MetadataView, SectionState, StatusPill } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';

type DiagnosticsPayload = {
  systemInfo: {
    version: string;
    gitSha: string | null;
    nodeEnv: string;
    region: string | null;
    startedAt: string;
    uptimeSeconds: number;
    fcmEnabled: boolean;
  };
  readiness: {
    status: 'ok' | 'degraded';
    database: 'ok' | 'fail';
    redis: string;
    s3: string;
  };
};

export function OperationsDiagnosticsDrawer() {
  const t = useTranslations('operations');
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [payload, setPayload] = useState<DiagnosticsPayload | null>(null);

  async function runDiagnostics() {
    setLoading(true);
    setError(null);
    try {
      const [systemInfo, readiness] = await Promise.all([
        adminBrowserFetch<DiagnosticsPayload['systemInfo']>('/admin/operations/system-info', { method: 'GET' }),
        adminBrowserFetch<DiagnosticsPayload['readiness']>('/admin/operations/readiness', { method: 'GET' }),
      ]);
      setPayload({ systemInfo, readiness });
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
      <Drawer
        open={open}
        title={t('diagnostics.title')}
        onClose={() => setOpen(false)}
      >
        {loading ? <SectionState variant="loading" message={t('diagnostics.running')} /> : null}
        {error ? <SectionState variant="error" message={error} /> : null}
        {payload ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' }}>
            <div>
              <h3>{t('diagnostics.readiness')}</h3>
              <p>
                <StatusPill status={payload.readiness.status === 'ok' ? 'OK' : 'DEGRADED'} />
              </p>
              <MetadataView
                value={{
                  database: payload.readiness.database,
                  redis: payload.readiness.redis,
                  s3: payload.readiness.s3,
                }}
              />
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
