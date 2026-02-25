import { FormEvent, useState } from 'react';
import { SnackState } from '@/components/ui';

type LoginValues = {
  identity: string;
  password: string;
};

type LoginErrors = Partial<Record<keyof LoginValues, string>>;

const MOCK_ADMIN_CREDENTIALS = {
  identity: 'admin@chisto.mk',
  password: 'chisto1234',
};

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

  function handleSubmit(event: FormEvent<HTMLFormElement>): boolean {
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

    const isMatchingIdentity = values.identity.trim().toLowerCase() === MOCK_ADMIN_CREDENTIALS.identity;
    const isMatchingPassword = values.password.trim() === MOCK_ADMIN_CREDENTIALS.password;

    if (!isMatchingIdentity || !isMatchingPassword) {
      setSnack({
        tone: 'error',
        title: 'Login failed',
        message: 'Wrong username or password. Please try again.',
      });
      return false;
    }

    setSnack({
      tone: 'success',
      title: 'Welcome back',
      message: 'Login successful. Opening your admin dashboard...',
    });

    return true;
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
