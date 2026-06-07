'use client';

import { useEffect, useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import { SITES_STATUS_OPTIONS } from '@/features/sites/config/sites-list-filters';
import {
  isAllowedSiteStatusTransition,
  SITE_STATUS_TRANSITIONS,
} from '@/features/sites/lib/sites-status-transitions';
import type { SiteRow } from '@/features/sites/data/sites-adapter';
import styles from './sites-bulk-status-modal.module.css';

type SitesBulkStatusModalProps = {
  open: boolean;
  selectedSites: SiteRow[];
  busy: boolean;
  onClose: () => void;
  onConfirm: (status: string, validSiteIds: string[]) => void;
};

export function SitesBulkStatusModal({
  open,
  selectedSites,
  busy,
  onClose,
  onConfirm,
}: SitesBulkStatusModalProps) {
  const t = useTranslations('sites');
  const tCommon = useTranslations('common');
  const [status, setStatus] = useState('VERIFIED');

  useEffect(() => {
    if (!open) {
      setStatus('VERIFIED');
    }
  }, [open]);

  const { validCount, skippedCount } = useMemo(() => {
    let valid = 0;
    let skipped = 0;
    for (const site of selectedSites) {
      if (isAllowedSiteStatusTransition(site.status, status)) {
        valid += 1;
      } else {
        skipped += 1;
      }
    }
    return { validCount: valid, skippedCount: skipped };
  }, [selectedSites, status]);

  const allowedTargetStatuses = useMemo(() => {
    const targets = new Set<string>();
    for (const site of selectedSites) {
      for (const next of SITE_STATUS_TRANSITIONS[site.status] ?? []) {
        targets.add(next);
      }
    }
    return SITES_STATUS_OPTIONS.filter((option) => option.value !== '' && targets.has(option.value));
  }, [selectedSites]);

  const statusOptions =
    allowedTargetStatuses.length > 0
      ? allowedTargetStatuses
      : SITES_STATUS_OPTIONS.filter((option) => option.value !== '');

  useEffect(() => {
    if (!statusOptions.some((option) => option.value === status) && statusOptions[0]) {
      setStatus(statusOptions[0].value);
    }
  }, [status, statusOptions]);

  function handleConfirm() {
    const validSiteIds = selectedSites
      .filter((site) => isAllowedSiteStatusTransition(site.status, status))
      .map((site) => site.id);
    if (validSiteIds.length === 0) {
      return;
    }
    onConfirm(status, validSiteIds);
  }

  return (
    <Modal
      open={open}
      title={t('bulk.setStatusTitle')}
      description={t('bulk.setStatusDescription', { count: selectedSites.length })}
      onClose={() => !busy && onClose()}
      footer={
        <div className={styles.footer}>
          <Button type="button" variant="outline" onClick={onClose} disabled={busy}>
            {tCommon('cancel')}
          </Button>
          <Button type="button" onClick={handleConfirm} disabled={busy || validCount === 0}>
            {busy ? t('bulk.updating') : t('bulk.applyStatus')}
          </Button>
        </div>
      }
    >
      <label className={styles.field} htmlFor="bulk-site-status">
        <span className={styles.label}>{t('bulk.targetStatus')}</span>
        <select
          id="bulk-site-status"
          className={styles.select}
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          disabled={busy}
        >
          {statusOptions.map((o) => (
            <option key={o.value} value={o.value}>
              {t(o.labelKey)}
            </option>
          ))}
        </select>
      </label>
      {skippedCount > 0 ? (
        <p className={styles.warning} role="status">
          {t('bulk.transitionSkippedPreview', { valid: validCount, skipped: skippedCount })}
        </p>
      ) : (
        <p className={styles.warning}>{t('bulk.transitionWarning')}</p>
      )}
    </Modal>
  );
}
