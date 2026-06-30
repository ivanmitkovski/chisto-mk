'use client';

import { useCallback, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { ApiError } from '@/lib/api';
import {
  changeStaffRole,
  createTeamInvite,
  resendTeamInvite,
  revokeTeamInvite,
  setStaffStatus,
} from '../data/team-adapter-client';
import type { InviteStaffFormValues, StaffRole, TeamInvite, TeamStaffMember } from '../types';

type UseTeamMutationsOptions = {
  onInvitesChange?: (updater: (prev: TeamInvite[]) => TeamInvite[]) => void;
  onStaffChange?: (updater: (prev: TeamStaffMember[]) => TeamStaffMember[]) => void;
};

export function useTeamMutations({ onInvitesChange, onStaffChange }: UseTeamMutationsOptions = {}) {
  const t = useTranslations('team');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const { showToast, clearToast } = useToast();
  const [busy, setBusy] = useState(false);

  const run = useCallback(
    async (action: () => Promise<void>, success: { title: string; message: string }) => {
      setBusy(true);
      clearToast();
      try {
        await action();
        showToast({ tone: 'success', title: success.title, message: success.message });
        router.refresh();
        return true;
      } catch (err) {
        showToast({
          tone: 'error',
          title: tCommon('error'),
          message: err instanceof ApiError ? err.message : tCommon('requestFailed'),
        });
        return false;
      } finally {
        setBusy(false);
      }
    },
    [clearToast, router, showToast, tCommon],
  );

  const inviteStaff = useCallback(
    async (values: InviteStaffFormValues) => {
      setBusy(true);
      clearToast();
      try {
        const invite = await createTeamInvite(values);
        onInvitesChange?.((prev) => {
          const existing = prev.find((row) => row.id === invite.id);
          if (existing) {
            return prev.map((row) => (row.id === invite.id ? invite : row));
          }
          return [invite, ...prev];
        });
        showToast({
          tone: 'success',
          title: t('toast.inviteSentTitle'),
          message: t('toast.inviteSentMessage', { email: invite.email }),
        });
        router.refresh();
        return true;
      } catch (err) {
        showToast({
          tone: 'error',
          title: t('toast.inviteFailedTitle'),
          message: err instanceof ApiError ? err.message : t('toast.inviteFailedMessage'),
        });
        return false;
      } finally {
        setBusy(false);
      }
    },
    [clearToast, onInvitesChange, router, showToast, t],
  );

  const resendInvite = useCallback(
    (id: string) =>
      run(
        async () => {
          const invite = await resendTeamInvite(id);
          onInvitesChange?.((prev) => prev.map((row) => (row.id === id ? invite : row)));
        },
        { title: t('toast.inviteResentTitle'), message: t('toast.inviteResentMessage') },
      ),
    [onInvitesChange, run, t],
  );

  const revokeInvite = useCallback(
    (id: string) =>
      run(
        async () => {
          await revokeTeamInvite(id);
          onInvitesChange?.((prev) =>
            prev.map((row) =>
              row.id === id ? { ...row, status: 'REVOKED', revokedAt: new Date().toISOString() } : row,
            ),
          );
        },
        { title: t('toast.inviteRevokedTitle'), message: t('toast.inviteRevokedMessage') },
      ),
    [onInvitesChange, run, t],
  );

  const updateStaffRole = useCallback(
    (userId: string, role: StaffRole) =>
      run(
        async () => {
          await changeStaffRole(userId, role);
        },
        { title: t('toast.roleUpdatedTitle'), message: t('toast.roleUpdatedMessage') },
      ),
    [run, t],
  );

  const updateStaffStatus = useCallback(
    async (userId: string, status: 'ACTIVE' | 'SUSPENDED') => {
      setBusy(true);
      clearToast();

      let previousStatus: TeamStaffMember['status'] | null = null;
      onStaffChange?.((prev) => {
        const row = prev.find((member) => member.id === userId);
        previousStatus = row?.status ?? null;
        return prev.map((member) => (member.id === userId ? { ...member, status } : member));
      });

      try {
        await setStaffStatus(userId, status);
        showToast({
          tone: 'success',
          title: status === 'ACTIVE' ? t('toast.activatedTitle') : t('toast.suspendedTitle'),
          message: t('toast.statusSavedMessage'),
        });
        router.refresh();
        return true;
      } catch (err) {
        if (previousStatus !== null) {
          onStaffChange?.((prev) =>
            prev.map((member) =>
              member.id === userId ? { ...member, status: previousStatus as TeamStaffMember['status'] } : member,
            ),
          );
        }
        showToast({
          tone: 'error',
          title: tCommon('error'),
          message: err instanceof ApiError ? err.message : tCommon('requestFailed'),
        });
        return false;
      } finally {
        setBusy(false);
      }
    },
    [clearToast, onStaffChange, router, showToast, t, tCommon],
  );

  return {
    busy,
    inviteStaff,
    resendInvite,
    revokeInvite,
    updateStaffRole,
    updateStaffStatus,
  };
}
