'use client';

import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { Button, Card, SectionState } from '@/components/ui';
import type { EngagementAnalytics } from '../data/active-users.types';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import styles from './engagement-charts.module.css';

type EngagementChartsInnerProps = {
  engagement: EngagementAnalytics;
  engagementError?: string;
};

export function EngagementChartsInner({ engagement, engagementError }: EngagementChartsInnerProps) {
  const t = useTranslations('activeUsers');
  const { refresh } = useActiveUsersLive();

  const dauData = useMemo(
    () =>
      engagement.history
        .slice(0, 14)
        .reverse()
        .map((row) => ({
          date: row.date.slice(5),
          dau: row.dau,
          mau: row.mau,
        })),
    [engagement.history],
  );

  if (engagementError) {
    return (
      <SectionState variant="error" message={engagementError}>
        <Button type="button" variant="outline" size="sm" onClick={() => refresh()}>
          {t('retry')}
        </Button>
      </SectionState>
    );
  }

  return (
    <section className={styles.grid}>
      <Card padding="md" className={styles.card}>
        <h3 className={styles.title}>{t('engagement')}</h3>
        <ul className={styles.stats}>
          <li>
            {t('metrics.dau')}: {engagement.dau}
          </li>
          <li>
            {t('metrics.wau')}: {engagement.wau}
          </li>
          <li>
            {t('metrics.mau')}: {engagement.mau}
          </li>
          <li>
            {t('metrics.dauMauRatio')}: {engagement.dauMauRatio}
          </li>
          <li>
            {t('sessionsPerUser')}: {engagement.sessionsPerUser}
          </li>
        </ul>
      </Card>
      <Card padding="md" className={`${styles.card} ${styles.wide}`}>
        <h3 className={styles.title}>{t('dauMauTrend')}</h3>
        {dauData.length === 0 ? (
          <p className={styles.stats}>{t('chart.noHistory')}</p>
        ) : (
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={dauData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="date" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="dau" fill="var(--color-primary)" name={t('metrics.dau')} />
              <Bar dataKey="mau" fill="var(--color-info)" name={t('metrics.mau')} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </Card>
    </section>
  );
}
