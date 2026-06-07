'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Field, Input, Modal, Select } from '@/components/ui';
import { TEAM_ROLE_OPTIONS } from '../config/team-roles';
import { validateInviteEmail, validateInviteName } from '../lib/team-validation';
import type { InviteStaffFormValues, StaffRole } from '../types';
import styles from './invite-staff-modal.module.css';

const EMPTY: InviteStaffFormValues = {
  email: '',
  firstName: '',
  lastName: '',
  role: 'SUPPORT',
};

type InviteStaffModalProps = {
  open: boolean;
  busy?: boolean;
  onClose: () => void;
  onSubmit: (values: InviteStaffFormValues) => Promise<boolean>;
};

export function InviteStaffModal({ open, busy = false, onClose, onSubmit }: InviteStaffModalProps) {
  const t = useTranslations('team');
  const tCommon = useTranslations('common');
  const [values, setValues] = useState<InviteStaffFormValues>(EMPTY);
  const [emailError, setEmailError] = useState<string | null>(null);
  const [firstNameError, setFirstNameError] = useState<string | null>(null);
  const [lastNameError, setLastNameError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) {
      setValues(EMPTY);
      setEmailError(null);
      setFirstNameError(null);
      setLastNameError(null);
    }
  }, [open]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    const emailValidationError = validateInviteEmail(values.email, (key) => t(`validation.${key}`));
    const firstNameValidationError = validateInviteName(values.firstName, (key) => t(`validation.${key}`));
    const lastNameValidationError = validateInviteName(values.lastName, (key) => t(`validation.${key}`));
    setEmailError(emailValidationError);
    setFirstNameError(firstNameValidationError);
    setLastNameError(lastNameValidationError);
    if (emailValidationError || firstNameValidationError || lastNameValidationError) {
      return;
    }

    const ok = await onSubmit({
      ...values,
      email: values.email.trim(),
      firstName: values.firstName.trim(),
      lastName: values.lastName.trim(),
    });
    if (ok) onClose();
  }

  return (
    <Modal
      open={open}
      title={t('inviteModal.title')}
      description={t('inviteModal.description')}
      onClose={onClose}
      footer={
        <div className={styles.actions}>
          <Button type="button" variant="outline" onClick={onClose} disabled={busy}>
            {tCommon('cancel')}
          </Button>
          <Button type="submit" form="invite-staff-form" disabled={busy}>
            {busy ? t('inviteModal.sending') : t('inviteModal.sendInvite')}
          </Button>
        </div>
      }
    >
      <form id="invite-staff-form" className={styles.form} onSubmit={(e) => void handleSubmit(e)}>
        <Field
          label={t('inviteModal.email')}
          htmlFor="invite-email"
          required
          errorText={emailError ?? undefined}
        >
          <Input
            id="invite-email"
            type="email"
            autoComplete="email"
            value={values.email}
            onChange={(e) => {
              setValues((prev) => ({ ...prev, email: e.target.value }));
              if (emailError) setEmailError(null);
            }}
            required
          />
        </Field>
        <Field label={t('inviteModal.firstName')} htmlFor="invite-first-name" required errorText={firstNameError ?? undefined}>
          <Input
            id="invite-first-name"
            value={values.firstName}
            onChange={(e) => {
              setValues((prev) => ({ ...prev, firstName: e.target.value }));
              if (firstNameError) setFirstNameError(null);
            }}
            required
          />
        </Field>
        <Field label={t('inviteModal.lastName')} htmlFor="invite-last-name" required errorText={lastNameError ?? undefined}>
          <Input
            id="invite-last-name"
            value={values.lastName}
            onChange={(e) => {
              setValues((prev) => ({ ...prev, lastName: e.target.value }));
              if (lastNameError) setLastNameError(null);
            }}
            required
          />
        </Field>
        <Select
          id="invite-role"
          label={t('inviteModal.role')}
          required
          value={values.role}
          options={TEAM_ROLE_OPTIONS.map((option) => ({
            value: option.value,
            label: t(option.labelKey),
          }))}
          onChange={(e) => setValues((prev) => ({ ...prev, role: e.target.value as StaffRole }))}
        />
      </form>
    </Modal>
  );
}
