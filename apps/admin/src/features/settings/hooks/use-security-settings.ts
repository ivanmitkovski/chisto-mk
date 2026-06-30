'use client';

import { FormEvent, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { ApiError } from '@/lib/api';
import type { MeProfile } from '@/features/auth/data/me-adapter';
import type { AdminSession, SecurityActivityEvent } from '../data/security-types';

type PasswordFields = { current: string; next: string; confirm: string };

export function useSecuritySettings(
  initialMe: MeProfile,
  initialSessions: AdminSession[],
  initialActivity: SecurityActivityEvent[],
) {
  const tToast = useTranslations('settings.securityToast');
  const tValidation = useTranslations('settings.passwordValidation');
  const tCommon = useTranslations('common');
  const [sessions, setSessions] = useState<AdminSession[]>(() => initialSessions.map((s) => ({ ...s })));
  const [activity] = useState<SecurityActivityEvent[]>(() => initialActivity);
  const { showToast } = useToast();
  const [signOutModal, setSignOutModal] = useState(false);
  const [signOutBusy, setSignOutBusy] = useState(false);
  const [pwd, setPwd] = useState<PasswordFields>({ current: '', next: '', confirm: '' });
  const [pwdErr, setPwdErr] = useState<Partial<PasswordFields>>({});
  const [pwdModal, setPwdModal] = useState(false);
  const [pwdBusy, setPwdBusy] = useState(false);
  const [mfaEnabled, setMfaEnabled] = useState(initialMe.mfaEnabled ?? false);

  const otherSessions = sessions.filter((s) => !s.isCurrent).length;

  async function revokeOthers() {
    setSignOutBusy(true);
    try {
      await adminBrowserFetch('/admin/sessions/me/others', { method: 'DELETE' });
      const refreshed = await adminBrowserFetch<{ sessions: AdminSession[] }>('/admin/security/overview');
      setSessions(refreshed.sessions.map((s) => ({ ...s })));
      showToast({
        tone: 'success',
        title: tToast('signedOutTitle'),
        message: tToast('signedOutMessage'),
      });
      setSignOutModal(false);
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : tCommon('requestFailed');
      showToast({ tone: 'warning', title: tCommon('errorGeneric'), message: msg });
    } finally {
      setSignOutBusy(false);
    }
  }

  function submitPwd(e: FormEvent) {
    e.preventDefault();
    const err: Partial<PasswordFields> = {};
    if (!pwd.current.trim()) err.current = tValidation('required');
    if (pwd.next.length < 8) err.next = tValidation('minLength');
    if (pwd.next !== pwd.confirm) err.confirm = tValidation('mustMatch');
    setPwdErr(err);
    if (Object.keys(err).length) return;
    setPwdModal(true);
  }

  async function confirmPwd() {
    setPwdBusy(true);
    try {
      await adminBrowserFetch('/auth/me/password', {
        method: 'PATCH',
        body: { currentPassword: pwd.current, newPassword: pwd.next },
      });
      setPwdModal(false);
      setPwd({ current: '', next: '', confirm: '' });
      setPwdErr({});
      showToast({
        tone: 'success',
        title: tToast('passwordUpdatedTitle'),
        message: tToast('passwordUpdatedMessage'),
      });
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : tCommon('updateFailed');
      showToast({ tone: 'warning', title: tCommon('errorGeneric'), message: msg });
    } finally {
      setPwdBusy(false);
    }
  }

  return {
    sessions,
    activity,
    signOutModal,
    setSignOutModal,
    signOutBusy,
    pwd,
    setPwd,
    pwdErr,
    pwdModal,
    setPwdModal,
    pwdBusy,
    mfaEnabled,
    setMfaEnabled,
    otherSessions,
    revokeOthers,
    submitPwd,
    confirmPwd,
  };
}
