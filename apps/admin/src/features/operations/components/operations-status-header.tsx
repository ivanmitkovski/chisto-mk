'use client';

import { useTranslations } from 'next-intl';
import { Card, StatusDot } from '@/components/ui';
import type { OperationsSnapshot, PanelState } from '../data/operations-adapter';
import { deriveSystemStatus } from '../lib/operations-health';
import styles from './operations-status-header.module.css';

export function OperationsStatusHeader({ snapshot }: { snapshot: OperationsSnapshot }) {
  const t = useTranslations('operations');
  const summary = deriveSystemStatus(snapshot);
  const latestUpdatedAt = Object.values(snapshot).reduce((latest, panel) => {
    const ts = Date.parse(panel.updatedAt);
    return Number.isFinite(ts) && ts > latest ? ts : latest;
  }, 0);

  const headline =
    summary.status === 'ok'
      ? t('status.allOperational')
      : summary.status === 'warn'
        ? t('status.degraded')
        : summary.status === 'critical'
          ? t('status.majorOutage')
          : t('status.unknown');

  return (
    <Card padding="md" className={`${styles.hero} ${styles[`hero_${summary.status}`]}`}>
      <div className={styles.main}>
        <StatusDot status={summary.status} label={headline} />
        <p className={styles.subline}>
          {t('status.summary', {
            ok: summary.okCount,
            warn: summary.warnCount,
            critical: summary.criticalCount,
          })}
        </p>
      </div>
      <p className={styles.updated}>
        {t('status.lastUpdated', {
          time: latestUpdatedAt > 0 ? new Date(latestUpdatedAt).toLocaleTimeString() : '—',
        })}
      </p>
    </Card>
  );
}

export function panelUpdatedAt(panel: PanelState<unknown>): string {
  return new Date(panel.updatedAt).toLocaleTimeString();
}
