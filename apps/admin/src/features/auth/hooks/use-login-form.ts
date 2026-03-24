import { FormEvent, useState } from 'react';
import { SnackState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { completeTotpLogin, loginAdmin } from '../lib/admin-auth';

type LoginValues = {
  email: string;
  password: string;
};

type LoginErrors = Partial<Record<keyof LoginValues, string>>;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function validate(values: LoginValues): LoginErrors {
  const errors: LoginErrors = {};

  const email = values.email.trim();
  if (!email) {
    errors.email = 'Email is required.';
  } else if (!EMAIL_RE.test(email)) {
    errors.email = 'Please enter a valid email address.';
  }

  if (!values.password.trim()) {
    errors.password = 'Password is required.';
  } else if (values.password.trim().length < 8) {
    errors.password = 'Password must contain at least 8 characters.';
  }

  return errors;
}

export type LoginStep = 'credentials' | 'totp';

export function useLoginForm() {
  const [values, setValues] = useState<LoginValues>({
    email: '',
    password: '',
  });
  const [step, setStep] = useState<LoginStep>('credentials');
  const [tempToken, setTempToken] = useState<string | null>(null);
  const [totpCode, setTotpCode] = useState('');
  const [useBackupCode, setUseBackupCode] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<LoginErrors>({});
  const [snack, setSnack] = useState<SnackState | null>(null);

  function updateField(field: keyof LoginValues, value: string) {
    setValues((prev) => ({ ...prev, [field]: value }));
    setErrors((prev) => ({ ...prev, [field]: undefined }));
    setSnack(null);
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>): Promise<boolean> {
    event.preventDefault();
    const nextErrors = validate(values);
    setErrors(nextErrors);

    if (Object.keys(nextErrors).length > 0) {
      setSnack({
        tone: 'warning',
        title: 'Check required fields',
        message: 'Please resolve the highlighted fields before continuing.',
      });
      return false;
    }

    setIsSubmitting(true);
    try {
      const result = await loginAdmin(values.email.trim(), values.password.trim());

      if ('requiresTotp' in result && result.requiresTotp) {
        setTempToken(result.tempToken);
        setStep('totp');
        setTotpCode('');
        return false;
      }

      setSnack({
        tone: 'success',
        title: 'Welcome back',
        message: 'Login successful. Opening your admin dashboard...',
      });

      return true;
    } catch (error) {
      if (error instanceof ApiError) {
        const isAdminError = error.code === 'ADMIN_ACCESS_REQUIRED';
        const isDbError = error.code === 'DATABASE_TIMEOUT' || error.code === 'DATABASE_UNAVAILABLE' || error.code === 'DATABASE_DISCONNECTED';
        const isLockout = error.code === 'TOO_MANY_ATTEMPTS';
        const isAccountInactive = error.code === 'ACCOUNT_NOT_ACTIVE' || error.code === 'ACCOUNT_SUSPENDED';

        let message: string;
        if (isAdminError) {
          message = 'This account does not have admin privileges for the console.';
        } else if (isLockout) {
          const retryAfter = (
            error.details as { retryAfterSeconds?: number } | undefined
          )?.retryAfterSeconds;
          const minutes = retryAfter != null ? Math.ceil(retryAfter / 60) : 15;
          message = `Too many attempts. Try again in ${minutes} minute${minutes !== 1 ? 's' : ''}.`;
        } else if (isAccountInactive) {
          message = error.message || 'This account is not active. Contact support for assistance.';
        } else if (isDbError) {
          message = error.message || 'The service is temporarily unavailable. Please try again in a moment.';
        } else if (error.code === 'INVALID_CREDENTIALS') {
          message = 'Wrong email or password. Please try again.';
        } else if (error.status >= 500) {
          message = error.message || 'The server is temporarily unavailable. Please try again.';
        } else {
          message = error.message || 'Wrong email or password. Please try again.';
        }

        setSnack({
          tone: 'error',
          title: isAdminError ? 'Admin access required' : isLockout ? 'Account locked' : 'Login failed',
          message,
        });
        return false;
      }

      setSnack({
        tone: 'error',
        title: 'Login failed',
        message: 'Unexpected error while logging in. Please try again.',
      });
      return false;
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleTotpSubmit(event: FormEvent<HTMLFormElement>): Promise<boolean> {
    event.preventDefault();
    const code = totpCode.trim();
    if (!tempToken || code.length < 6) {
      setSnack({
        tone: 'warning',
        title: 'Enter code',
        message: useBackupCode
          ? 'Please enter your backup code.'
          : 'Please enter the 6-digit code from your authenticator app.',
      });
      return false;
    }

    setIsSubmitting(true);
    try {
      await completeTotpLogin(tempToken, code);

      setSnack({
        tone: 'success',
        title: 'Welcome back',
        message: 'Login successful. Opening your admin dashboard...',
      });

      return true;
    } catch (error) {
      if (error instanceof ApiError) {
        if (error.code === 'INVALID_TEMP_TOKEN') {
          resetToCredentials();
          setSnack({
            tone: 'error',
            title: 'Session expired',
            message: 'Verification timed out. Please sign in again.',
          });
          return false;
        }
        setSnack({
          tone: 'error',
          title: 'Verification failed',
          message: error.message || 'Invalid code. Please try again.',
        });
        return false;
      }

      setSnack({
        tone: 'error',
        title: 'Verification failed',
        message: 'Unexpected error. Please try again.',
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
    setSnack(null);
  }

  return {
    values,
    errors,
    snack,
    step,
    tempToken,
    totpCode,
    setTotpCode,
    useBackupCode,
    setUseBackupCode,
    isSubmitting,
    updateField,
    handleSubmit,
    handleTotpSubmit,
    resetToCredentials,
    clearSnack: () => setSnack(null),
  };
}
