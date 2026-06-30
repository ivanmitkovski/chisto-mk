'use client';

import { FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Brand, Button, Checkbox, Input } from '@/components/ui';
import { useLoginForm } from '../hooks/use-login-form';
import { OtpInput } from './otp-input';
import { PasswordInput } from './password-input';
import styles from './login-screen.module.css';

const motionDuration = 0.22;
const motionEase = [0.22, 1, 0.36, 1] as const;

export function LoginScreen() {
  const t = useTranslations('auth');
  const router = useRouter();
  const shouldReduceMotion = useReducedMotion();
  const duration = shouldReduceMotion ? 0 : motionDuration;
  const initialX = shouldReduceMotion ? 0 : -16;
  const initialY = shouldReduceMotion ? 0 : 6;
  const {
    values,
    errors,
    step,
    totpCode,
    setTotpCode,
    useBackupCode,
    setUseBackupCode,
    isSubmitting,
    isLockedOut,
    lockoutRemainingSeconds,
    updateField,
    handleSubmit,
    handleTotpSubmit,
    resetToCredentials,
  } = useLoginForm();
  const currentYear = new Date().getFullYear();

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    handleSubmit(event).then((isValid) => {
      if (isValid) {
        window.setTimeout(() => router.push('/dashboard'), 300);
      }
    });
  }

  function onTotpSubmit(event: FormEvent<HTMLFormElement>) {
    handleTotpSubmit(event).then((isValid) => {
      if (isValid) {
        window.setTimeout(() => router.push('/dashboard'), 300);
      }
    });
  }

  return (
    <main className={styles.root}>
      <motion.section
        className={styles.left}
        initial={{ opacity: 0, x: initialX }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration, ease: motionEase }}
      >
        <motion.div
          initial={{ opacity: 0, y: initialY }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration, delay: shouldReduceMotion ? 0 : 0.06, ease: motionEase }}
        >
          <Brand priority />
        </motion.div>

        <AnimatePresence mode="wait">
          {step === 'credentials' ? (
            <motion.div
              key="credentials"
              initial={{ opacity: 0, y: initialY }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, x: shouldReduceMotion ? 0 : -12 }}
              transition={{ duration, ease: motionEase }}
              className={styles.stepContent}
            >
              <motion.h1
                className={styles.title}
                initial={{ opacity: 0, y: initialY }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration, delay: shouldReduceMotion ? 0 : 0.04, ease: motionEase }}
              >
                {t('signInTitle')}
              </motion.h1>

              <form className={styles.form} onSubmit={onSubmit}>
                <Input
                  id="login-email"
                  label={t('email')}
                  type="email"
                  autoComplete="email"
                  autoFocus
                  placeholder={t('emailPlaceholder')}
                  value={values.email}
                  onChange={(event) => updateField('email', event.target.value)}
                  errorText={errors.email}
                />
                <PasswordInput
                  id="login-password"
                  label={t('password')}
                  autoComplete="current-password"
                  placeholder={t('passwordPlaceholder')}
                  value={values.password}
                  onChange={(event) => updateField('password', event.target.value)}
                  errorText={errors.password}
                />
                <Checkbox
                  className={styles.checkboxRow}
                  checked={values.rememberDevice}
                  onChange={(event) => updateField('rememberDevice', event.target.checked)}
                  label={t('rememberDevice')}
                />
                {isLockedOut ? (
                  <p className={styles.lockout} role="status" aria-live="polite">
                    {t('lockout', { time: formatCountdown(lockoutRemainingSeconds) })}
                  </p>
                ) : null}
                <div className={styles.actionsRow}>
                  <Button
                    className={styles.button}
                    type="submit"
                    isLoading={isSubmitting}
                    disabled={isLockedOut}
                  >
                    {t('signIn')}
                  </Button>
                  <a className={styles.helpLink} href="mailto:support@chisto.mk?subject=Admin%20login%20help">
                    {t('forgotPassword')}
                  </a>
                </div>
              </form>
            </motion.div>
          ) : (
            <motion.div
              key="totp"
              initial={{ opacity: 0, x: shouldReduceMotion ? 0 : 12 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: shouldReduceMotion ? 0 : -12 }}
              transition={{ duration, ease: motionEase }}
              className={styles.stepContent}
            >
              <h1 className={styles.title}>{t('enterVerificationCode')}</h1>
              <p className={styles.totpSubtitle}>
                {useBackupCode ? t('totpSubtitleBackup') : t('totpSubtitleAuthenticator')}
              </p>

              <form className={styles.form} onSubmit={onTotpSubmit}>
                {useBackupCode ? (
                  <Input
                    id="login-totp"
                    label={t('backupCode')}
                    type="text"
                    inputMode="text"
                    autoComplete="one-time-code"
                    autoFocus
                    placeholder={t('backupCodePlaceholder')}
                    value={totpCode}
                    onChange={(event) => setTotpCode(event.target.value.slice(0, 32))}
                    maxLength={32}
                    errorText={errors.totp}
                  />
                ) : (
                  <OtpInput
                    id="login-totp"
                    label={t('verificationCode')}
                    value={totpCode}
                    onChange={setTotpCode}
                    disabled={isSubmitting}
                    errorText={errors.totp}
                  />
                )}
                <Button className={styles.button} type="submit" isLoading={isSubmitting}>
                  {t('verify')}
                </Button>
              </form>

              <button
                type="button"
                className={styles.toggleLink}
                onClick={() => {
                  setUseBackupCode((prev) => !prev);
                  setTotpCode('');
                }}
                disabled={isSubmitting}
              >
                {useBackupCode ? t('useAuthenticatorApp') : t('useBackupCode')}
              </button>

              <button
                type="button"
                className={styles.backLink}
                onClick={resetToCredentials}
                disabled={isSubmitting}
              >
                {t('useDifferentAccount')}
              </button>
            </motion.div>
          )}
        </AnimatePresence>

        <p className={styles.footer}>{t('copyright', { year: currentYear })}</p>
      </motion.section>

      <motion.section
        className={styles.right}
        initial={{ opacity: 0, scale: shouldReduceMotion ? 1 : 1.02 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: shouldReduceMotion ? 0 : 0.32, ease: motionEase }}
      />

    </main>
  );
}

function formatCountdown(totalSeconds: number): string {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}
