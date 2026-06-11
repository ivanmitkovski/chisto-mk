'use client';

import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import {
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import styles from './active-users-summary.module.css';

function TrendChart({ data, label }: { data: number[]; label: string }) {
  const chartData = useMemo(
    () => data.map((value, index) => ({ index, value })),
    [data],
  );
  if (chartData.length === 0) {
    return <p className={styles.emptyTrend}>{label}: —</p>;
  }
  return (
    <div className={styles.trendChart}>
      <p className={styles.trendLabel}>{label}</p>
      <ResponsiveContainer width="100%" height={80}>
        <LineChart data={chartData}>
          <XAxis dataKey="index" hide />
          <YAxis hide domain={['dataMin - 1', 'dataMax + 1']} />
          <Tooltip />
          <Line type="monotone" dataKey="value" stroke="var(--color-primary)" dot={false} strokeWidth={2} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

export function ActiveUsersSummaryCards() {
  const t = useTranslations('activeUsers');
  const { summary } = useActiveUsersLive();
  if (!summary) return null;

  const cards = [
    { label: t('currentActive'), value: summary.currentActive },
    { label: t('online'), value: summary.online },
    { label: t('away'), value: summary.away },
    { label: t('peakToday'), value: summary.peakToday },
    { label: t('peakWeek'), value: summary.peakWeek },
    { label: t('avgConcurrent'), value: summary.avgConcurrent },
  ];

  return (
    <section className={styles.grid}>
      {cards.map((card) => (
        <article key={card.label} className={styles.card}>
          <p className={styles.cardLabel}>{card.label}</p>
          <p className={styles.cardValue}>{card.value}</p>
        </article>
      ))}
      <TrendChart data={summary.trend5m} label={t('trend5m')} />
      <TrendChart data={summary.trend15m} label={t('trend15m')} />
      <TrendChart data={summary.trend1h} label={t('trend1h')} />
    </section>
  );
}
