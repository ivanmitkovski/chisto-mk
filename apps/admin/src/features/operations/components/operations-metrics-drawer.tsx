'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Drawer, MetadataView, MetricTile, MetricTileGrid, SectionState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import styles from './operations-workspace.module.css';

type MetricsSnapshot = {
  requestsTotal: number;
  requestsFailed: number;
  p50Ms: number;
  p95Ms: number;
  p99Ms: number;
  pushSendsTotal: number;
  pushSendsSuccess: number;
  pushSendsFailure: number;
  pushSendsRevoked: number;
  pushQueueDepth: number;
  pushActiveLeases: number;
  pushDeadLetterCount: number;
  pushDispatchSkippedFcmNotReady: number;
  pushDispatchSkippedNoTokens: number;
  mapOutboxPending: number;
  mapOutboxFailed: number;
  feedRequestsTotal: number;
  feedCacheHitRate: number;
  emailQueueDepth: number;
  emailDeadLetterCount: number;
  reportSideEffectFailedTotal: number;
  processMemory: { rssMb: number; heapUsedMb: number; heapTotalMb: number };
  capturedAt: string;
};

export function OperationsMetricsDrawer() {
  const t = useTranslations('operations');
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [snapshot, setSnapshot] = useState<MetricsSnapshot | null>(null);

  async function loadMetrics() {
    setLoading(true);
    setError(null);
    try {
      const response = await adminBrowserFetch<MetricsSnapshot>('/admin/operations/metrics-snapshot', {
        method: 'GET',
      });
      setSnapshot(response);
    } catch (fetchError) {
      setError(fetchError instanceof Error ? fetchError.message : t('metricsDrawer.failed'));
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
          void loadMetrics();
        }}
      >
        {t('metricsDrawer.button')}
      </Button>
      <Drawer open={open} title={t('metricsDrawer.title')} onClose={() => setOpen(false)}>
        {loading ? <SectionState variant="loading" message={t('metricsDrawer.loading')} /> : null}
        {error ? (
          <>
            <SectionState variant="error" message={error} />
            <Button variant="outline" onClick={() => void loadMetrics()}>
              {t('diagnostics.retry')}
            </Button>
          </>
        ) : null}
        {snapshot ? (
          <>
            <MetricTileGrid>
              <MetricTile label={t('metrics.httpRequests')} value={snapshot.requestsTotal} />
              <MetricTile label={t('metrics.httpFailures')} value={snapshot.requestsFailed} tone="danger" />
              <MetricTile label={t('metrics.p95Latency')} value={`${snapshot.p95Ms}ms`} />
              <MetricTile label={t('metrics.totalSends')} value={snapshot.pushSendsTotal} />
              <MetricTile label={t('metrics.success')} value={snapshot.pushSendsSuccess} tone="success" />
              <MetricTile label={t('metrics.failures')} value={snapshot.pushSendsFailure} tone="danger" />
              <MetricTile label={t('metrics.revoked')} value={snapshot.pushSendsRevoked} />
              <MetricTile label={t('metrics.queueDepth')} value={snapshot.pushQueueDepth} />
              <MetricTile label={t('metrics.activeLeases')} value={snapshot.pushActiveLeases} />
              <MetricTile label={t('metrics.deadLetters')} value={snapshot.pushDeadLetterCount} />
              <MetricTile label={t('metrics.outboxPending')} value={snapshot.mapOutboxPending} />
              <MetricTile label={t('metrics.mapOutboxFailed')} value={snapshot.mapOutboxFailed} />
              <MetricTile label={t('metrics.emailQueueDepth')} value={snapshot.emailQueueDepth} />
              <MetricTile label={t('metrics.feedRequests')} value={snapshot.feedRequestsTotal} />
              <MetricTile label={t('metrics.feedCacheHitRate')} value={snapshot.feedCacheHitRate} />
            </MetricTileGrid>
            <details className={styles.metricsDetails}>
              <summary>{t('metricsDrawer.rawSnapshot')}</summary>
              <MetadataView value={snapshot} variant="block" />
            </details>
          </>
        ) : null}
      </Drawer>
    </>
  );
}
