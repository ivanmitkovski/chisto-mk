'use client';

import { useState } from 'react';
import Link from 'next/link';
import { motion, AnimatePresence, useReducedMotion } from 'framer-motion';
import { Icon, SectionState } from '@/components/ui';
import { StatCard, type StatCardGroup } from '../types';
import styles from './stats-overview.module.css';

const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };
const INITIAL_COUNT = 4;
const GROUP_LABELS: Record<StatCardGroup, string> = {
  reports: 'Reports',
  platform: 'Platform',
  cleanups: 'Cleanups',
};

type StatsOverviewProps = {
  stats: StatCard[];
};

function trendClass(trend: StatCard['trend']) {
  if (trend === 'up') return styles.trendUp;
  if (trend === 'down') return styles.trendDown;
  return styles.trendNeutral;
}

function StatContent({ card }: { card: StatCard }) {
  return (
    <>
      <span className={styles.iconWrap}>
        <Icon name={card.icon} size={14} className={styles.icon} aria-hidden />
      </span>
      <span className={styles.value}>{card.value}</span>
      <span className={styles.label}>{card.label}</span>
      {card.trendLabel && (
        <span className={trendClass(card.trend)}>{card.trendLabel}</span>
      )}
    </>
  );
}

function groupStats(stats: StatCard[]): Map<StatCardGroup | 'other', StatCard[]> {
  const map = new Map<StatCardGroup | 'other', StatCard[]>();
  for (const card of stats) {
    const g = card.group ?? 'other';
    const list = map.get(g) ?? [];
    list.push(card);
    map.set(g, list);
  }
  const order: (StatCardGroup | 'other')[] = ['reports', 'platform', 'cleanups', 'other'];
  const sorted = new Map<StatCardGroup | 'other', StatCard[]>();
  for (const g of order) {
    const list = map.get(g);
    if (list?.length) sorted.set(g, list);
  }
  return sorted;
}

export function StatsOverview({ stats }: StatsOverviewProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const reducedMotion = useReducedMotion();
  const groups = groupStats(stats);
  const flatStats = [...groups.values()].flat();
  const visibleStats = isExpanded ? flatStats : flatStats.slice(0, INITIAL_COUNT);
  const hasMore = flatStats.length > INITIAL_COUNT;

  if (stats.length === 0) {
    return <SectionState variant="empty" message="No dashboard statistics available yet." />;
  }

  const visibleIds = new Set(visibleStats.map((s) => s.id));
  const entries = Array.from(groups.entries());
  let idx = 0;
  return (
    <div className={styles.root} role="list">
      {entries.map(([groupKey, groupCards], entryIdx) => {
        const visibleInGroup = groupCards.filter((c) => visibleIds.has(c.id));
        if (visibleInGroup.length === 0) return null;
        const label = groupKey !== 'other' ? GROUP_LABELS[groupKey] : null;
        return (
          <div key={groupKey} className={styles.group}>
            {entryIdx > 0 ? <span className={styles.groupDivider} aria-hidden /> : null}
            {label ? <span className={styles.groupLabel}>{label}</span> : null}
            <div className={styles.groupStats}>
              {visibleInGroup.map((card) => {
                idx += 1;
                const content = <StatContent card={card} />;
                const statClassName = `${styles.stat} ${card.href ? styles.statLink : ''}`;

                return (
                  <motion.span
                    key={card.id}
                    role="listitem"
                    initial={reducedMotion ? false : { opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={
                      reducedMotion ? { duration: 0 } : { ...SPRING, delay: (idx - 1) * 0.03 }
                    }
                    {...(reducedMotion
                      ? {}
                      : { whileHover: { scale: 1.01 }, whileTap: { scale: 0.98 } })}
                  >
                    {card.href ? (
                      <Link
                        href={card.href}
                        className={statClassName}
                        aria-label={`${card.label}: ${card.value}`}
                      >
                        {content}
                      </Link>
                    ) : (
                      <span className={statClassName}>{content}</span>
                    )}
                  </motion.span>
                );
              })}
            </div>
          </div>
        );
      })}
      <AnimatePresence>
        {hasMore && (
          <motion.button
            type="button"
            className={styles.toggleButton}
            onClick={() => setIsExpanded((prev) => !prev)}
            initial={false}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={reducedMotion ? { duration: 0 } : { ...SPRING }}
          >
            {isExpanded ? (
              <>
                <Icon name="chevron-up" size={14} aria-hidden />
                Show less
              </>
            ) : (
              <>
                <Icon name="chevron-down" size={14} aria-hidden />
                Show all stats ({flatStats.length})
              </>
            )}
          </motion.button>
        )}
      </AnimatePresence>
    </div>
  );
}
