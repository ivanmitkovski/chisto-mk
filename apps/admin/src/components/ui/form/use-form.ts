'use client';

import { ChangeEvent, useState } from 'react';

export type FormErrors<TValues extends Record<string, unknown>> = Partial<Record<keyof TValues, string>>;

type Validator<TValues extends Record<string, unknown>> = (
  values: TValues,
) => FormErrors<TValues>;

export function useForm<TValues extends Record<string, unknown>>(
  initialValues: TValues,
  validate: Validator<TValues>,
) {
  const [values, setValues] = useState<TValues>(initialValues);
  const [errors, setErrors] = useState<FormErrors<TValues>>({});
  const [dirty, setDirty] = useState<Partial<Record<keyof TValues, boolean>>>({});

  function setField<TKey extends keyof TValues>(key: TKey, value: TValues[TKey]): void {
    setValues((current) => ({ ...current, [key]: value }));
    setDirty((current) => ({ ...current, [key]: true }));
    setErrors((current) => {
      const next = { ...current };
      delete next[key];
      return next;
    });
  }

  function bindText<TKey extends keyof TValues>(key: TKey) {
    return {
      value: String(values[key] ?? ''),
      onChange: (event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
        setField(key, event.target.value as TValues[TKey]),
    };
  }

  function validateNow(): boolean {
    const nextErrors = validate(values);
    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  }

  return {
    values,
    errors,
    dirty,
    setField,
    setValues,
    setErrors,
    bindText,
    validateNow,
  };
}
