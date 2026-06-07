'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Drawer, MetadataView, MetricTile, MetricTileGrid, SectionState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';

type MetricsSnapshot = {
  requestsTotal: number;
  requestsFailed: number;
  p95Ms: number;
  pushSendsTotal: number;
  pushSendsSuccess: number;
  pushSendsFailure: number;
  pushQueueDepth: number;
  pushDeadLetterCount: number;
  mapOutboxPending: number;
  feedCacheHitRate: number;
  emailQueueDepth: number;
  emailDeadLetterCount: number;
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
        {error ? <SectionState variant="error" message={error} /> : null}
        {snapshot ? (
          <>
            <MetricTileGrid>
              <MetricTile label={t('metrics.totalSends')} value={snapshot.pushSendsTotal} />
              <MetricTile label={t('metrics.success')} value={snapshot.pushSendsSuccess} tone="success" />
              <MetricTile label={t('metrics.failures')} value={snapshot.pushSendsFailure} tone="danger" />
              <MetricTile label={t('metrics.queueDepth')} value={snapshot.pushQueueDepth} />
              <MetricTile label={t('metrics.deadLetters')} value={snapshot.pushDeadLetterCount} />
              <MetricTile label={t('metrics.outboxPending')} value={snapshot.mapOutboxPending} />
              <MetricTile label={t('metrics.emailQueueDepth')} value={snapshot.emailQueueDepth} />
            </MetricTileGrid>
            <MetadataView value={snapshot} variant="block" />
          </>
        ) : null}
      </Drawer>
    </>
  );
}
