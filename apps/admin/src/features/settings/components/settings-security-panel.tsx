'use client';

import type { RefObject } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon, Input } from '@/components/ui';
import type { AdminSession, SecurityActivityEvent } from '@/features/settings/data/security-types';
import { SettingsMfaSection } from './settings-mfa-section';
import panelStyles from './settings-panel.module.css';
import styles from './settings-security-panel.module.css';

type PasswordFields = { current: string; next: string; confirm: string };

type SettingsSecurityPanelProps = {
  sessions: AdminSession[];
  activity: SecurityActivityEvent[];
  pwd: PasswordFields;
  pwdErr: Partial<PasswordFields>;
  mfaEnabled: boolean;
  otherSessions: number;
  panelTitleRef: RefObject<HTMLHeadingElement | null>;
  onPwdChange: (fields: PasswordFields) => void;
  onMfaChange: (enabled: boolean) => void;
  onSignOutOthers: () => void;
  onSubmitPwd: (e: React.FormEvent) => void;
};

export function SettingsSecurityPanel({
  sessions,
  activity,
  pwd,
  pwdErr,
  mfaEnabled,
  otherSessions,
  panelTitleRef,
  onPwdChange,
  onMfaChange,
  onSignOutOthers,
  onSubmitPwd,
}: SettingsSecurityPanelProps) {
  const t = useTranslations('settings.security');

  return (
    <div className={panelStyles.panel}>
      <header className={panelStyles.panelHeader}>
        <h2 ref={panelTitleRef} className={panelStyles.panelTitle} tabIndex={-1}>
          {t('title')}
        </h2>
        <p className={panelStyles.panelDescription}>{t('description')}</p>
      </header>

      <section className={panelStyles.section}>
        <span className={panelStyles.sectionLabel}>{t('sessionsLabel')}</span>
        <h3 className={panelStyles.sectionTitle}>{t('activeSessionsTitle')}</h3>
        <p className={panelStyles.sectionHint}>{t('activeSessionsHint')}</p>
        <div className={panelStyles.insetGroup}>
          <ul className={styles.list}>
            {sessions.map((session) => (
              <li key={session.id} className={styles.listItem}>
                <span className={styles.sessionIcon} aria-hidden>
                  <Icon name="shield" size={16} />
                </span>
                <div className={styles.sessionInfo}>
                  <span className={styles.sessionDevice}>
                    {session.device}
                    {session.isCurrent ? (
                      <span className={styles.sessionCurrent}>{t('thisDevice')}</span>
                    ) : null}
                  </span>
                  <span className={styles.sessionMeta}>
                    {session.ipAddress} · {session.lastActiveLabel}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        </div>
        <Button variant="outline" size="sm" onClick={onSignOutOthers} disabled={otherSessions === 0}>
          {t('signOutOtherSessions')}
        </Button>
      </section>

      <SettingsMfaSection mfaEnabled={mfaEnabled} onMfaChange={onMfaChange} />

      <section className={panelStyles.section}>
        <span className={panelStyles.sectionLabel}>{t('passwordLabel')}</span>
        <h3 className={panelStyles.sectionTitle}>{t('changePasswordTitle')}</h3>
        <form className={styles.passwordForm} onSubmit={onSubmitPwd}>
          <Input
            id="pc"
            label={t('currentPassword')}
            type="password"
            value={pwd.current}
            onChange={(e) => onPwdChange({ ...pwd, current: e.target.value })}
            errorText={pwdErr.current}
          />
          <Input
            id="pn"
            label={t('newPassword')}
            type="password"
            value={pwd.next}
            onChange={(e) => onPwdChange({ ...pwd, next: e.target.value })}
            errorText={pwdErr.next}
          />
          <Input
            id="pnc"
            label={t('confirmNewPassword')}
            type="password"
            value={pwd.confirm}
            onChange={(e) => onPwdChange({ ...pwd, confirm: e.target.value })}
            errorText={pwdErr.confirm}
          />
          <Button type="submit">{t('changePasswordButton')}</Button>
        </form>
      </section>

      <section className={panelStyles.section}>
        <span className={panelStyles.sectionLabel}>{t('activityLabel')}</span>
        <h3 className={panelStyles.sectionTitle}>{t('recentActivityTitle')}</h3>
        <p className={panelStyles.sectionHint}>{t('recentActivityHint')}</p>
        {activity.length === 0 ? (
          <div className={styles.activityEmpty}>
            <Icon name="document-text" size={48} aria-hidden />
            <span>{t('noActivityYet')}</span>
          </div>
        ) : (
          <div className={panelStyles.insetGroup}>
            <ol className={styles.activityList}>
              {activity.map((ev) => (
                <li
                  key={ev.id}
                  className={`${styles.activityItem} ${styles[`activityTone${ev.tone.charAt(0).toUpperCase() + ev.tone.slice(1)}`]}`}
                >
                  <span className={styles.activityIcon}>
                    <Icon name={ev.icon} size={14} />
                  </span>
                  <div className={styles.activityBody}>
                    <span className={styles.activityTitle}>{ev.title}</span>
                    <span className={styles.activityDetail}>{ev.detail}</span>
                  </div>
                  <span className={styles.activityTime}>{ev.occurredAtLabel}</span>
                </li>
              ))}
            </ol>
          </div>
        )}
      </section>
    </div>
  );
}
