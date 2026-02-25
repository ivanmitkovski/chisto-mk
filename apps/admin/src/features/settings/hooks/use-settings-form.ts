import { FormEvent, useState } from 'react';

type SettingsValues = {
  identity: string;
  password: string;
};

type SettingsErrors = Partial<Record<keyof SettingsValues, string>>;

function validate(values: SettingsValues): SettingsErrors {
  const errors: SettingsErrors = {};

  if (!values.identity.trim()) {
    errors.identity = 'Email or phone is required.';
  }

  if (values.password.length < 8) {
    errors.password = 'Password must be at least 8 characters.';
  }

  return errors;
}

export function useSettingsForm() {
  const [values, setValues] = useState<SettingsValues>({
    identity: '',
    password: '',
  });
  const [errors, setErrors] = useState<SettingsErrors>({});
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  function updateField(field: keyof SettingsValues, value: string) {
    setValues((prev) => ({ ...prev, [field]: value }));
    setErrors((prev) => ({ ...prev, [field]: undefined }));
    setSuccessMessage(null);
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const nextErrors = validate(values);
    setErrors(nextErrors);

    if (Object.keys(nextErrors).length > 0) {
      setSuccessMessage(null);
      return;
    }

    setSuccessMessage('Profile settings have been saved.');
  }

  return {
    values,
    errors,
    successMessage,
    updateField,
    handleSubmit,
  };
}
