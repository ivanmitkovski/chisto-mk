'use client';

import { useEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useRouter, useSearchParams } from 'next/navigation';
import { AnimatePresence, motion } from 'framer-motion';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import { ConfirmDialog } from '@/components/ui';
import type { MeProfile } from '@/features/auth/data/me-adapter';
import type { ConfigEntry } from '@/features/settings/data/config-adapter';
import type { FeatureFlagRow } from '@/features/settings/data/feature-flags-adapter';
import type { AdminSession, SecurityActivityEvent } from '../data/security-types';
import { SECTION_IDS, type SectionId } from '@/features/settings/config/settings-sections';
import { useProfileSettings } from '@/features/settings/hooks/use-profile-settings';
import { useSecuritySettings } from '@/features/settings/hooks/use-security-settings';
import { useEnvironmentConfig } from '@/features/settings/hooks/use-environment-config';
import { useFeatureFlags } from '@/features/settings/hooks/use-feature-flags';
import { useModerationEmailPreferences } from '@/features/settings/hooks/use-moderation-email-preferences';
import type { ModerationEmailPreferenceRow } from '@/features/settings/data/moderation-email-preferences-adapter';
import { SettingsModerationEmailsPanel } from './settings-moderation-emails-panel';
import { SettingsSidebar } from './settings-sidebar';
import { SettingsProfilePanel } from './settings-profile-panel';
import { SettingsSecurityPanel } from './settings-security-panel';
import { SettingsEnvironmentPanel } from './settings-environment-panel';
import { SettingsFeatureFlagsPanel } from './settings-feature-flags-panel';
import { SettingsPreferencesSection } from './settings-preferences-section';
import panelStyles from './settings-panel.module.css';
import styles from './settings-console.module.css';

type SettingsConsoleProps = {
  initialMe: MeProfile;
  initialSessions: AdminSession[];
  initialActivity: SecurityActivityEvent[];
  initialConfig: ConfigEntry[];
  initialFlags: FeatureFlagRow[];
  initialModerationEmailPrefs: ModerationEmailPreferenceRow[];
};

export function SettingsConsole({
  initialMe,
  initialSessions,
  initialActivity,
  initialConfig,
  initialFlags,
  initialModerationEmailPrefs,
}: SettingsConsoleProps) {
  const t = useTranslations('settings');
  const tCommon = useTranslations('common');
  const tModals = useTranslations('settings.securityModals');
  const router = useRouter();
  const searchParams = useSearchParams();
  const [section, setSection] = useState<SectionId>('profile');
  const panelTitleRef = useRef<HTMLHeadingElement>(null);
  const [prefersReducedMotion, setPrefersReducedMotion] = useState(false);
  const [envSaveConfirmOpen, setEnvSaveConfirmOpen] = useState(false);

  const profile = useProfileSettings(initialMe);
  const security = useSecuritySettings(initialMe, initialSessions, initialActivity);
  const environment = useEnvironmentConfig(initialConfig);
  const featureFlags = useFeatureFlags(initialFlags);
  const moderationEmails = useModerationEmailPreferences(initialModerationEmailPrefs);

  const isSuperAdmin = initialMe.role === 'SUPER_ADMIN';

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

  const motionProps = {
    initial: { opacity: 0, x: prefersReducedMotion ? 0 : 12 },
    animate: { opacity: 1, x: 0 },
    exit: { opacity: 0, x: prefersReducedMotion ? 0 : -12 },
    transition: { duration: prefersReducedMotion ? 0 : 0.22 },
  };

  return (
    <>
      <motion.div
        className={styles.layout}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.2 }}
      >
        <a href="#settings-main" className="skipLink">
          {t('skipToContent')}
        </a>
        <SettingsSidebar section={section} onSectionChange={handleSectionChange} />

        <div className={styles.content} id="settings-main" tabIndex={-1}>
          <AnimatePresence mode="wait">
            {section === 'profile' && (
              <motion.div key="profile" {...motionProps}>
                <SettingsProfilePanel
                  initialMe={initialMe}
                  firstName={profile.firstName}
                  lastName={profile.lastName}
                  busy={profile.busy}
                  hasChanges={profile.hasChanges}
                  panelTitleRef={panelTitleRef}
                  onFirstNameChange={profile.setFirstName}
                  onLastNameChange={profile.setLastName}
                  onSubmit={(e) => void profile.saveProfile(e)}
                />
              </motion.div>
            )}

            {section === 'security' && (
              <motion.div key="security" {...motionProps}>
                <SettingsSecurityPanel
                  sessions={security.sessions}
                  activity={security.activity}
                  pwd={security.pwd}
                  pwdErr={security.pwdErr}
                  mfaEnabled={security.mfaEnabled}
                  otherSessions={security.otherSessions}
                  panelTitleRef={panelTitleRef}
                  onPwdChange={security.setPwd}
                  onMfaChange={security.setMfaEnabled}
                  onSignOutOthers={() => security.setSignOutModal(true)}
                  onSubmitPwd={security.submitPwd}
                />
              </motion.div>
            )}

            {section === 'environment' && (
              <motion.div key="env" {...motionProps}>
                <SettingsEnvironmentPanel
                  isSuperAdmin={isSuperAdmin}
                  rows={environment.rows}
                  busy={environment.busy}
                  panelTitleRef={panelTitleRef}
                  onRowValueChange={environment.updateRowValue}
                  onSave={() => {
                    if (environment.isDirty) {
                      setEnvSaveConfirmOpen(true);
                    }
                  }}
                />
              </motion.div>
            )}

            {section === 'featureFlags' && (
              <motion.div key="ff" {...motionProps}>
                <SettingsFeatureFlagsPanel
                  flags={featureFlags.flags}
                  busyKey={featureFlags.busyKey}
                  panelTitleRef={panelTitleRef}
                  onToggle={featureFlags.toggleFlag}
                /></motion.div>
            )}

            {section === 'moderationEmails' && (
              <motion.div key="mod-email" {...motionProps}>
                <SettingsModerationEmailsPanel
                  rows={moderationEmails.rows}
                  busyCategory={moderationEmails.busyCategory}
                  panelTitleRef={panelTitleRef}
                  onToggle={moderationEmails.toggle}
                />
              </motion.div>
            )}

            {section === 'preferences' && (
              <motion.div key="pref" className={panelStyles.panel} {...motionProps}>
                <SettingsPreferencesSection panelTitleRef={panelTitleRef} />
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </motion.div>

      <ActionConfirmModal
        isOpen={security.signOutModal}
        title={tModals('signOutOthersTitle')}
        description={tModals('signOutOthersDescription')}
        confirmLabel={tModals('signOutOthersConfirm')}
        confirmTone="danger"
        isConfirming={security.signOutBusy}
        onCancel={() => security.setSignOutModal(false)}
        onConfirm={() => void security.revokeOthers()}
      />

      <ActionConfirmModal
        isOpen={security.pwdModal}
        title={tModals('updatePasswordTitle')}
        description={tModals('updatePasswordDescription')}
        confirmLabel={tModals('updatePasswordConfirm')}
        isConfirming={security.pwdBusy}
        onCancel={() => security.setPwdModal(false)}
        onConfirm={() => void security.confirmPwd()}
      />

      <ActionConfirmModal
        isOpen={envSaveConfirmOpen}
        title={t('environment.confirmSaveTitle')}
        description={t('environment.confirmSaveDescription')}
        confirmLabel={t('environment.saveConfiguration')}
        isConfirming={environment.busy}
        onCancel={() => setEnvSaveConfirmOpen(false)}
        onConfirm={() => {
          void environment.saveConfig().then(() => setEnvSaveConfirmOpen(false));
        }}
      />

      <ConfirmDialog
        open={featureFlags.pendingToggle != null}
        title={t('featureFlags.confirmToggleTitle')}
        description={
          featureFlags.pendingToggle
            ? t('featureFlags.confirmToggleDescription', {
                key: featureFlags.pendingToggle.key,
                state: featureFlags.pendingToggle.enabled
                  ? t('featureFlags.confirmEnable')
                  : t('featureFlags.confirmDisable'),
              })
            : ''
        }
        confirmLabel={tCommon('confirm')}
        isLoading={featureFlags.busyKey != null}
        onConfirm={() => {
          if (!featureFlags.pendingToggle) return;
          void featureFlags.applyToggle(
            featureFlags.pendingToggle.key,
            featureFlags.pendingToggle.enabled,
          );
        }}
        onClose={() => featureFlags.setPendingToggle(null)}
      />

    </>
  );
}
