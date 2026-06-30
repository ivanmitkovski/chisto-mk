'use client';

import { useTranslations } from 'next-intl';
import { motion, useReducedMotion } from 'framer-motion';
import { Icon } from '@/components/ui';
import styles from './news-workspace.module.css';

type NewsStatsCardsProps = {
  countsByStatus: Record<string, number>;
  activeStatus: string;
  onStatusSelect: (status: string) => void;
};

const STATUS_KEYS = ['draft', 'scheduled', 'published', 'archived'] as const;

function statusIconClass(key: (typeof STATUS_KEYS)[number] | 'total'): string {
  switch (key) {
    case 'draft':
      return styles.statIconDraft;
    case 'scheduled':
      return styles.statIconScheduled;
    case 'published':
      return styles.statIconPublished;
    case 'archived':
      return styles.statIconArchived;
    default:
      return styles.statIconTotal;
  }
}

function statusIconName(key: (typeof STATUS_KEYS)[number] | 'total') {
  switch (key) {
    case 'draft':
      return 'document-text' as const;
    case 'scheduled':
      return 'calendar' as const;
    case 'published':
      return 'check' as const;
    case 'archived':
      return 'document-duplicate' as const;
    default:
      return 'newspaper' as const;
  }
}

export function NewsStatsCards({ countsByStatus, activeStatus, onStatusSelect }: NewsStatsCardsProps) {
  const t = useTranslations('news');
  const reduceMotion = useReducedMotion();
  const transition = (delay = 0) =>
    reduceMotion ? { duration: 0 } : { duration: 0.2, delay };

  const total = STATUS_KEYS.reduce((sum, key) => sum + (countsByStatus[key] ?? 0), 0);

  const cards: Array<{
    key: (typeof STATUS_KEYS)[number] | 'total';
    count: number;
    label: string;
    filterValue: string;
  }> = [
    { key: 'total', count: total, label: t('stats.total'), filterValue: '' },
    ...STATUS_KEYS.map((key) => ({
      key,
      count: countsByStatus[key] ?? 0,
      label: t(`status.${key}`),
      filterValue: key,
    })),
  ];

  return (
    <div className={styles.statsBar} role="group" aria-label={t('stats.label')}>
      {cards.map((card, index) => {
        const active = activeStatus === card.filterValue;
        const iconClass = statusIconClass(card.key);
        const iconName = statusIconName(card.key);

        return (
          <motion.button
            key={card.key}
            type="button"
            className={`${styles.statCard} ${active ? styles.statCardActive : ''}`}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={transition(index * 0.05)}
            onClick={() => onStatusSelect(card.filterValue)}
            aria-pressed={active}
          >
            <span className={iconClass}>
              <Icon name={iconName} size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{card.count}</span>
            <span className={styles.statLabel}>{card.label}</span>
          </motion.button>
        );
      })}
    </div>
  );
}
