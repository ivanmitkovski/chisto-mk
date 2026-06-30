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
import { Card } from '@/components/ui';
import styles from './active-users-summary.module.css';

export function ActiveUsersSummaryTrendInner({ data, label }: { data: number[]; label: string }) {
  const t = useTranslations('activeUsers');
  const chartData = useMemo(
    () => data.map((value, index) => ({ index, value })),
    [data],
  );

  if (chartData.length === 0) {
    return (
      <Card padding="sm" className={styles.trendCard}>
        <p className={styles.trendLabel}>{label}</p>
        <p className={styles.emptyTrend}>—</p>
      </Card>
    );
  }

  return (
    <Card padding="sm" className={styles.trendCard}>
      <p className={styles.trendLabel}>{label}</p>
      <ResponsiveContainer width="100%" height={80}>
        <LineChart data={chartData}>
          <XAxis dataKey="index" hide />
          <YAxis hide domain={['dataMin - 1', 'dataMax + 1']} />
          <Tooltip
            contentStyle={{
              backgroundColor: 'var(--bg-surface)',
              border: '1px solid var(--border-default)',
              borderRadius: 'var(--radius-md)',
            }}
            formatter={(value) => [value ?? 0, t('chart.concurrent')]}
          />
          <Line
            type="monotone"
            dataKey="value"
            stroke="var(--color-primary)"
            dot={false}
            strokeWidth={2}
          />
        </LineChart>
      </ResponsiveContainer>
    </Card>
  );
}
