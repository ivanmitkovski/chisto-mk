'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { completeTotpLogin, loginAdmin } from '../lib/admin-auth';

type LoginValues = {
  email: string;
  password: string;
  rememberDevice: boolean;
};

type LoginErrors = Partial<Record<'email' | 'password' | 'totp', string>>;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type AuthTranslator = ReturnType<typeof useTranslations<'auth'>>;

function validate(values: LoginValues, t: AuthTranslator): LoginErrors {
  const errors: LoginErrors = {};

  const email = values.email.trim();
  if (!email) {
    errors.email = t('validation.emailRequired');
  } else if (!EMAIL_RE.test(email)) {
    errors.email = t('validation.emailInvalid');
  }

  if (!values.password) {
    errors.password = t('validation.passwordRequired');
  } else if (values.password.length < 8) {
    errors.password = t('validation.passwordMinLength');
  }

  return errors;
}

export type LoginStep = 'credentials' | 'totp';

export function useLoginForm() {
  const t = useTranslations('auth');
  const { showToast, clearToast } = useToast();
  const [values, setValues] = useState<LoginValues>({
    email: '',
    password: '',
    rememberDevice: false,
  });
  const [step, setStep] = useState<LoginStep>('credentials');
  const [tempToken, setTempToken] = useState<string | null>(null);
  const [totpCode, setTotpCode] = useState('');
  const [useBackupCode, setUseBackupCode] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<LoginErrors>({});
  const [lockoutUntilMs, setLockoutUntilMs] = useState<number | null>(null);
  const [lockoutRemainingSeconds, setLockoutRemainingSeconds] = useState(0);

  useEffect(() => {
    if (lockoutUntilMs == null) {
      setLockoutRemainingSeconds(0);
      return undefined;
    }
    const tick = () => {
      const remaining = Math.max(0, Math.ceil((lockoutUntilMs - Date.now()) / 1000));
      setLockoutRemainingSeconds(remaining);
      if (remaining <= 0) {
        setLockoutUntilMs(null);
      }
    };
    tick();
    const interval = window.setInterval(tick, 1000);
    return () => window.clearInterval(interval);
  }, [lockoutUntilMs]);

  function updateField(field: keyof LoginValues, value: string | boolean) {
    setValues((prev) => ({ ...prev, [field]: value }));
    if (field === 'email' || field === 'password') {
      setErrors((prev) => {
        const next = { ...prev };
        delete next[field];
        return next;
      });
    }
    clearToast();
  }

  function updateTotpCode(value: string) {
    setTotpCode(value);
    setErrors((prev) => {
      const next = { ...prev };
      delete next.totp;
      return next;
    });
    clearToast();
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>): Promise<boolean> {
    event.preventDefault();
    const nextErrors = validate(values, t);
    setErrors(nextErrors);

    if (Object.keys(nextErrors).length > 0) {
      showToast({
        tone: 'warning',
        title: t('toast.checkRequiredFieldsTitle'),
        message: t('toast.checkRequiredFieldsMessage'),
      });
      return false;
    }
    if (lockoutRemainingSeconds > 0) {
      showToast({
        tone: 'warning',
        title: t('toast.accountLockedTitle'),
        message: t('toast.accountLockedMessage', { time: formatCountdown(lockoutRemainingSeconds) }),
      });
      return false;
    }

    setIsSubmitting(true);
    try {
      const result = await loginAdmin(values.email.trim(), values.password, {
        rememberDevice: values.rememberDevice,
      });

      if ('requiresTotp' in result && result.requiresTotp) {
        setTempToken(result.tempToken);
        setStep('totp');
        setTotpCode('');
        return false;
      }

      showToast({
        tone: 'success',
        title: t('toast.welcomeBackTitle'),
        message: t('toast.welcomeBackMessage'),
      });

      return true;
    } catch (error) {
      if (error instanceof ApiError) {
        const isAdminError = error.code === 'ADMIN_ACCESS_REQUIRED';
        const isDbError = error.code === 'DATABASE_TIMEOUT' || error.code === 'DATABASE_UNAVAILABLE' || error.code === 'DATABASE_DISCONNECTED';
        const isLockout = error.code === 'TOO_MANY_ATTEMPTS';
        const isAccountInactive = error.code === 'ACCOUNT_NOT_ACTIVE' || error.code === 'ACCOUNT_SUSPENDED';

        const isBackendUnavailable =
          error.code === 'API_CONNECTION_FAILED' || error.code === 'BACKEND_TIMEOUT';

        let message: string;
        if (isAdminError) {
          message = t('toast.adminAccessRequiredMessage');
        } else if (isLockout) {
          const retryAfter = (
            error.details as { retryAfterSeconds?: number } | undefined
          )?.retryAfterSeconds;
          const minutes = retryAfter != null ? Math.ceil(retryAfter / 60) : 15;
          setLockoutUntilMs(Date.now() + (retryAfter ?? minutes * 60) * 1000);
          message = t('toast.tooManyAttemptsMessage', { minutes });
        } else if (isAccountInactive) {
          message = error.message || t('toast.accountInactiveMessage');
        } else if (isDbError) {
          message = error.message || t('toast.serviceTemporarilyUnavailableMessage');
        } else if (isBackendUnavailable) {
          message = error.message;
        } else if (error.code === 'INVALID_CREDENTIALS') {
          message = t('toast.invalidCredentialsMessage');
        } else if (error.status >= 500) {
          message = error.message || t('toast.serverUnavailableMessage');
        } else {
          message = error.message || t('toast.invalidCredentialsMessage');
        }

        showToast({
          tone: 'error',
          title: isAdminError
            ? t('toast.adminAccessRequiredTitle')
            : isLockout
              ? t('toast.accountLockedTitle')
              : isBackendUnavailable
                ? t('toast.serviceUnavailableTitle')
                : t('toast.loginFailedTitle'),
          message,
        });
        return false;
      }

      showToast({
        tone: 'error',
        title: t('toast.loginFailedTitle'),
        message: t('toast.unexpectedLoginErrorMessage'),
      });
      return false;
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleTotpSubmit(event: FormEvent<HTMLFormElement>): Promise<boolean> {
    event.preventDefault();
    const code = totpCode.trim();
    const totpRequiredMessage = useBackupCode
      ? t('validation.totpBackupRequired')
      : t('validation.totpCodeRequired');

    if (!tempToken || code.length < 6) {
      setErrors((prev) => ({
        ...prev,
        totp: totpRequiredMessage,
      }));
      showToast({
        tone: 'warning',
        title: t('toast.enterCodeTitle'),
        message: totpRequiredMessage,
      });
      return false;
    }

    setIsSubmitting(true);
    try {
      await completeTotpLogin(tempToken, code, { rememberDevice: values.rememberDevice });

      showToast({
        tone: 'success',
        title: t('toast.welcomeBackTitle'),
        message: t('toast.welcomeBackMessage'),
      });

      return true;
    } catch (error) {
      if (error instanceof ApiError) {
        if (error.code === 'INVALID_TEMP_TOKEN') {
          resetToCredentials();
          showToast({
            tone: 'error',
            title: t('toast.sessionExpiredTitle'),
            message: t('toast.sessionExpiredMessage'),
          });
          return false;
        }
        const invalidCodeMessage = error.message || t('toast.invalidCodeMessage');
        showToast({
          tone: 'error',
          title: t('toast.verificationFailedTitle'),
          message: invalidCodeMessage,
        });
        setErrors((prev) => ({ ...prev, totp: invalidCodeMessage }));
        return false;
      }

      showToast({
        tone: 'error',
        title: t('toast.verificationFailedTitle'),
        message: t('toast.unexpectedVerificationErrorMessage'),
      });
      return false;
    } finally {
      setIsSubmitting(false);
    }
  }

  function resetToCredentials(): void {
    setStep('credentials');
    setTempToken(null);
    setTotpCode('');
    setUseBackupCode(false);
    setErrors({});
    clearToast();
  }

  return {
    values,
    errors,
    step,
    tempToken,
    totpCode,
    setTotpCode: updateTotpCode,
    useBackupCode,
    setUseBackupCode,
    isSubmitting,
    isLockedOut: lockoutRemainingSeconds > 0,
    lockoutRemainingSeconds,
    updateField,
    handleSubmit,
    handleTotpSubmit,
    resetToCredentials,
  };
}

function formatCountdown(totalSeconds: number): string {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}
