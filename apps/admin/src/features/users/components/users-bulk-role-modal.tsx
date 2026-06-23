'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import styles from './users-bulk-role-modal.module.css';

const ROLE_OPTIONS = [
  { value: 'USER', labelKey: 'filters.roleUser' },
  { value: 'SUPPORT', labelKey: 'filters.roleSupport' },
  { value: 'ADMIN', labelKey: 'filters.roleAdmin' },
  { value: 'SUPER_ADMIN', labelKey: 'filters.roleSuperAdmin' },
] as const;

const DEFAULT_ROLE = 'SUPPORT';

type UsersBulkRoleModalProps = {
  open: boolean;
  selectedCount: number;
  busy: boolean;
  onClose: () => void;
  onConfirm: (role: string) => void;
};

export function UsersBulkRoleModal({
  open,
  selectedCount,
  busy,
  onClose,
  onConfirm,
}: UsersBulkRoleModalProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const [role, setRole] = useState(DEFAULT_ROLE);

  useEffect(() => {
    if (!open) {
      setRole(DEFAULT_ROLE);
    }
  }, [open]);

  return (
    <Modal
      open={open}
      title={t('bulk.changeRoleTitle')}
      description={t('bulk.changeRoleDescription', { count: selectedCount })}
      onClose={() => !busy && onClose()}
      footer={
        <div className={styles.footer}>
          <Button type="button" variant="outline" onClick={onClose} disabled={busy}>
            {tCommon('cancel')}
          </Button>
          <Button type="button" onClick={() => onConfirm(role)} disabled={busy}>
            {busy ? t('bulk.updating') : t('bulk.applyRole')}
          </Button>
        </div>
      }
    >
      <label className={styles.field} htmlFor="bulk-user-role">
        <span className={styles.label}>{t('bulk.targetRole')}</span>
        <select
          id="bulk-user-role"
          className={styles.select}
          value={role}
          onChange={(e) => setRole(e.target.value)}
          disabled={busy}
        >
          {ROLE_OPTIONS.map((o) => (
            <option key={o.value} value={o.value}>
              {t(o.labelKey)}
            </option>
          ))}
        </select>
      </label>
    </Modal>
  );
}
