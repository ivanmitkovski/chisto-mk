'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button, Input, Modal, Select, useToast } from '@/components/ui';
import { OtpInput } from '@/features/auth/components/otp-input';
import { useOptimisticMutation } from '@/features/admin-shell/hooks/use-optimistic-mutation';
import { adminBrowserFetch, ApiError } from '@/lib/api';
import { USER_EMAIL_CHANGE_REASONS } from '@/features/users/constants/user-email-change-reasons';
import styles from './user-change-email-modal.module.css';

type UserChangeEmailModalProps = {
  open: boolean;
  userId: string;
  currentEmail: string;
  busy?: boolean;
  onClose: () => void;
};

type Step = 'request' | 'confirm';

export function UserChangeEmailModal({
  open,
  userId,
  currentEmail,
  busy = false,
  onClose,
}: UserChangeEmailModalProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const router = useRouter();
  const { showToast } = useToast();
  const [step, setStep] = useState<Step>('request');
  const [newEmail, setNewEmail] = useState('');
  const [reasonCode, setReasonCode] = useState<string>(USER_EMAIL_CHANGE_REASONS[0].value);
  const [note, setNote] = useState('');
  const [code, setCode] = useState('');

  function resetAndClose() {
    if (busy) return;
    setStep('request');
    setNewEmail('');
    setReasonCode(USER_EMAIL_CHANGE_REASONS[0].value);
    setNote('');
    setCode('');
    onClose();
  }

  function mapError(error: unknown): string {
    if (error instanceof ApiError) {
      if (error.code === 'EMAIL_IN_USE') return t('detail.changeEmail.errors.emailInUse');
      if (error.code === 'EMAIL_UNCHANGED') return t('detail.changeEmail.errors.emailUnchanged');
      if (error.code === 'INVALID_CODE') return t('detail.changeEmail.errors.invalidCode');
      if (error.code === 'SERVICE_UNAVAILABLE') return t('detail.changeEmail.errors.serviceUnavailable');
      if (error.code === 'USER_DELETED') return t('detail.changeEmail.errors.userDeleted');
    }
    return t('detail.changeEmail.errors.generic');
  }

  const requestMutation = useOptimisticMutation({
    mutate: async () => {
      try {
        const normalized = newEmail.trim().toLowerCase();
        const result = await adminBrowserFetch<{ expiresIn: number; devCode?: string }>(
          `/admin/users/${userId}/email/change-request`,
          {
            method: 'POST',
            body: {
              newEmail: normalized,
              reasonCode,
              ...(note.trim() ? { note: note.trim() } : {}),
            },
          },
        );
        return { normalized, devCode: result.devCode };
      } catch (error) {
        throw new Error(mapError(error));
      }
    },
    onSuccess: ({ normalized, devCode }) => {
      setNewEmail(normalized);
      setStep('confirm');
      if (devCode) {
        setCode(devCode);
      }
      showToast({
        tone: 'success',
        title: t('detail.changeEmail.requestSuccessTitle'),
        message: t('detail.changeEmail.requestSuccessMessage', { email: normalized }),
      });
    },
    errorToast: { title: tCommon('error'), message: '' },
  });

  const confirmMutation = useOptimisticMutation({
    mutate: async () => {
      try {
        await adminBrowserFetch(`/admin/users/${userId}/email/confirm`, {
          method: 'POST',
          body: {
            newEmail: newEmail.trim().toLowerCase(),
            code: code.trim(),
          },
        });
        return null;
      } catch (error) {
        throw new Error(mapError(error));
      }
    },
    successToast: {
      title: t('detail.changeEmail.confirmSuccessTitle'),
      message: t('detail.changeEmail.confirmSuccessMessage'),
    },
    errorToast: { title: tCommon('error'), message: '' },
    onSuccess: () => {
      resetAndClose();
      router.refresh();
    },
  });

  const isBusy = busy || requestMutation.isPending || confirmMutation.isPending;

  return (
    <Modal
      open={open}
      title={t('detail.changeEmail.title')}
      description={
        step === 'request'
          ? t('detail.changeEmail.requestDescription', { currentEmail })
          : t('detail.changeEmail.confirmDescription', { email: newEmail.trim().toLowerCase() })
      }
      onClose={resetAndClose}
      footer={
        <div className={styles.footer}>
          {step === 'confirm' ? (
            <Button type="button" variant="outline" onClick={() => setStep('request')} disabled={isBusy}>
              {t('detail.changeEmail.back')}
            </Button>
          ) : (
            <Button type="button" variant="outline" onClick={resetAndClose} disabled={isBusy}>
              {tCommon('cancel')}
            </Button>
          )}
          {step === 'request' ? (
            <Button
              type="button"
              disabled={isBusy || !newEmail.trim() || !reasonCode}
              isLoading={requestMutation.isPending}
              onClick={() => void requestMutation.run(null)}
            >
              {t('detail.changeEmail.sendCode')}
            </Button>
          ) : (
            <Button
              type="button"
              disabled={isBusy || code.trim().length !== 6}
              isLoading={confirmMutation.isPending}
              onClick={() => void confirmMutation.run(null)}
            >
              {t('detail.changeEmail.confirm')}
            </Button>
          )}
        </div>
      }
    >
      {step === 'request' ? (
        <div className={styles.form}>
          <Input
            label={t('detail.changeEmail.newEmailLabel')}
            type="email"
            value={newEmail}
            onChange={(e) => setNewEmail(e.target.value)}
            disabled={isBusy}
            autoComplete="off"
          />
          <Select
            label={t('detail.changeEmail.reasonLabel')}
            value={reasonCode}
            onChange={(e) => setReasonCode(e.target.value)}
            disabled={isBusy}
            options={USER_EMAIL_CHANGE_REASONS.map((reason) => ({
              value: reason.value,
              label: t(reason.labelKey),
            }))}
          />
          <Input
            label={t('detail.changeEmail.noteLabel')}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            disabled={isBusy}
          />
        </div>
      ) : (
        <div className={styles.form}>
          <OtpInput
            id="admin-email-change-otp"
            label={t('detail.changeEmail.codeLabel')}
            value={code}
            onChange={setCode}
            disabled={isBusy}
          />
        </div>
      )}
    </Modal>
  );
}
