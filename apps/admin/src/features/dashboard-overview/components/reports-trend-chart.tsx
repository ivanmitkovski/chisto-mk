'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useLocale, useTranslations } from 'next-intl';
import dynamic from 'next/dynamic';
import { Icon } from '@/components/ui';
import { formatAdminDate } from '@/lib/i18n/format-admin-datetime';
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

function formatDateLabel(dateStr: string, locale: string): string {
  return formatAdminDate(dateStr, locale, { month: 'short', day: 'numeric' });
}

type ReportsTrendChartProps = {
  data: ReportsTrendItem[];
};

const RANGE_OPTIONS: TrendRange[] = [7, 14, 30];

export function ReportsTrendChart({ data }: ReportsTrendChartProps) {
  const t = useTranslations('dashboard.reportsTrend');
  const locale = useLocale();
  const [range, setRange] = useState<TrendRange>(30);
  const filteredData = filterByRange(data, range);
  const chartData = filteredData.map((item) => ({
    ...item,
    dateLabel: formatDateLabel(item.date, locale),
  }));

  const showChart = chartData.length >= 2;
  const chartHeight = chartData.length < 7 ? 120 : 140;

  return (
    <div className={styles.card} role="region" aria-label={t('chartAria', { range })}>
      <span className={styles.sectionLabel}>{t('sectionLabel')}</span>
      <div className={styles.header}>
        <h3 className={styles.title}>{t('title')}</h3>
        <div className={styles.headerRight}>
          <div className={styles.rangeTabs} role="tablist" aria-label={t('timeRangeAria')}>
            {RANGE_OPTIONS.map((opt) => (
              <button
                key={opt}
                type="button"
                role="tab"
                aria-selected={range === opt}
                className={range === opt ? styles.rangeTabActive : styles.rangeTab}
                onClick={() => setRange(opt)}
              >
                {`${opt}d`}
              </button>
            ))}
          </div>
          <Link href="/dashboard/reports" className={styles.viewLink}>
            {t('viewReports')}
            <Icon name="chevron-right" size={12} className={styles.viewChevron} />
          </Link>
        </div>
      </div>
      {!showChart ? (
        <p className={styles.emptyHint}>
          {data.length === 0
            ? t('emptyNoData', { range })
            : t('emptyNeedMore')}
        </p>
      ) : (
        <div className={styles.chartWrap} aria-hidden="true">
          <ReportsTrendChartInner data={chartData} height={chartHeight} />
          <table className={styles.srOnly}>
            <caption>{t('tableCaption', { range })}</caption>
            <thead>
              <tr>
                <th scope="col">{t('dateColumn')}</th>
                <th scope="col">{t('reportsColumn')}</th>
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
