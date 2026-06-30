'use client';

import type { RefObject } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Input } from '@/components/ui';
import type { MeProfile } from '@/features/auth/data/me-adapter';
import { formatRole, getInitials } from '@/features/settings/lib/settings-display';
import panelStyles from './settings-panel.module.css';
import styles from './settings-profile-panel.module.css';

type SettingsProfilePanelProps = {
  initialMe: MeProfile;
  firstName: string;
  lastName: string;
  busy: boolean;
  hasChanges: boolean;
  panelTitleRef: RefObject<HTMLHeadingElement | null>;
  onFirstNameChange: (value: string) => void;
  onLastNameChange: (value: string) => void;
  onSubmit: (e: React.FormEvent) => void;
};

export function SettingsProfilePanel({
  initialMe,
  firstName,
  lastName,
  busy,
  hasChanges,
  panelTitleRef,
  onFirstNameChange,
  onLastNameChange,
  onSubmit,
}: SettingsProfilePanelProps) {
  const t = useTranslations('settings.profile');

  return (
    <div className={panelStyles.panel}>
      <header className={panelStyles.panelHeader}>
        <h2 ref={panelTitleRef} className={panelStyles.panelTitle} tabIndex={-1}>
          {t('title')}
        </h2>
        <p className={panelStyles.panelDescription}>{t('description')}</p>
      </header>
      <div className={styles.profileCard}>
        <div className={styles.avatarWrap}>
          <div className={styles.avatar} aria-hidden>
            {getInitials(firstName, lastName)}
          </div>
          <span className={styles.roleBadge}>{formatRole(initialMe.role)}</span>
        </div>
        <div className={styles.profileInfo}>
          <p className={styles.profileEmail}>{initialMe.email}</p>
          {initialMe.phoneNumber ? (
            <p className={styles.profilePhone}>{initialMe.phoneNumber}</p>
          ) : null}
        </div>
      </div>
      <form className={styles.form} onSubmit={onSubmit}>
        <div className={styles.formGroup}>
          <Input
            id="fn"
            label={t('firstName')}
            value={firstName}
            onChange={(e) => onFirstNameChange(e.target.value)}
            disabled={busy}
          />
          <Input
            id="ln"
            label={t('lastName')}
            value={lastName}
            onChange={(e) => onLastNameChange(e.target.value)}
            disabled={busy}
          />
        </div>
        {hasChanges ? <p className={styles.unsavedHint}>{t('unsavedChanges')}</p> : null}
        <Button type="submit" disabled={busy || !hasChanges}>
          {busy ? t('saving') : t('saveChanges')}
        </Button>
      </form>
    </div>
  );
}
