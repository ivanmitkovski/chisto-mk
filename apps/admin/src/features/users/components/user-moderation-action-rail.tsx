'use client';

import type { KeyboardEvent as ReactKeyboardEvent, MutableRefObject } from 'react';
import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button, ConfirmDialog, Icon } from '@/components/ui';
import { useReadOnlyUnless } from '@/lib/auth/rbac';
import { useOptimisticMutation } from '@/features/admin-shell/hooks/use-optimistic-mutation';
import { adminBrowserFetch } from '@/lib/api';
import { UserSuspendReasonModal } from './user-suspend-reason-modal';
import styles from './user-moderation-action-rail.module.css';

type UserModerationActionRailProps = {
  userId: string;
  status: string;
  profileDirty: boolean;
  canViewSessions: boolean;
  actionButtonsRef: MutableRefObject<Array<HTMLButtonElement | null>>;
  onActionRailKeyDown: (event: ReactKeyboardEvent<HTMLDivElement>) => void;
  onStatusChanged?: (status: string) => void;
};

export function UserModerationActionRail({
  userId,
  status,
  profileDirty,
  canViewSessions,
  actionButtonsRef,
  onActionRailKeyDown,
  onStatusChanged,
}: UserModerationActionRailProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const readOnly = useReadOnlyUnless('users:write');
  const [pendingAction, setPendingAction] = useState<'activate' | 'revokeAll' | null>(null);
  const [suspendReasonOpen, setSuspendReasonOpen] = useState(false);

  const isActive = status === 'ACTIVE';
  const isSuspended = status === 'SUSPENDED';
  const isDeleted = status === 'DELETED';
  const actionsBlocked = readOnly || profileDirty || isDeleted;

  const statusMutation = useOptimisticMutation({
    mutate: async (payload: {
      nextStatus: 'ACTIVE' | 'SUSPENDED';
      reasonCode?: string;
      note?: string | undefined;
    }) => {
      await adminBrowserFetch(`/admin/users/${userId}`, {
        method: 'PATCH',
        body: {
          status: payload.nextStatus,
          ...(payload.reasonCode ? { reasonCode: payload.reasonCode } : {}),
          ...(payload.note ? { note: payload.note } : {}),
        },
      });
      return payload.nextStatus;
    },
    onSuccess: (nextStatus) => {
      setPendingAction(null);
      setSuspendReasonOpen(false);
      onStatusChanged?.(nextStatus);
      router.refresh();
    },
    errorToast: { title: tCommon('error'), message: tCommon('updateFailed') },
  });

  const revokeAllMutation = useOptimisticMutation({
    mutate: async () => {
      await adminBrowserFetch(`/admin/users/${userId}/sessions/revoke-all`, {
        method: 'POST',
      });
      return null;
    },
    successToast: {
      title: t('detail.moderation.revokeAllSuccessTitle'),
      message: t('detail.moderation.revokeAllSuccessMessage'),
    },
    errorToast: {
      title: t('detail.moderation.revokeAllFailedTitle'),
      message: t('detail.moderation.revokeAllFailedMessage'),
    },
    onSuccess: () => {
      setPendingAction(null);
      router.refresh();
    },
  });

  return (
    <aside className={styles.rail} aria-label={t('detail.moderation.railAria')}>
      <h2 className={styles.title}>{t('detail.moderation.title')}</h2>
      {profileDirty ? (
        <p className={styles.blocked} role="status">
          {t('detail.moderation.profileDirtyBlocked')}
        </p>
      ) : null}
      {readOnly ? (
        <p className={styles.hint} role="note">
          {t('detail.moderation.readOnlyHint')}
        </p>
      ) : (
        <p className={styles.hint}>{t('detail.moderation.shortcutHint')}</p>
      )}
      <div
        className={styles.actions}
        role="toolbar"
        aria-label={t('detail.moderation.toolbarAria')}
        onKeyDown={onActionRailKeyDown}
      >
        <Button
          variant="outline"
          disabled={actionsBlocked || !isActive}
          isLoading={statusMutation.isPending}
          onClick={() => setSuspendReasonOpen(true)}
          ref={(el) => {
            actionButtonsRef.current[0] = el;
          }}
        >
          <Icon name="shield" size={14} aria-hidden />
          {t('detail.moderation.suspend')}
        </Button>
        <Button
          variant="outline"
          disabled={actionsBlocked || !isSuspended}
          isLoading={statusMutation.isPending}
          onClick={() => setPendingAction('activate')}
          ref={(el) => {
            actionButtonsRef.current[1] = el;
          }}
        >
          <Icon name="check" size={14} aria-hidden />
          {t('detail.moderation.activate')}
        </Button>
        {canViewSessions ? (
          <Button
            variant="outline"
            disabled={actionsBlocked}
            isLoading={revokeAllMutation.isPending}
            onClick={() => setPendingAction('revokeAll')}
            ref={(el) => {
              actionButtonsRef.current[2] = el;
            }}
          >
            <Icon name="log-out" size={14} aria-hidden />
            {t('detail.moderation.revokeAllSessions')}
          </Button>
        ) : null}
      </div>
      <Link
        href={`/dashboard/moderation/ugc?subjectType=user&search=${encodeURIComponent(userId)}`}
        className={styles.ugcLink}
      >
        {t('detail.moderation.viewUgcQueue')}
        <Icon name="external-link" size={12} aria-hidden />
      </Link>

      <UserSuspendReasonModal
        open={suspendReasonOpen}
        busy={statusMutation.isPending}
        onClose={() => setSuspendReasonOpen(false)}
        onConfirm={(payload) =>
          void statusMutation.run({
            nextStatus: 'SUSPENDED',
            reasonCode: payload.reasonCode,
            note: payload.note,
          })
        }
      />
      <ConfirmDialog
        open={pendingAction === 'activate'}
        title={t('detail.moderation.activateTitle')}
        description={t('detail.moderation.activateDescription')}
        confirmLabel={t('detail.moderation.activate')}
        isLoading={statusMutation.isPending}
        onConfirm={() => void statusMutation.run({ nextStatus: 'ACTIVE' })}
        onClose={() => setPendingAction(null)}
      />
      <ConfirmDialog
        open={pendingAction === 'revokeAll'}
        title={t('detail.moderation.revokeAllTitle')}
        description={t('detail.moderation.revokeAllDescription')}
        confirmLabel={t('detail.moderation.revokeAllSessions')}
        tone="danger"
        isLoading={revokeAllMutation.isPending}
        onConfirm={() => void revokeAllMutation.run(null)}
        onClose={() => setPendingAction(null)}
      />
    </aside>
  );
}
