'use client';

import { useId } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon, Modal } from '@/components/ui';
import styles from './context-detail-modal.module.css';

export type ContextDetailKind = 'submitted' | 'reporter' | 'co-reporters' | 'trust-tier' | 'queue';

type ContextDetailModalProps = {
  isOpen: boolean;
  kind: ContextDetailKind | null;
  value: string;
  onClose: () => void;
};

const KIND_TO_KEY: Record<ContextDetailKind, 'submitted' | 'reporter' | 'coReporters' | 'trustTier' | 'queue'> = {
  submitted: 'submitted',
  reporter: 'reporter',
  'co-reporters': 'coReporters',
  'trust-tier': 'trustTier',
  queue: 'queue',
};

const KIND_ICONS = {
  submitted: 'calendar',
  reporter: 'user',
  coReporters: 'users',
  trustTier: 'shield',
  queue: 'scroll-text',
} as const;

export function ContextDetailModal({ isOpen, kind, value, onClose }: ContextDetailModalProps) {
  const t = useTranslations('reports.contextDetail');
  const bodyId = useId();

  if (!kind) return null;

  const contentKey = KIND_TO_KEY[kind];
  const icon = KIND_ICONS[contentKey];

  return (
    <Modal
      open={isOpen}
      title={t(`${contentKey}.title`)}
      description={t(`${contentKey}.description`, { value })}
      onClose={onClose}
      footer={
        <Button type="button" onClick={onClose}>
          {t('close')}
        </Button>
      }
    >
      <div className={styles.content}>
        <span className={styles.icon} aria-hidden>
          <Icon name={icon} size={20} />
        </span>
        <div id={bodyId} className={styles.body}>
          <p>{t(`${contentKey}.body`, { value })}</p>
        </div>
      </div>
    </Modal>
  );
}
