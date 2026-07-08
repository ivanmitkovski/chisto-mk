'use client';

import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import styles from './news-conflict-dialog.module.css';

type NewsConflictDialogProps = {
  open: boolean;
  isLoading?: boolean;
  onReload: () => void;
  onOverwrite: () => void;
  onClose: () => void;
};

export function NewsConflictDialog({
  open,
  isLoading = false,
  onReload,
  onOverwrite,
  onClose,
}: NewsConflictDialogProps) {
  const t = useTranslations('news');

  return (
    <Modal
      open={open}
      title={t('conflict.title')}
      description={t('conflict.description')}
      onClose={isLoading ? () => undefined : onClose}
      footer={
        <div className={styles.footer}>
          <Button variant="outline" onClick={onClose} disabled={isLoading}>
            {t('conflict.cancel')}
          </Button>
          <Button variant="outline" onClick={onReload} disabled={isLoading} isLoading={isLoading}>
            {t('conflict.reload')}
          </Button>
          <Button onClick={onOverwrite} disabled={isLoading} isLoading={isLoading}>
            {t('conflict.overwrite')}
          </Button>
        </div>
      }
    >
      <p className={styles.body}>{t('conflict.body')}</p>
    </Modal>
  );
}
