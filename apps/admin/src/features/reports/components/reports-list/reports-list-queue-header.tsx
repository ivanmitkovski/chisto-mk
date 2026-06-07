'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Button, Icon } from '@/components/ui';
import styles from '../reports-list.module.css';

type ReportsListQueueHeaderProps = {
  reportsCount: number;
  needAttentionCount: number;
  duplicateCount: number;
  isRefreshing: boolean;
  onRefresh: () => void;
  sublineText: string;
};

export function ReportsListQueueHeader({
  reportsCount,
  needAttentionCount,
  duplicateCount,
  isRefreshing,
  onRefresh,
  sublineText,
}: ReportsListQueueHeaderProps) {
  const t = useTranslations('reports.queue');
  const tCommon = useTranslations('common');

  return (
    <>
      <div className={styles.summaryStrip}>
        <span className={styles.summaryValue}>{t('reportsCount', { count: reportsCount })}</span>
        <span className={styles.summarySep}>·</span>
        <span className={styles.summaryValue}>{t('needAttention', { count: needAttentionCount })}</span>
        <span className={styles.summarySep}>·</span>
        <Link href="/dashboard/reports/duplicates" className={styles.summaryLink}>
          {t('duplicatesLink', { count: duplicateCount })}
        </Link>
      </div>
      <span className={styles.sectionLabel}>{tCommon('queue')}</span>
      <div className={styles.reportsHeader}>
        <div>
          <h2 id="reports-heading" className={styles.sectionTitle}>
            {t('title')}
          </h2>
          <p className={styles.reportsSubline} data-attention={needAttentionCount > 0 ? 'true' : undefined}>
            {sublineText}
          </p>
        </div>
        <div className={styles.reportsHeaderActions}>
          <div className={styles.statusPill} role="status">
            <Button
              variant="icon"
              aria-label={t('refreshAria')}
              onClick={onRefresh}
              disabled={isRefreshing}
              className={styles.refreshBtn}
            >
              <Icon name="refresh" size={16} {...(isRefreshing && { className: styles.spinning })} />
            </Button>
          </div>
          <Link href="/dashboard/reports/duplicates" className={styles.viewAllLink}>
            {duplicateCount > 0
              ? t('potentialDuplicates', { count: duplicateCount })
              : t('duplicates')}
            <Icon name="chevron-right" size={12} className={styles.linkChevron} aria-hidden />
          </Link>
        </div>
      </div>
    </>
  );
}
