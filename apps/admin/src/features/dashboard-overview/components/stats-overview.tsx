'use client';

import { motion } from 'framer-motion';
import { Card, Icon, SectionState } from '@/components/ui';
import { StatCard } from '../types';
import styles from './stats-overview.module.css';

type StatsOverviewProps = {
  cards: StatCard[];
};

function toneClass(tone: StatCard['tone']) {
  const toneClassByName: Record<StatCard['tone'], string> = {
    green: styles.dotGreen,
    yellow: styles.dotYellow,
    red: styles.dotRed,
    mint: styles.dotMint,
  };

  return toneClassByName[tone];
}

export function StatsOverview({ cards }: StatsOverviewProps) {
  if (cards.length === 0) {
    return <SectionState variant="empty" message="No dashboard statistics available yet." />;
  }

  return (
    <motion.section
      className={styles.grid}
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25 }}
    >
      {cards.map((card) => (
        <motion.div key={card.id} whileHover={{ y: -3 }} transition={{ duration: 0.16 }}>
          <Card as="article" padding="sm" className={styles.card}>
            <div className={styles.header}>
              <span className={`${styles.dot} ${toneClass(card.tone)}`}>
                <Icon name={card.icon} size={14} className={styles.icon} />
              </span>
              <p className={styles.label}>{card.label}</p>
            </div>
            <p className={styles.value}>{card.value}</p>
          </Card>
        </motion.div>
      ))}
    </motion.section>
  );
}
