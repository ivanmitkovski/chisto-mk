'use client';

import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import type { EngagementAnalytics, RealtimeAnalytics } from '../data/active-users.types';
import styles from './engagement-charts.module.css';

export function EngagementCharts({
  engagement,
  realtime,
}: {
  engagement: EngagementAnalytics;
  realtime: RealtimeAnalytics;
}) {
  const t = useTranslations('activeUsers');
  const dauData = useMemo(
    () => engagement.history.slice(0, 14).reverse().map((row) => ({
      date: row.date.slice(5),
      dau: row.dau,
      mau: row.mau,
    })),
    [engagement.history],
  );

  return (
    <section className={styles.grid}>
      <article className={styles.card}>
        <h3>{t('engagement')}</h3>
        <ul className={styles.stats}>
          <li>DAU: {engagement.dau}</li>
          <li>WAU: {engagement.wau}</li>
          <li>MAU: {engagement.mau}</li>
          <li>DAU/MAU: {engagement.dauMauRatio}</li>
          <li>{t('sessionsPerUser')}: {engagement.sessionsPerUser}</li>
        </ul>
      </article>
      <article className={styles.card}>
        <h3>{t('realtimeMetrics')}</h3>
        <ul className={styles.stats}>
          <li>{t('concurrent')}: {realtime.concurrent}</li>
          <li>{t('reportDrafts')}: {realtime.activeReportDrafts}</li>
          <li>{t('reportsToday')}: {realtime.reportsSubmittedToday}</li>
          <li>{t('registrationsToday')}: {realtime.registrationsToday}</li>
        </ul>
      </article>
      <article className={`${styles.card} ${styles.wide}`}>
        <h3>{t('dauMauTrend')}</h3>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={dauData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="dau" fill="#2563eb" />
            <Bar dataKey="mau" fill="#9333ea" />
          </BarChart>
        </ResponsiveContainer>
      </article>
    </section>
  );
}
