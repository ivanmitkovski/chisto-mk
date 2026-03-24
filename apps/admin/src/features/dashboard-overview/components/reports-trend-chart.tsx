'use client';

import { useState } from 'react';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import { Icon } from '@/components/ui';
import type { ReportsTrendItem } from '../types';
import { ReportsTrendChartSkeleton } from './reports-trend-chart-skeleton';
import styles from './reports-trend-chart.module.css';

type TrendRange = 7 | 14 | 30;

function filterByRange(data: ReportsTrendItem[], range: TrendRange): ReportsTrendItem[] {
  if (range === 30 || data.length === 0) return data;
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - range);
  const cutoffStr = cutoff.toISOString().slice(0, 10);
  return data.filter((d) => d.date >= cutoffStr);
}

const ReportsTrendChartInner = dynamic(
  () =>
    import('./reports-trend-chart-inner').then((mod) => ({
      default: mod.ReportsTrendChartInner,
    })),
  {
    ssr: false,
    loading: () => <ReportsTrendChartSkeleton height={120} />,
  }
);

function formatDateLabel(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

type ReportsTrendChartProps = {
  data: ReportsTrendItem[];
};

const RANGE_OPTIONS: { value: TrendRange; label: string }[] = [
  { value: 7, label: '7d' },
  { value: 14, label: '14d' },
  { value: 30, label: '30d' },
];

export function ReportsTrendChart({ data }: ReportsTrendChartProps) {
  const [range, setRange] = useState<TrendRange>(30);
  const filteredData = filterByRange(data, range);
  const chartData = filteredData.map((item) => ({
    ...item,
    dateLabel: formatDateLabel(item.date),
  }));

  const showChart = chartData.length >= 2;
  const chartHeight = chartData.length < 7 ? 120 : 140;

  return (
    <div className={styles.card} role="region" aria-label={`Reports trend over the last ${range} days`}>
      <span className={styles.sectionLabel}>Analytics</span>
      <div className={styles.header}>
        <h3 className={styles.title}>Reports trend</h3>
        <div className={styles.headerRight}>
          <div className={styles.rangeTabs} role="tablist" aria-label="Time range">
            {RANGE_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                type="button"
                role="tab"
                aria-selected={range === opt.value}
                className={range === opt.value ? styles.rangeTabActive : styles.rangeTab}
                onClick={() => setRange(opt.value)}
              >
                {opt.label}
              </button>
            ))}
          </div>
          <Link href="/dashboard/reports" className={styles.viewLink}>
            View reports
            <Icon name="chevron-right" size={12} className={styles.viewChevron} />
          </Link>
        </div>
      </div>
      {!showChart ? (
        <p className={styles.emptyHint}>
          {data.length === 0
            ? `No reports submitted in the last ${range} days.`
            : 'Submit more reports to see the trend.'}
        </p>
      ) : (
        <div className={styles.chartWrap} aria-hidden="true">
          <ReportsTrendChartInner data={chartData} height={chartHeight} />
          <table className={styles.srOnly}>
            <caption>Reports trend over the last {range} days</caption>
            <thead>
              <tr>
                <th scope="col">Date</th>
                <th scope="col">Reports</th>
              </tr>
            </thead>
            <tbody>
              {chartData.map((row) => (
                <tr key={row.date}>
                  <td>{row.dateLabel}</td>
                  <td>{row.count}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
