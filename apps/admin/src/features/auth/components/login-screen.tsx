'use client';

import { FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Brand, Button, Input, Snack } from '@/components/ui';
import { useLoginForm } from '../hooks/use-login-form';
import styles from './login-screen.module.css';

const motionDuration = 0.22;
const motionEase = [0.22, 1, 0.36, 1] as const;

export function LoginScreen() {
  const router = useRouter();
  const shouldReduceMotion = useReducedMotion();
  const duration = shouldReduceMotion ? 0 : motionDuration;
  const initialX = shouldReduceMotion ? 0 : -16;
  const initialY = shouldReduceMotion ? 0 : 6;
  const {
    values,
    errors,
    snack,
    step,
    totpCode,
    setTotpCode,
    useBackupCode,
    setUseBackupCode,
    isSubmitting,
    updateField,
    handleSubmit,
    handleTotpSubmit,
    resetToCredentials,
    clearSnack,
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
                Sign in
              </motion.h1>

              <form className={styles.form} onSubmit={onSubmit}>
                <Input
                  id="login-email"
                  label="Email"
                  type="email"
                  autoComplete="email"
                  autoFocus
                  placeholder="admin@chisto.mk"
                  value={values.email}
                  onChange={(event) => updateField('email', event.target.value)}
                  errorText={errors.email}
                />
                <Input
                  id="login-password"
                  label="Password"
                  type="password"
                  autoComplete="current-password"
                  placeholder="••••••••••••"
                  value={values.password}
                  onChange={(event) => updateField('password', event.target.value)}
                  errorText={errors.password}
                />
                <Button className={styles.button} type="submit" isLoading={isSubmitting}>
                  Sign in
                </Button>
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
              <h1 className={styles.title}>Enter verification code</h1>
              <p className={styles.totpSubtitle}>
                {useBackupCode
                  ? 'Enter one of your backup codes.'
                  : 'Open your authenticator app and enter the 6-digit code.'}
              </p>

              <form className={styles.form} onSubmit={onTotpSubmit}>
                <Input
                  id="login-totp"
                  label={useBackupCode ? 'Backup code' : 'Verification code'}
                  type="text"
                  inputMode={useBackupCode ? 'text' : 'numeric'}
                  autoComplete="one-time-code"
                  autoFocus
                  placeholder={useBackupCode ? 'xxxxxxxx-xxxxxxxx' : '000000'}
                  value={totpCode}
                  onChange={(event) =>
                    setTotpCode(
                      useBackupCode
                        ? event.target.value.slice(0, 32)
                        : event.target.value.replace(/\D/g, '').slice(0, 6),
                    )
                  }
                  maxLength={useBackupCode ? 32 : 6}
                />
                <Button className={styles.button} type="submit" isLoading={isSubmitting}>
                  Verify
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
                {useBackupCode ? 'Use authenticator app' : 'Use backup code'}
              </button>

              <button
                type="button"
                className={styles.backLink}
                onClick={resetToCredentials}
                disabled={isSubmitting}
              >
                Use a different account
              </button>
            </motion.div>
          )}
        </AnimatePresence>

        <p className={styles.footer}>Copyright {currentYear} Chisto.mk. All rights reserved.</p>
      </motion.section>

      <motion.section
        className={styles.right}
        initial={{ opacity: 0, scale: shouldReduceMotion ? 1 : 1.02 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: shouldReduceMotion ? 0 : 0.32, ease: motionEase }}
      />

      <Snack snack={snack} onClose={clearSnack} />
    </main>
  );
}
