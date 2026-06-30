'use client';

import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import {
  EMPTY_BODY_QUICK_INSERT,
  blockOptionByType,
  type BlockInsertType,
} from '../lib/news-block-insert-config';
import styles from './news-block-insert-menu.module.css';

type NewsBlockInsertStarterProps = {
  disabled?: boolean;
  onInsert: (block: BlockInsertType) => void;
};

export function NewsBlockInsertStarter({ disabled = false, onInsert }: NewsBlockInsertStarterProps) {
  const t = useTranslations('news');

  return (
    <div className={styles.starter} role="region" aria-label={t('insert.starterLabel')}>
      <h3 className={styles.starterTitle}>{t('insert.starterTitle')}</h3>
      <p className={styles.starterDescription}>{t('insert.starterDescription')}</p>
      <div className={styles.starterGrid}>
        {EMPTY_BODY_QUICK_INSERT.map((type) => {
          const option = blockOptionByType(type);
          return (
            <button
              key={type}
              type="button"
              className={styles.starterCard}
              disabled={disabled}
              onClick={() => onInsert(type)}
            >
              <span
                className={`${styles.starterIcon} ${
                  option.tone === 'media'
                    ? styles.iconMedia
                    : option.tone === 'advanced'
                      ? styles.iconAdvanced
                      : styles.iconText
                }`}
              >
                <Icon name={option.icon} size={18} strokeWidth={1.75} />
              </span>
              <span className={styles.starterCardLabel}>{t(option.labelKey)}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
