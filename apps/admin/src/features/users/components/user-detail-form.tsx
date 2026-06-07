'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, ConfirmDialog, useToast } from '@/components/ui';
import { Can, useReadOnlyUnless } from '@/lib/auth/rbac';
import { useOptimisticMutation } from '@/features/admin-shell/hooks/use-optimistic-mutation';
import { useUnsavedChangesGuard } from '@/features/admin-shell/hooks/use-unsaved-changes-guard';
import { adminBrowserFetch } from '@/lib/api';
import styles from './user-detail-form.module.css';

const ROLE_LABEL_KEY_BY_VALUE: Record<string, string> = {
  USER: 'filters.roleUser',
  SUPPORT: 'filters.roleSupport',
  MODERATOR: 'filters.roleModerator',
  ADMIN: 'filters.roleAdmin',
  SUPER_ADMIN: 'filters.roleSuperAdmin',
};

const STATUS_LABEL_KEY_BY_VALUE: Record<string, string> = {
  ACTIVE: 'filters.active',
  SUSPENDED: 'filters.suspended',
};

function formatToken(value: string): string {
  return value
    .replace(/_/g, ' ')
    .toLowerCase()
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

type UserDetailFormProps = {
  userId: string;
  initialFirstName: string;
  initialLastName: string;
  initialRole: string;
  initialStatus: string;
  initialPhoneNumber: string;
  email: string;
  pointsBalance: number;
  reportsCount: number;
  sessionsCount: number;
  hidden?: boolean;
  onDirtyChange?: (dirty: boolean) => void;
};

export function UserDetailForm({
  userId,
  initialFirstName,
  initialLastName,
  initialRole,
  initialStatus,
  initialPhoneNumber,
  email,
  pointsBalance,
  reportsCount,
  sessionsCount,
  hidden = false,
  onDirtyChange,
}: UserDetailFormProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const readOnly = useReadOnlyUnless('users:write');
  const [firstName, setFirstName] = useState(initialFirstName);
  const [lastName, setLastName] = useState(initialLastName);
  const [phoneNumber, setPhoneNumber] = useState(initialPhoneNumber ?? '');
  const [role, setRole] = useState(initialRole);
  const [status, setStatus] = useState(initialStatus);
  const [confirmRoleOpen, setConfirmRoleOpen] = useState(false);
  const [confirmStatusOpen, setConfirmStatusOpen] = useState(false);
  const [pendingStatus, setPendingStatus] = useState<string | null>(null);
  const { showToast, clearToast } = useToast();
  const roleLabel = (roleValue: string) => {
    const labelKey = ROLE_LABEL_KEY_BY_VALUE[roleValue];
    return labelKey ? t(labelKey) : formatToken(roleValue);
  };
  const statusLabel = (statusValue: string) => {
    const labelKey = STATUS_LABEL_KEY_BY_VALUE[statusValue];
    return labelKey ? t(labelKey) : formatToken(statusValue);
  };

  const isDirty =
    firstName !== initialFirstName ||
    lastName !== initialLastName ||
    (phoneNumber ?? '') !== (initialPhoneNumber ?? '') ||
    status !== initialStatus ||
    role !== initialRole;

  useUnsavedChangesGuard(isDirty);

  useEffect(() => {
    onDirtyChange?.(isDirty);
  }, [isDirty, onDirtyChange]);

  const saveMutation = useOptimisticMutation({
    mutate: async () => {
      await adminBrowserFetch(`/admin/users/${userId}`, {
        method: 'PATCH',
        body: {
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          phoneNumber: phoneNumber.trim() || null,
          status,
        },
      });
      return null;
    },
    successToast: { title: tCommon('saved'), message: t('detail.savedMessage') },
    errorToast: { title: tCommon('error'), message: tCommon('updateFailed') },
    onSuccess: () => {
      router.refresh();
      if (role !== initialRole) {
        setConfirmRoleOpen(true);
      }
    },
  });

  const roleMutation = useOptimisticMutation({
    mutate: async () => {
      await adminBrowserFetch(`/admin/users/${userId}/role`, {
        method: 'PATCH',
        body: { role },
      });
      return null;
    },
    successToast: { title: tCommon('saved'), message: t('detail.roleUpdatedMessage') },
    errorToast: { title: tCommon('error'), message: t('detail.roleUpdateFailed') },
    onSuccess: () => {
      setConfirmRoleOpen(false);
      router.refresh();
    },
  });

  function validate(): string | null {
    if (!firstName.trim()) return t('detail.validation.firstNameRequired');
    if (!lastName.trim()) return t('detail.validation.lastNameRequired');
    if (phoneNumber.trim() && phoneNumber.trim().length < 8) return t('detail.validation.phoneMinLength');
    return null;
  }

  async function saveProfile() {
    const err = validate();
    if (err) {
      showToast({ tone: 'warning', title: tCommon('validation'), message: err });
      return;
    }
    clearToast();
    await saveMutation.run(null);
  }

  function handleStatusChange(nextStatus: string) {
    if (nextStatus === status) return;
    if (nextStatus === 'SUSPENDED' || nextStatus === 'DELETED') {
      setPendingStatus(nextStatus);
      setConfirmStatusOpen(true);
      return;
    }
    setStatus(nextStatus);
  }

  function confirmStatusChange() {
    if (pendingStatus) setStatus(pendingStatus);
    setPendingStatus(null);
    setConfirmStatusOpen(false);
  }

  const saving = saveMutation.isPending || roleMutation.isPending;

  return (
    <Card className={hidden ? styles.hidden : styles.card} padding="md" aria-hidden={hidden}>
      <div className={styles.grid}>
        <div className={styles.summaryItemEmail}>
          <p className={styles.label}>{t('detail.email')}</p>
          <p className={styles.value}>{email}</p>
        </div>
        <div>
          <p className={styles.label}>{t('detail.pointsSummary')}</p>
          <p className={styles.value}>{pointsBalance}</p>
        </div>
        <div>
          <p className={styles.label}>{t('detail.reports')}</p>
          <p className={styles.value}>{reportsCount}</p>
        </div>
        <div>
          <p className={styles.label}>{t('detail.sessionsSummary')}</p>
          <p className={styles.value}>{sessionsCount}</p>
        </div>
      </div>
      <div className={styles.formRow}>
        <label className={styles.field} htmlFor="user-firstName">
          <span className={styles.label}>{t('detail.firstName')}</span>
          <input
            id="user-firstName"
            type="text"
            className={styles.input}
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            maxLength={100}
            readOnly={readOnly}
            disabled={readOnly}
          />
        </label>
        <label className={styles.field} htmlFor="user-lastName">
          <span className={styles.label}>{t('detail.lastName')}</span>
          <input
            id="user-lastName"
            type="text"
            className={styles.input}
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            maxLength={100}
            readOnly={readOnly}
            disabled={readOnly}
          />
        </label>
        <label className={styles.field} htmlFor="user-phone">
          <span className={styles.label}>{t('detail.phone')}</span>
          <input
            id="user-phone"
            type="tel"
            className={styles.input}
            value={phoneNumber}
            onChange={(e) => setPhoneNumber(e.target.value)}
            maxLength={20}
            readOnly={readOnly}
            disabled={readOnly}
          />
        </label>
        <Can permission="users:role:write" fallback={
          <div className={styles.readonlyField}>
            <p className={styles.label}>{t('detail.role')}</p>
            <p className={styles.value}>{roleLabel(initialRole)}</p>
          </div>
        }>
          <label className={styles.field} htmlFor="user-role">
            <span className={styles.label}>{t('detail.role')}</span>
            <select
              id="user-role"
              className={styles.select}
              value={role}
              onChange={(e) => setRole(e.target.value)}
              disabled={readOnly}
            >
              <option value="USER">{t('filters.roleUser')}</option>
              <option value="SUPPORT">{t('filters.roleSupport')}</option>
              <option value="MODERATOR">{t('filters.roleModerator')}</option>
              <option value="ADMIN">{t('filters.roleAdmin')}</option>
              <option value="SUPER_ADMIN">{t('filters.roleSuperAdmin')}</option>
            </select>
          </label>
        </Can>
        {readOnly ? (
          <div className={styles.readonlyField}>
            <p className={styles.label}>{t('detail.status')}</p>
            <p className={styles.value}>{statusLabel(initialStatus)}</p>
          </div>
        ) : (
          <label className={styles.field} htmlFor="user-status">
            <span className={styles.label}>{t('detail.status')}</span>
            <select
              id="user-status"
              className={styles.select}
              value={status}
              onChange={(e) => handleStatusChange(e.target.value)}
            >
              <option value="ACTIVE">{t('filters.active')}</option>
              <option value="SUSPENDED">{t('filters.suspended')}</option>
              <option value="DELETED">{formatToken('DELETED')}</option>
            </select>
          </label>
        )}
      </div>
      {!readOnly ? (
        <div className={styles.actions}>
          <Button type="button" onClick={() => void saveProfile()} disabled={saving} className={styles.saveButton}>
            {saving ? tCommon('saving') : tCommon('saveChanges')}
          </Button>
        </div>
      ) : null}
      <ConfirmDialog
        open={confirmRoleOpen}
        title={t('detail.confirmRoleTitle')}
        description={t('detail.confirmRoleDescription')}
        confirmLabel={t('detail.updateRole')}
        isLoading={roleMutation.isPending}
        onConfirm={() => void roleMutation.run(null)}
        onClose={() => setConfirmRoleOpen(false)}
      />
      <ConfirmDialog
        open={confirmStatusOpen}
        title={pendingStatus === 'DELETED' ? t('detail.markDeletedTitle') : t('detail.suspendUserTitle')}
        description={
          pendingStatus === 'DELETED'
            ? t('detail.deleteDescription')
            : t('detail.suspendDescription')
        }
        confirmLabel={pendingStatus === 'DELETED' ? t('detail.markDeleted') : t('bulk.suspend')}
        tone="danger"
        onConfirm={confirmStatusChange}
        onClose={() => {
          setConfirmStatusOpen(false);
          setPendingStatus(null);
        }}
      />
    </Card>
  );
}
