import { FormEvent, useState } from 'react';
import { SnackState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { loginAdmin } from '../lib/admin-auth';

type LoginValues = {
  identity: string;
  password: string;
};

type LoginErrors = Partial<Record<keyof LoginValues, string>>;

function validate(values: LoginValues): LoginErrors {
  const errors: LoginErrors = {};

  if (!values.identity.trim()) {
    errors.identity = 'Email or phone is required.';
  }

  if (!values.password.trim()) {
    errors.password = 'Password is required.';
  } else if (values.password.trim().length < 8) {
    errors.password = 'Password must contain at least 8 characters.';
  }

  return errors;
}

export function useLoginForm() {
  const [values, setValues] = useState<LoginValues>({
    identity: '',
    password: '',
  });
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

    try {
      await loginAdmin(values.identity.trim(), values.password.trim());

      setSnack({
        tone: 'success',
        title: 'Welcome back',
        message: 'Login successful. Opening your admin dashboard...',
      });

      return true;
    } catch (error) {
      if (error instanceof ApiError) {
        const isAdminError = error.code === 'ADMIN_ACCESS_REQUIRED';

        setSnack({
          tone: 'error',
          title: isAdminError ? 'Admin access required' : 'Login failed',
          message: isAdminError
            ? 'This account does not have admin privileges for the console.'
            : 'Wrong email or password. Please try again.',
        });
        return false;
      }

      setSnack({
        tone: 'error',
        title: 'Login failed',
        message: 'Unexpected error while logging in. Please try again.',
      });
      return false;
    }
  }

  return {
    values,
    errors,
    snack,
    updateField,
    handleSubmit,
    clearSnack: () => setSnack(null),
  };
}
