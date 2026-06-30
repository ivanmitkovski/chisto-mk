'use client';

import { useTranslations } from 'next-intl';
import { MetricTile, MetricTileGrid } from '@/components/ui';
import type { OperationsSnapshot, PanelState } from '../data/operations-snapshot';
import styles from './operations-workspace.module.css';

type FeedDiagnosticsData = OperationsSnapshot['feedDiagnostics'] extends PanelState<infer T> ? T : never;

export function OperationsFeedDiagnosticsPanel({ data }: { data: FeedDiagnosticsData }) {
  const t = useTranslations('operations');

  return (
    <>
      <MetricTileGrid>
        <MetricTile label={t('metrics.reasonCodes')} value={data.reasonCodes.length} />
        <MetricTile label={t('metrics.integrityDemotions')} value={data.recentIntegrityDemotions} />
        {data.paginationContinuityIssues != null ? (
          <MetricTile label={t('metrics.paginationIssues')} value={data.paginationContinuityIssues} />
        ) : null}
        {data.rankerMode ? <MetricTile label={t('metrics.rankerMode')} value={data.rankerMode} /> : null}
      </MetricTileGrid>
      {data.reasonCodes.length > 0 ? (
        <ul className={styles.breakdownList}>
          {data.reasonCodes.slice(0, 5).map((item) => (
            <li key={item.code}>
              <strong>{item.code}</strong> — {item.count}
            </li>
          ))}
        </ul>
      ) : null}
      {data.rankDriftSnapshot && data.rankDriftSnapshot.length > 0 ? (
        <ul className={styles.breakdownList}>
          {data.rankDriftSnapshot.slice(0, 3).map((item) => (
            <li key={item.siteId}>
              {item.siteId.slice(0, 8)}… · score {item.score.toFixed(2)}
            </li>
          ))}
        </ul>
      ) : null}
    </>
  );
}
