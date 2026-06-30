'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import styles from './sites-bulk-status-modal.module.css';

type SitesBulkArchiveModalProps = {
  open: boolean;
  selectedCount: number;
  busy: boolean;
  onClose: () => void;
  onConfirm: (archived: boolean, reason?: string) => void;
};

export function SitesBulkArchiveModal({
  open,
  selectedCount,
  busy,
  onClose,
  onConfirm,
}: SitesBulkArchiveModalProps) {
  const t = useTranslations('sites');
  const tCommon = useTranslations('common');
  const [archived, setArchived] = useState(true);
  const [reason, setReason] = useState('');
  const [reasonError, setReasonError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) {
      setArchived(true);
      setReason('');
      setReasonError(null);
    }
  }, [open]);

  function handleConfirm() {
    if (archived && !reason.trim()) {
      setReasonError(t('bulk.archiveReasonRequired'));
      return;
    }
    setReasonError(null);
    onConfirm(archived, archived ? reason.trim() : undefined);
  }

  return (
    <Modal
      open={open}
      title={t('bulk.archiveTitle')}
      description={t('bulk.archiveDescription', { count: selectedCount })}
      onClose={() => !busy && onClose()}
      footer={
        <div className={styles.footer}>
          <Button type="button" variant="outline" onClick={onClose} disabled={busy}>
            {tCommon('cancel')}
          </Button>
          <Button type="button" onClick={handleConfirm} disabled={busy}>
            {busy ? t('bulk.updating') : archived ? t('bulk.archiveSites') : t('bulk.unarchiveSites')}
          </Button>
        </div>
      }
    >
      <label className={styles.field} htmlFor="bulk-site-archive">
        <span className={styles.label}>{t('bulk.visibility')}</span>
        <select
          id="bulk-site-archive"
          className={styles.select}
          value={archived ? 'archived' : 'visible'}
          onChange={(e) => {
            setArchived(e.target.value === 'archived');
            if (e.target.value !== 'archived') {
              setReasonError(null);
            }
          }}
          disabled={busy}
        >
          <option value="archived">{t('bulk.archiveOption')}</option>
          <option value="visible">{t('bulk.unarchiveOption')}</option>
        </select>
      </label>
      {archived ? (
        <>
          <label className={styles.field} htmlFor="bulk-site-archive-reason">
            <span className={styles.label}>{t('bulk.archiveReasonLabel')}</span>
            <textarea
              id="bulk-site-archive-reason"
              className={styles.textarea}
              value={reason}
              onChange={(e) => {
                setReason(e.target.value);
                if (reasonError && e.target.value.trim()) {
                  setReasonError(null);
                }
              }}
              rows={3}
              disabled={busy}
              aria-invalid={reasonError != null}
            />
          </label>
          {reasonError ? (
            <p className={styles.fieldError} role="alert">
              {reasonError}
            </p>
          ) : null}
          <p className={styles.warning}>{t('bulk.archiveWarning')}</p>
        </>
      ) : null}
    </Modal>
  );
}
