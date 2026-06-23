'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Input, Modal, Select } from '@/components/ui';
import { USER_SUSPENSION_REASONS } from '@/features/users/constants/user-suspension-reasons';
import styles from './user-suspend-reason-modal.module.css';

type UserSuspendReasonModalProps = {
  open: boolean;
  busy?: boolean;
  onClose: () => void;
  onConfirm: (payload: { reasonCode: string; note?: string | undefined }) => void;
};

export function UserSuspendReasonModal({
  open,
  busy = false,
  onClose,
  onConfirm,
}: UserSuspendReasonModalProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const [reasonCode, setReasonCode] = useState<string>(USER_SUSPENSION_REASONS[0].value);
  const [note, setNote] = useState('');

  return (
    <Modal
      open={open}
      title={t('detail.suspendReason.title')}
      description={t('detail.suspendReason.description')}
      onClose={() => !busy && onClose()}
      footer={
        <div className={styles.footer}>
          <Button type="button" variant="outline" onClick={onClose} disabled={busy}>
            {tCommon('cancel')}
          </Button>
          <Button
            type="button"
            variant="danger"
            disabled={busy || !reasonCode}
            onClick={() => onConfirm({ reasonCode, note: note.trim() || undefined })}
          >
            {busy ? tCommon('saving') : t('detail.moderation.suspend')}
          </Button>
        </div>
      }
    >
      <div className={styles.form}>
        <Select
          label={t('detail.suspendReason.reasonLabel')}
          value={reasonCode}
          onChange={(e) => setReasonCode(e.target.value)}
          disabled={busy}
          options={USER_SUSPENSION_REASONS.map((reason) => ({
            value: reason.value,
            label: t(reason.labelKey),
          }))}
        />
        <Input
          label={t('detail.suspendReason.noteLabel')}
          value={note}
          onChange={(e) => setNote(e.target.value)}
          disabled={busy}
        />
      </div>
    </Modal>
  );
}
