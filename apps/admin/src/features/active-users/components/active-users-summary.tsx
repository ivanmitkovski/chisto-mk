'use client';

import dynamic from 'next/dynamic';
import { useTranslations } from 'next-intl';
import { motion, useReducedMotion } from 'framer-motion';
import { Card, Icon, SectionState, Button, PanelSkeleton } from '@/components/ui';
import { useDashboardSSE } from '@/features/dashboard-overview/context/dashboard-sse-context';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import styles from './active-users-summary.module.css';

const ActiveUsersSummaryTrendInner = dynamic(
  () =>
    import('./active-users-summary-trend-inner').then((m) => ({
      default: m.ActiveUsersSummaryTrendInner,
    })),
  {
    ssr: false,
    loading: () => (
      <Card padding="sm" className={styles.trendCard}>
        <PanelSkeleton lines={2} />
      </Card>
    ),
  },
);

function TrendChart({ data, label }: { data: number[]; label: string }) {
  return <ActiveUsersSummaryTrendInner data={data} label={label} />;
}

export function ActiveUsersSummarySection() {
  const t = useTranslations('activeUsers');
  const reducedMotion = useReducedMotion();
  const sseCtx = useDashboardSSE();
  const { summary, summaryError, refresh } = useActiveUsersLive();

  if (summaryError) {
    return (
      <SectionState variant="error" message={t('errors.summaryFailed')}>
        <Button type="button" variant="outline" size="sm" onClick={() => refresh()}>
          {t('retry')}
        </Button>
      </SectionState>
    );
  }

  if (!summary) {
    return <SectionState variant="loading" message={t('loadingSummary')} />;
  }

  const cards = [
    { key: 'currentActive', label: t('currentActive'), value: summary.currentActive, icon: 'users' as const, live: true },
    { key: 'online', label: t('online'), value: summary.online, icon: 'check-circle' as const },
    { key: 'away', label: t('away'), value: summary.away, icon: 'info' as const },
    { key: 'peakToday', label: t('peakToday'), value: summary.peakToday, icon: 'calendar' as const },
    { key: 'peakWeek', label: t('peakWeek'), value: summary.peakWeek, icon: 'calendar' as const },
    { key: 'avgConcurrent', label: t('avgConcurrent'), value: summary.avgConcurrent, icon: 'refresh' as const },
    {
      key: 'offlineEstimate',
      label: t('offlineEstimate'),
      value: summary.offlineUsersEstimate > 0 ? summary.offlineUsersEstimate : '—',
      icon: 'user' as const,
      title: summary.offlineUsersEstimate <= 0 ? t('offlineEstimateUnavailable') : undefined,
    },
  ];

  const sseConnected = Boolean(sseCtx?.connected);

  return (
    <div className={styles.grid}>
      {cards.map((card) => (
        <Card key={card.key} padding="md" className={styles.statCard} title={card.title}>
          <div className={styles.statHeader}>
            <span className={styles.iconWrap}>
              <Icon name={card.icon} size={14} aria-hidden />
            </span>
            {card.live && sseConnected ? (
              <span className={styles.liveDot} aria-label={t('liveConnected')} />
            ) : null}
          </div>
          <motion.p
            className={styles.cardValue}
            key={String(card.value)}
            initial={reducedMotion ? false : { opacity: 0.6, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            {card.value}
          </motion.p>
          <p className={styles.cardLabel}>{card.label}</p>
        </Card>
      ))}
      <TrendChart data={summary.trend5m} label={t('trend5m')} />
      <TrendChart data={summary.trend15m} label={t('trend15m')} />
      <TrendChart data={summary.trend1h} label={t('trend1h')} />
    </div>
  );
}
