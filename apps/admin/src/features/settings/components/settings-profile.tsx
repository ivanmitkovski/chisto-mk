'use client';

import { FormEvent, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import { Button, Card, Icon, Input, Snack, type SnackState } from '@/components/ui';
import type { AdminSession, SecurityActivityEvent } from '../data/security';
import { useSettingsForm } from '../hooks/use-settings-form';
import styles from './settings-profile.module.css';

type SettingsTabId = 'profile' | 'preferences' | 'security';

type SettingsProfileProps = {
  initialSessions: AdminSession[];
  initialActivity: SecurityActivityEvent[];
};

type PasswordFormValues = {
  current: string;
  next: string;
  confirm: string;
};

type PasswordFormErrors = Partial<Record<keyof PasswordFormValues, string>>;

function validatePasswordForm(values: PasswordFormValues): PasswordFormErrors {
  const errors: PasswordFormErrors = {};

  if (!values.current.trim()) {
    errors.current = 'Current password is required.';
  }

  const trimmedNext = values.next.trim();
  if (!trimmedNext) {
    errors.next = 'New password is required.';
  } else if (trimmedNext.length < 8) {
    errors.next = 'New password must be at least 8 characters.';
  } else if (trimmedNext === values.current.trim()) {
    errors.next = 'New password must be different from your current password.';
  }

  if (!values.confirm.trim()) {
    errors.confirm = 'Please confirm your new password.';
  } else if (values.confirm.trim() !== trimmedNext) {
    errors.confirm = 'Passwords do not match.';
  }

  return errors;
}

export function SettingsProfile({ initialSessions, initialActivity }: SettingsProfileProps) {
  const [activeTab, setActiveTab] = useState<SettingsTabId>('profile');
  const { values, errors, successMessage, updateField, handleSubmit } = useSettingsForm();

  const [sessions, setSessions] = useState<AdminSession[]>(() => initialSessions.map((session) => ({ ...session })));
  const [activity] = useState<SecurityActivityEvent[]>(() => initialActivity);
  const [securitySnack, setSecuritySnack] = useState<SnackState | null>(null);

  const [isSignOutModalOpen, setIsSignOutModalOpen] = useState(false);
  const [isSigningOutOthers, setIsSigningOutOthers] = useState(false);

  const [passwordValues, setPasswordValues] = useState<PasswordFormValues>({
    current: '',
    next: '',
    confirm: '',
  });
  const [passwordErrors, setPasswordErrors] = useState<PasswordFormErrors>({});
  const [isPasswordConfirmModalOpen, setIsPasswordConfirmModalOpen] = useState(false);
  const [isConfirmingPasswordChange, setIsConfirmingPasswordChange] = useState(false);

  const otherSessionsCount = sessions.filter((session) => !session.isCurrent).length;

  function handlePasswordFieldChange(field: keyof PasswordFormValues, value: string) {
    setPasswordValues((prev) => ({ ...prev, [field]: value }));
    setPasswordErrors((prev) => ({ ...prev, [field]: undefined }));
    setSecuritySnack(null);
  }

  function handlePasswordFormSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors = validatePasswordForm(passwordValues);
    setPasswordErrors(nextErrors);

    if (Object.keys(nextErrors).length > 0) {
      setSecuritySnack({
        tone: 'warning',
        title: 'Check password fields',
        message: 'Please resolve the highlighted fields before continuing.',
      });
      return;
    }

    setIsPasswordConfirmModalOpen(true);
  }

  function confirmPasswordChange() {
    setIsConfirmingPasswordChange(true);

    window.setTimeout(() => {
      setIsConfirmingPasswordChange(false);
      setIsPasswordConfirmModalOpen(false);
      setPasswordValues({
        current: '',
        next: '',
        confirm: '',
      });
      setPasswordErrors({});
      setSecuritySnack({
        tone: 'success',
        title: 'Password updated',
        message: 'Your password has been updated. You will use it next time you sign in.',
      });
    }, 640);
  }

  function openSignOutModal() {
    if (otherSessionsCount === 0) {
      return;
    }

    setIsSignOutModalOpen(true);
  }

  function confirmSignOutOtherSessions() {
    setIsSigningOutOthers(true);

    window.setTimeout(() => {
      setSessions((previousSessions) => previousSessions.filter((session) => session.isCurrent));
      setIsSigningOutOthers(false);
      setIsSignOutModalOpen(false);
      setSecuritySnack({
        tone: 'success',
        title: 'Signed out of other sessions',
        message:
          otherSessionsCount === 1
            ? 'One other session has been signed out. Only this device remains active.'
            : `${otherSessionsCount} other sessions have been signed out. Only this device remains active.`,
      });
    }, 720);
  }

  return (
    <>
      <motion.div
        initial={{ opacity: 0, y: 14 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.28, ease: 'easeOut' }}
      >
        <Card className={styles.card}>
          <h2 className={styles.title}>Settings</h2>
          <div className={styles.tabs} role="tablist" aria-label="Settings tabs" aria-orientation="horizontal">
            <button
              type="button"
              role="tab"
              id="settings-tab-profile"
              aria-selected={activeTab === 'profile'}
              aria-controls="settings-panel-profile"
              className={`${styles.tab} ${activeTab === 'profile' ? styles.tabActive : ''}`}
              onClick={() => setActiveTab('profile')}
            >
              Edit Profile
            </button>
            <button
              type="button"
              role="tab"
              id="settings-tab-preferences"
              aria-selected={activeTab === 'preferences'}
              aria-controls="settings-panel-preferences"
              className={`${styles.tab} ${activeTab === 'preferences' ? styles.tabActive : ''}`}
              onClick={() => setActiveTab('preferences')}
            >
              Preferences
            </button>
            <button
              type="button"
              role="tab"
              id="settings-tab-security"
              aria-selected={activeTab === 'security'}
              aria-controls="settings-panel-security"
              className={`${styles.tab} ${activeTab === 'security' ? styles.tabActive : ''}`}
              onClick={() => setActiveTab('security')}
            >
              Security
            </button>
          </div>

          <AnimatePresence mode="wait">
            {activeTab === 'profile' ? (
              <motion.div
                key="profile-tab"
                role="tabpanel"
                id="settings-panel-profile"
                aria-labelledby="settings-tab-profile"
                tabIndex={0}
                className={styles.grid}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.2 }}
              >
                <div className={styles.avatarBlock}>
                  <div className={styles.avatar}>
                    <Icon name="user" size={34} className={styles.avatarIcon} />
                  </div>
                  <Button type="button" variant="outline" size="sm">
                    Upload photo
                  </Button>
                </div>

                <form className={styles.form} onSubmit={handleSubmit}>
                  <Input
                    id="settings-identity"
                    label="Change email or phone"
                    placeholder="Enter email or phone"
                    value={values.identity}
                    onChange={(event) => updateField('identity', event.target.value)}
                    errorText={errors.identity}
                  />
                  <Input
                    id="settings-password"
                    label="Password"
                    type="password"
                    placeholder="Enter password"
                    value={values.password}
                    onChange={(event) => updateField('password', event.target.value)}
                    errorText={errors.password}
                  />
                  <div className={styles.actions}>
                    <Button type="submit">
                      <Icon name="check" size={14} />
                      Save
                    </Button>
                  </div>
                </form>

                {successMessage ? (
                  <p className={styles.message} role="status">
                    {successMessage}
                  </p>
                ) : null}
              </motion.div>
            ) : null}

            {activeTab === 'preferences' ? (
              <motion.p
                key="preferences-tab"
                role="tabpanel"
                id="settings-panel-preferences"
                aria-labelledby="settings-tab-preferences"
                tabIndex={0}
                className={styles.placeholder}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.2 }}
              >
                Preferences controls will be introduced in the next admin iteration.
              </motion.p>
            ) : null}

            {activeTab === 'security' ? (
              <motion.div
                key="security-tab"
                role="tabpanel"
                id="settings-panel-security"
                aria-labelledby="settings-tab-security"
                tabIndex={0}
                className={styles.securityLayout}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.2 }}
              >
                <section className={styles.section}>
                  <header className={styles.sectionHeader}>
                    <h3 className={styles.sectionTitle}>Active sessions</h3>
                    <p className={styles.sectionDescription}>
                      View devices that are currently signed in to your admin account.
                    </p>
                  </header>
                  <ul className={styles.sessionsList}>
                    {sessions.map((session) => (
                      <li key={session.id} className={styles.sessionItem}>
                        <div className={styles.sessionLeading}>
                          <span className={styles.sessionDot} aria-hidden />
                        </div>
                        <div className={styles.sessionBody}>
                          <p className={styles.sessionTitle}>
                            {session.device}
                            {session.isCurrent ? <span className={styles.sessionTag}>This device</span> : null}
                          </p>
                          <p className={styles.sessionMeta}>
                            {session.location} · {session.ipAddress} · Last active {session.lastActiveLabel}
                          </p>
                        </div>
                      </li>
                    ))}
                    {sessions.length === 0 ? (
                      <li className={styles.sessionEmpty}>You are currently signed in on this device only.</li>
                    ) : null}
                  </ul>
                  <div className={styles.sectionActions}>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={openSignOutModal}
                      disabled={otherSessionsCount === 0}
                    >
                      Sign out of other sessions
                    </Button>
                  </div>
                </section>

                <section className={styles.section}>
                  <header className={styles.sectionHeader}>
                    <h3 className={styles.sectionTitle}>Change password</h3>
                    <p className={styles.sectionDescription}>
                      Update your password to keep your moderator access secure.
                    </p>
                  </header>
                  <form className={styles.securityForm} onSubmit={handlePasswordFormSubmit}>
                    <Input
                      id="security-current-password"
                      label="Current password"
                      type="password"
                      placeholder="Enter current password"
                      value={passwordValues.current}
                      onChange={(event) => handlePasswordFieldChange('current', event.target.value)}
                      errorText={passwordErrors.current}
                    />
                    <Input
                      id="security-new-password"
                      label="New password"
                      type="password"
                      placeholder="Enter new password"
                      value={passwordValues.next}
                      onChange={(event) => handlePasswordFieldChange('next', event.target.value)}
                      errorText={passwordErrors.next}
                    />
                    <Input
                      id="security-confirm-password"
                      label="Confirm new password"
                      type="password"
                      placeholder="Re-enter new password"
                      value={passwordValues.confirm}
                      onChange={(event) => handlePasswordFieldChange('confirm', event.target.value)}
                      errorText={passwordErrors.confirm}
                    />
                    <div className={styles.actions}>
                      <Button type="submit">
                        <Icon name="check" size={14} />
                        Change password
                      </Button>
                    </div>
                  </form>
                </section>

                <section className={styles.section}>
                  <header className={styles.sectionHeader}>
                    <h3 className={styles.sectionTitle}>Recent security activity</h3>
                    <p className={styles.sectionDescription}>
                      A quick overview of recent logins and sensitive actions.
                    </p>
                  </header>
                  <ol className={styles.activityList}>
                    {activity.length === 0 ? (
                      <li className={styles.activityItem}>
                        <div className={styles.activityBody}>
                          <p className={styles.activityTitle}>No recent security activity</p>
                          <p className={styles.activityDetail}>
                            Security events such as password changes and new device sign-ins will appear here.
                          </p>
                        </div>
                      </li>
                    ) : (
                      activity.map((event) => (
                        <li
                          key={event.id}
                          className={`${styles.activityItem} ${styles[`activityTone${event.tone[0].toUpperCase()}${event.tone.slice(1)}`]}`}
                        >
                          <span className={styles.activityIcon} aria-hidden>
                            <Icon name={event.icon} size={14} />
                          </span>
                          <div className={styles.activityBody}>
                            <p className={styles.activityTitle}>{event.title}</p>
                            <p className={styles.activityDetail}>{event.detail}</p>
                            <p className={styles.activityTime}>{event.occurredAtLabel}</p>
                          </div>
                        </li>
                      ))
                    )}
                  </ol>
                </section>
              </motion.div>
            ) : null}
          </AnimatePresence>
        </Card>
      </motion.div>

      <ActionConfirmModal
        isOpen={isSignOutModalOpen}
        title="Sign out of other sessions"
        description="This will sign out all sessions except the one you are using now. Use this if you suspect someone else has access."
        confirmLabel="Sign out others"
        confirmTone="danger"
        isConfirming={isSigningOutOthers}
        onCancel={() => setIsSignOutModalOpen(false)}
        onConfirm={confirmSignOutOtherSessions}
      />

      <ActionConfirmModal
        isOpen={isPasswordConfirmModalOpen}
        title="Save new password"
        description="You will use your new password the next time you sign in. Make sure you store it somewhere safe."
        confirmLabel="Save password"
        isConfirming={isConfirmingPasswordChange}
        onCancel={() => setIsPasswordConfirmModalOpen(false)}
        onConfirm={confirmPasswordChange}
      />

      <Snack snack={securitySnack} onClose={() => setSecuritySnack(null)} />
    </>
  );
}

