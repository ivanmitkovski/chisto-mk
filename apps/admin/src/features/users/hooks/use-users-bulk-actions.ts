'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { useOptimisticMutation } from '@/features/admin-shell/hooks/use-optimistic-mutation';
import { adminBrowserFetch } from '@/lib/api';

type BulkAction = 'suspend' | 'activate' | 'changeRole';

type BulkMutationPayload = {
  action: BulkAction;
  userIds: string[];
  role?: string;
  reasonCode?: string;
  note?: string;
};

const ROLE_LABEL_KEY_BY_VALUE: Record<string, string> = {
  USER: 'filters.roleUser',
  SUPPORT: 'filters.roleSupport',
  ADMIN: 'filters.roleAdmin',
  SUPER_ADMIN: 'filters.roleSuperAdmin',
};

export function useUsersBulkActions(refresh: () => void) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const { showToast } = useToast();
  const [bulkModal, setBulkModal] = useState<BulkAction | null>(null);
  const [roleModalOpen, setRoleModalOpen] = useState(false);

  const bulkMutation = useOptimisticMutation({
    mutate: async (payload: BulkMutationPayload) => {
      const body =
        payload.action === 'changeRole'
          ? { userIds: payload.userIds, action: payload.action, role: payload.role }
          : {
              userIds: payload.userIds,
              action: payload.action,
              ...(payload.reasonCode ? { reasonCode: payload.reasonCode } : {}),
              ...(payload.note ? { note: payload.note } : {}),
            };
      return adminBrowserFetch<{ updatedCount: number; skippedCount: number }>('/admin/users/bulk', {
        method: 'POST',
        body,
      });
    },
    onSuccess: (res, variables) => {
      const message =
        variables.action === 'suspend'
          ? t('bulk.suspendedMessage', { count: res.updatedCount })
          : variables.action === 'activate'
            ? t('bulk.activatedMessage', { count: res.updatedCount })
            : t('bulk.roleUpdatedMessage', {
                count: res.updatedCount,
                role: variables.role
                  ? t(ROLE_LABEL_KEY_BY_VALUE[variables.role] ?? variables.role)
                  : tCommon('unknown'),
              });
      const skippedSuffix =
        res.skippedCount > 0 ? t('bulk.skippedSuffix', { count: res.skippedCount }) : '';
      setBulkModal(null);
      setRoleModalOpen(false);
      refresh();
      showToast({
        tone: 'success',
        title: t('bulk.completeTitle'),
        message: `${message}${skippedSuffix}`,
      });
    },
    errorToast: { title: t('bulk.failedTitle'), message: tCommon('requestFailed') },
  });

  async function runBulkAction(
    action: BulkAction,
    selectedIds: Set<string>,
    options?: { role?: string; reasonCode?: string; note?: string },
  ) {
    if (selectedIds.size === 0) return false;
    const result = await bulkMutation.run({
      action,
      userIds: Array.from(selectedIds),
      ...(options?.role ? { role: options.role } : {}),
      ...(options?.reasonCode ? { reasonCode: options.reasonCode } : {}),
      ...(options?.note ? { note: options.note } : {}),
    });
    return result != null;
  }

  return {
    isBulkLoading: bulkMutation.isPending,
    bulkModal,
    setBulkModal,
    roleModalOpen,
    setRoleModalOpen,
    runBulkAction,
  };
}
