'use client';

import { Button, Icon } from '@/components/ui';
import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import styles from './users-workspace.module.css';

type UsersBulkBarProps = {
  selectedCount: number;
  isBulkLoading: boolean;
  canBulkWrite: boolean;
  canBulkRole: boolean;
  canBroadcast: boolean;
  onActivate: () => void;
  onSuspend: () => void;
  onChangeRole: () => void;
  onSendBroadcast: () => void;
  onClear: () => void;
};

export function UsersBulkBar({
  selectedCount,
  isBulkLoading,
  canBulkWrite,
  canBulkRole,
  canBroadcast,
  onActivate,
  onSuspend,
  onChangeRole,
  onSendBroadcast,
  onClear,
}: UsersBulkBarProps) {
  const t = useTranslations('users');

  return (
    <motion.div
      className={styles.bulkBar}
      initial={{ opacity: 0, height: 0 }}
      animate={{ opacity: 1, height: 'auto' }}
      exit={{ opacity: 0, height: 0 }}
    >
      <span className={styles.bulkLabel}>{t('bulk.selected', { count: selectedCount })}</span>
      <div className={styles.bulkActions}>
        {canBulkWrite ? (
          <>
            <Button variant="outline" size="sm" onClick={onActivate} disabled={isBulkLoading}>
              <Icon name="check" size={12} aria-hidden />
              {t('bulk.activate')}
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={onSuspend}
              disabled={isBulkLoading}
              className={styles.bulkDanger}
            >
              <Icon name="shield" size={12} aria-hidden />
              {t('bulk.suspend')}
            </Button>
          </>
        ) : null}
        {canBulkRole ? (
          <Button variant="outline" size="sm" onClick={onChangeRole} disabled={isBulkLoading}>
            <Icon name="users" size={12} aria-hidden />
            {t('bulk.changeRole')}
          </Button>
        ) : null}
        {canBroadcast ? (
          <Button variant="outline" size="sm" onClick={onSendBroadcast} disabled={isBulkLoading}>
            <Icon name="document-forward" size={12} aria-hidden />
            {t('bulk.sendBroadcast')}
          </Button>
        ) : null}
        <button type="button" className={styles.bulkClear} onClick={onClear}>
          {t('bulk.clearSelection')}
        </button>
      </div>
    </motion.div>
  );
}
