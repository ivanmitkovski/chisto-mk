'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';

type BulkAction = 'suspend' | 'activate' | 'changeRole';

const ROLE_LABEL_KEY_BY_VALUE: Record<string, string> = {
  USER: 'filters.roleUser',
  SUPPORT: 'filters.roleSupport',
  MODERATOR: 'filters.roleModerator',
  ADMIN: 'filters.roleAdmin',
  SUPER_ADMIN: 'filters.roleSuperAdmin',
};

export function useUsersBulkActions(refresh: () => void) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const { showToast } = useToast();
  const [isBulkLoading, setIsBulkLoading] = useState(false);
  const [bulkModal, setBulkModal] = useState<BulkAction | null>(null);
  const [roleModalOpen, setRoleModalOpen] = useState(false);

  async function runBulkAction(action: BulkAction, selectedIds: Set<string>, role?: string) {
    if (selectedIds.size === 0) return;
    setIsBulkLoading(true);
    try {
      const body =
        action === 'changeRole'
          ? { userIds: Array.from(selectedIds), action, role }
          : { userIds: Array.from(selectedIds), action };
      const res = await adminBrowserFetch<{ updatedCount: number; skippedCount: number }>(
        '/admin/users/bulk',
        {
          method: 'POST',
          body,
        },
      );
      const message =
        action === 'suspend'
          ? t('bulk.suspendedMessage', { count: res.updatedCount })
          : action === 'activate'
            ? t('bulk.activatedMessage', { count: res.updatedCount })
            : t('bulk.roleUpdatedMessage', {
                count: res.updatedCount,
                role: role ? t(ROLE_LABEL_KEY_BY_VALUE[role] ?? role) : tCommon('unknown'),
              });
      const skippedSuffix =
        res.skippedCount > 0
          ? t('bulk.skippedSuffix', { count: res.skippedCount })
          : '';
      showToast({
        tone: 'success',
        title: t('bulk.completeTitle'),
        message: `${message}${skippedSuffix}`,
      });
      setBulkModal(null);
      setRoleModalOpen(false);
      refresh();
      return true;
    } catch (err) {
      const msg = err instanceof Error ? err.message : tCommon('requestFailed');
      showToast({ tone: 'error', title: t('bulk.failedTitle'), message: msg });
      return false;
    } finally {
      setIsBulkLoading(false);
    }
  }

  return {
    isBulkLoading,
    bulkModal,
    setBulkModal,
    roleModalOpen,
    setRoleModalOpen,
    runBulkAction,
  };
}
