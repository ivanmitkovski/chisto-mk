'use client';

import { FormEvent, useEffect, useRef, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { AnimatePresence, motion } from 'framer-motion';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import { Button, Icon, Input, Snack, type SnackState } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import { ApiError } from '@/lib/api';
import type { MeProfile } from '@/features/auth/data/me-adapter';
import type { ConfigEntry } from '@/features/settings/data/config-adapter';
import type { FeatureFlagRow } from '@/features/settings/data/feature-flags-adapter';
import type { AdminSession, SecurityActivityEvent } from '../data/security';
import { SettingsMfaSection } from './settings-mfa-section';
import { SettingsPreferencesSection } from './settings-preferences-section';
import styles from './settings-console.module.css';

type SectionId = 'profile' | 'security' | 'environment' | 'featureFlags' | 'preferences';

const SECTION_IDS: SectionId[] = ['profile', 'security', 'environment', 'featureFlags', 'preferences'];

type SectionGroup = {
  label: string;
  items: { id: SectionId; label: string; icon: string }[];
};

const SIDEBAR_GROUPS: SectionGroup[] = [
  {
    label: 'Account',
    items: [
      { id: 'profile', label: 'Profile', icon: 'user' },
      { id: 'security', label: 'Security', icon: 'shield' },
    ],
  },
  {
    label: 'System',
    items: [
      { id: 'environment', label: 'Environment', icon: 'setting' },
      { id: 'featureFlags', label: 'Feature flags', icon: 'document-duplicate' },
    ],
  },
  {
    label: 'Preferences',
    items: [{ id: 'preferences', label: 'Preferences', icon: 'document-text' }],
  },
];

type SettingsConsoleProps = {
  initialMe: MeProfile;
  initialSessions: AdminSession[];
  initialActivity: SecurityActivityEvent[];
  initialConfig: ConfigEntry[];
  initialFlags: FeatureFlagRow[];
};

function getInitials(firstName: string, lastName: string): string {
  const f = firstName?.trim().charAt(0) ?? '';
  const l = lastName?.trim().charAt(0) ?? '';
  return `${f}${l}`.toUpperCase() || '?';
}

function formatRole(role: string): string {
  return role.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

export function SettingsConsole({
  initialMe,
  initialSessions,
  initialActivity,
  initialConfig,
  initialFlags,
}: SettingsConsoleProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [section, setSection] = useState<SectionId>('profile');
  const [firstName, setFirstName] = useState(initialMe.firstName);
  const [lastName, setLastName] = useState(initialMe.lastName);
  const [profileSnack, setProfileSnack] = useState<SnackState | null>(null);
  const [profileBusy, setProfileBusy] = useState(false);

  const [sessions, setSessions] = useState<AdminSession[]>(() => initialSessions.map((s) => ({ ...s })));
  const [activity] = useState<SecurityActivityEvent[]>(() => initialActivity);
  const [securitySnack, setSecuritySnack] = useState<SnackState | null>(null);
  const [signOutModal, setSignOutModal] = useState(false);
  const [signOutBusy, setSignOutBusy] = useState(false);
  const [pwd, setPwd] = useState({ current: '', next: '', confirm: '' });
  const [pwdErr, setPwdErr] = useState<Partial<typeof pwd>>({});
  const [pwdModal, setPwdModal] = useState(false);
  const [pwdBusy, setPwdBusy] = useState(false);

  const [configRows, setConfigRows] = useState<ConfigEntry[]>(() => initialConfig.map((c) => ({ ...c })));
  const [configBusy, setConfigBusy] = useState(false);
  const [configSnack, setConfigSnack] = useState<SnackState | null>(null);

  const [flags, setFlags] = useState<FeatureFlagRow[]>(() => initialFlags.map((f) => ({ ...f })));
  const [flagBusy, setFlagBusy] = useState<string | null>(null);
  const [mfaEnabled, setMfaEnabled] = useState(initialMe.mfaEnabled ?? false);

  const isSuperAdmin = initialMe.role === 'SUPER_ADMIN';
  const otherSessions = sessions.filter((s) => !s.isCurrent).length;
  const hasProfileChanges =
    firstName !== initialMe.firstName || lastName !== initialMe.lastName;
  const panelTitleRef = useRef<HTMLHeadingElement>(null);
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mq.matches);
    const handler = () => setPrefersReducedMotion(mq.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  useEffect(() => {
    const raw = searchParams.get('section');
    if (raw && SECTION_IDS.includes(raw as SectionId)) {
      setSection(raw as SectionId);
    }
  }, [searchParams]);

  function handleSectionChange(next: SectionId) {
    setSection(next);
    router.replace(`/dashboard/settings?section=${next}`, { scroll: false });
  }

  useEffect(() => {
    panelTitleRef.current?.focus({ preventScroll: true });
  }, [section]);

  async function saveProfile(e: FormEvent) {
    e.preventDefault();
    setProfileBusy(true);
    setProfileSnack(null);
    try {
      await adminBrowserFetch('/auth/me', {
        method: 'PATCH',
        body: { firstName, lastName },
      });
      setProfileSnack({ tone: 'success', title: 'Saved', message: 'Profile updated.' });
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : 'Could not save';
      setProfileSnack({ tone: 'warning', title: 'Error', message: msg });
    } finally {
      setProfileBusy(false);
    }
  }

  async function revokeOthers() {
    setSignOutBusy(true);
    try {
      await adminBrowserFetch('/admin/sessions/me/others', { method: 'DELETE' });
      setSessions((prev) => prev.filter((s) => s.isCurrent));
      setSecuritySnack({
        tone: 'success',
        title: 'Signed out',
        message: 'Other sessions were revoked.',
      });
      setSignOutModal(false);
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : 'Request failed';
      setSecuritySnack({ tone: 'warning', title: 'Error', message: msg });
    } finally {
      setSignOutBusy(false);
    }
  }

  function submitPwd(e: FormEvent) {
    e.preventDefault();
    const err: Partial<typeof pwd> = {};
    if (!pwd.current.trim()) err.current = 'Required';
    if (pwd.next.length < 8) err.next = 'Min 8 characters';
    if (pwd.next !== pwd.confirm) err.confirm = 'Must match';
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
      setSecuritySnack({
        tone: 'success',
        title: 'Password updated',
        message: 'Use your new password next sign in.',
      });
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : 'Failed';
      setSecuritySnack({ tone: 'warning', title: 'Error', message: msg });
    } finally {
      setPwdBusy(false);
    }
  }

  async function saveConfig() {
    if (!isSuperAdmin) return;
    setConfigBusy(true);
    setConfigSnack(null);
    try {
      await adminBrowserFetch('/admin/config', {
        method: 'PATCH',
        body: { entries: configRows.map((r) => ({ key: r.key, value: r.value })) },
      });
      setConfigSnack({ tone: 'success', title: 'Saved', message: 'Configuration updated.' });
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : 'Failed';
      setConfigSnack({ tone: 'warning', title: 'Error', message: msg });
    } finally {
      setConfigBusy(false);
    }
  }

  async function toggleFlag(key: string, enabled: boolean) {
    setFlagBusy(key);
    try {
      const res = await adminBrowserFetch<{ key: string; enabled: boolean }>(
        `/admin/feature-flags/${encodeURIComponent(key)}`,
        { method: 'PATCH', body: { enabled } },
      );
      setFlags((prev) => prev.map((f) => (f.key === key ? { ...f, enabled: res.enabled } : f)));
    } catch {
      setConfigSnack({ tone: 'warning', title: 'Error', message: 'Could not update flag' });
    } finally {
      setFlagBusy(null);
    }
  }

  return (
    <>
      <motion.div
        className={styles.layout}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.2 }}
      >
        <a href="#settings-main" className="skipLink">
          Skip to settings content
        </a>
        <nav className={styles.sidebar} aria-label="Settings sections">
          {SIDEBAR_GROUPS.map((group) => (
            <div key={group.label} className={styles.sidebarSection}>
              <span className={styles.sidebarSectionLabel}>{group.label}</span>
              <div className={styles.sidebarItems}>
                {group.items.map((s) => (
                  <button
                    key={s.id}
                    type="button"
                    className={`${styles.sidebarItem} ${section === s.id ? styles.sidebarItemActive : ''}`}
                    onClick={() => handleSectionChange(s.id)}
                    aria-current={section === s.id ? 'true' : undefined}
                  >
                    <Icon
                      name={s.icon as 'user' | 'shield' | 'setting' | 'document-duplicate' | 'document-text'}
                      size={18}
                    />
                    <span>{s.label}</span>
                  </button>
                ))}
              </div>
            </div>
          ))}
        </nav>

        <div className={styles.content} id="settings-main" tabIndex={-1}>
          <AnimatePresence mode="wait">
            {section === 'profile' && (
              <motion.div
                key="profile"
                className={styles.panel}
                initial={{ opacity: 0, x: prefersReducedMotion ? 0 : 12 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: prefersReducedMotion ? 0 : -12 }}
                transition={{ duration: prefersReducedMotion ? 0 : 0.22 }}
              >
                <header className={styles.panelHeader}>
                  <h2 ref={panelTitleRef} className={styles.panelTitle} tabIndex={-1}>
                    Profile
                  </h2>
                  <p className={styles.panelDescription}>Your account information.</p>
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
                    {initialMe.phoneNumber && (
                      <p className={styles.profilePhone}>{initialMe.phoneNumber}</p>
                    )}
                  </div>
                </div>
                <form className={styles.form} onSubmit={saveProfile}>
                  <div className={styles.formGroup}>
                    <Input
                      id="fn"
                      label="First name"
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      disabled={profileBusy}
                    />
                    <Input
                      id="ln"
                      label="Last name"
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      disabled={profileBusy}
                    />
                  </div>
                  {hasProfileChanges && (
                    <p className={styles.unsavedHint}>Unsaved changes</p>
                  )}
                  <Button type="submit" disabled={profileBusy || !hasProfileChanges}>
                    {profileBusy ? 'Saving…' : 'Save changes'}
                  </Button>
                </form>
              </motion.div>
            )}

            {section === 'security' && (
              <motion.div
                key="security"
                className={styles.panel}
                initial={{ opacity: 0, x: prefersReducedMotion ? 0 : 12 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: prefersReducedMotion ? 0 : -12 }}
                transition={{ duration: prefersReducedMotion ? 0 : 0.22 }}
              >
                <header className={styles.panelHeader}>
                  <h2 ref={panelTitleRef} className={styles.panelTitle} tabIndex={-1}>
                    Security
                  </h2>
                  <p className={styles.panelDescription}>Sessions, password, and activity.</p>
                </header>

                <section className={styles.section}>
                  <span className={styles.sectionLabel}>Sessions</span>
                  <h3 className={styles.sectionTitle}>Active sessions</h3>
                  <p className={styles.sectionHint}>Devices currently signed in to your account.</p>
                  <div className={styles.insetGroup}>
                    <ul className={styles.list}>
                      {sessions.map((session) => (
                        <li key={session.id} className={styles.listItem}>
                        <span className={styles.sessionIcon} aria-hidden>
                          <Icon name="shield" size={16} />
                        </span>
                        <div className={styles.sessionInfo}>
                          <span className={styles.sessionDevice}>
                            {session.device}
                            {session.isCurrent && <span className={styles.sessionCurrent}>This device</span>}
                          </span>
                          <span className={styles.sessionMeta}>
                            {session.ipAddress} · {session.lastActiveLabel}
                          </span>
                        </div>
                      </li>
                    ))}
                    </ul>
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setSignOutModal(true)}
                    disabled={otherSessions === 0}
                  >
                    Sign out other sessions
                  </Button>
                </section>

                <SettingsMfaSection
                  mfaEnabled={mfaEnabled}
                  onMfaChange={setMfaEnabled}
                />

                <section className={styles.section}>
                  <span className={styles.sectionLabel}>Password</span>
                  <h3 className={styles.sectionTitle}>Change password</h3>
                  <form className={styles.passwordForm} onSubmit={submitPwd}>
                    <Input
                      id="pc"
                      label="Current password"
                      type="password"
                      value={pwd.current}
                      onChange={(e) => setPwd((p) => ({ ...p, current: e.target.value }))}
                      errorText={pwdErr.current}
                    />
                    <Input
                      id="pn"
                      label="New password"
                      type="password"
                      value={pwd.next}
                      onChange={(e) => setPwd((p) => ({ ...p, next: e.target.value }))}
                      errorText={pwdErr.next}
                    />
                    <Input
                      id="pnc"
                      label="Confirm new password"
                      type="password"
                      value={pwd.confirm}
                      onChange={(e) => setPwd((p) => ({ ...p, confirm: e.target.value }))}
                      errorText={pwdErr.confirm}
                    />
                    <Button type="submit">Change password</Button>
                  </form>
                </section>

                <section className={styles.section}>
                  <span className={styles.sectionLabel}>Activity</span>
                  <h3 className={styles.sectionTitle}>Recent activity</h3>
                  <p className={styles.sectionHint}>Security-related events on your account.</p>
                  {activity.length === 0 ? (
                    <div className={styles.activityEmpty}>
                      <Icon name="document-text" size={48} aria-hidden />
                      <span>No activity yet.</span>
                    </div>
                  ) : (
                  <div className={styles.insetGroup}>
                    <ol className={styles.activityList}>
                      {activity.map((ev) => (
                        <li key={ev.id} className={`${styles.activityItem} ${styles[`activityTone${ev.tone.charAt(0).toUpperCase() + ev.tone.slice(1)}`]}`}>
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
              </motion.div>
            )}

            {section === 'environment' && (
              <motion.div
                key="env"
                className={styles.panel}
                initial={{ opacity: 0, x: prefersReducedMotion ? 0 : 12 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: prefersReducedMotion ? 0 : -12 }}
                transition={{ duration: prefersReducedMotion ? 0 : 0.22 }}
              >
                <header className={styles.panelHeader}>
                  <h2 ref={panelTitleRef} className={styles.panelTitle} tabIndex={-1}>
                    Environment
                  </h2>
                  <p className={styles.panelDescription}>
                    System configuration. Super admin only.
                  </p>
                </header>
                {!isSuperAdmin ? (
                  <div className={styles.restricted}>
                    <Icon name="shield" size={48} />
                    <p>This section is restricted to super administrators.</p>
                  </div>
                ) : (
                  <section className={styles.section}>
                    <h3 className={styles.sectionTitle}>Configuration entries</h3>
                    <div className={styles.insetGroup}>
                      {configRows.map((row, i) => (
                        <div key={row.key} className={styles.configRow}>
                          <label htmlFor={`cfg-${row.key}`} className={styles.configLabel}>
                            {row.key}
                          </label>
                          <Input
                            id={`cfg-${row.key}`}
                            value={row.value}
                            onChange={(e) => {
                              const v = e.target.value;
                              setConfigRows((prev) => {
                                const next = [...prev];
                                next[i] = { ...next[i], value: v };
                                return next;
                              });
                            }}
                          />
                        </div>
                      ))}
                    </div>
                    <Button onClick={() => void saveConfig()} disabled={configBusy}>
                      {configBusy ? 'Saving…' : 'Save configuration'}
                    </Button>
                  </section>
                )}
              </motion.div>
            )}

            {section === 'featureFlags' && (
              <motion.div
                key="ff"
                className={styles.panel}
                initial={{ opacity: 0, x: prefersReducedMotion ? 0 : 12 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: prefersReducedMotion ? 0 : -12 }}
                transition={{ duration: prefersReducedMotion ? 0 : 0.22 }}
              >
                <header className={styles.panelHeader}>
                  <h2 ref={panelTitleRef} className={styles.panelTitle} tabIndex={-1}>
                    Feature flags
                  </h2>
                  <p className={styles.panelDescription}>
                    Enable or disable features across the platform.
                  </p>
                </header>
                <section className={styles.section}>
                  <div className={styles.insetGroup}>
                    <ul className={styles.flagList}>
                      {flags.map((f) => {
                      const desc =
                        f.metadata && typeof f.metadata === 'object' && 'description' in f.metadata
                          ? (f.metadata as { description?: unknown }).description
                          : null;
                      const descStr = typeof desc === 'string' ? desc : null;
                      return (
                      <li key={f.key} className={styles.flagItem}>
                        <div className={styles.flagInfo}>
                          <span className={styles.flagKey}>{f.key}</span>
                          {descStr != null ? (
                            <span className={styles.flagDesc}>{descStr}</span>
                          ) : null}
                        </div>
                        <button
                          type="button"
                          role="switch"
                          aria-checked={f.enabled}
                          disabled={flagBusy === f.key}
                          className={`${styles.toggle} ${f.enabled ? styles.toggleOn : ''}`}
                          onClick={() => void toggleFlag(f.key, !f.enabled)}
                        >
                          <span className={styles.toggleThumb} />
                        </button>
                      </li>
                    );
                    })}
                    </ul>
                    {flags.length === 0 && (
                      <p className={styles.empty}>No feature flags configured.</p>
                    )}
                  </div>
                </section>
              </motion.div>
            )}

            {section === 'preferences' && (
              <motion.div
                key="pref"
                className={styles.panel}
                initial={{ opacity: 0, x: prefersReducedMotion ? 0 : 12 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: prefersReducedMotion ? 0 : -12 }}
                transition={{ duration: prefersReducedMotion ? 0 : 0.22 }}
              >
                <SettingsPreferencesSection panelTitleRef={panelTitleRef} />
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </motion.div>

      <ActionConfirmModal
        isOpen={signOutModal}
        title="Sign out other sessions"
        description="This will revoke access for all other devices. You will stay signed in on this device."
        confirmLabel="Revoke all"
        confirmTone="danger"
        isConfirming={signOutBusy}
        onCancel={() => setSignOutModal(false)}
        onConfirm={() => void revokeOthers()}
      />

      <ActionConfirmModal
        isOpen={pwdModal}
        title="Update password"
        description="Your new password will take effect on your next sign in."
        confirmLabel="Update password"
        isConfirming={pwdBusy}
        onCancel={() => setPwdModal(false)}
        onConfirm={() => void confirmPwd()}
      />

      <Snack snack={profileSnack} onClose={() => setProfileSnack(null)} />
      <Snack snack={securitySnack} onClose={() => setSecuritySnack(null)} />
      <Snack snack={configSnack} onClose={() => setConfigSnack(null)} />
    </>
  );
}
