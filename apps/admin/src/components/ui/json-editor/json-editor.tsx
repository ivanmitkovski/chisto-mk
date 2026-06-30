'use client';

import { TextareaHTMLAttributes, useEffect, useId, useMemo } from 'react';

import { Field, fieldDescriptionId } from '../field';
import { validateJson } from './validate-json';
import styles from './json-editor.module.css';

export type JsonEditorProps = Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, 'value' | 'onChange'> & {
  label?: string;
  value: string;
  onChange: (value: string) => void;
  onValidityChange?: (valid: boolean, error?: string) => void;
  helperText?: string;
};

export function JsonEditor({
  id,
  label,
  value,
  onChange,
  onValidityChange,
  helperText,
  className,
  disabled,
  rows = 12,
  ...rest
}: JsonEditorProps) {
  const fallbackId = useId();
  const textareaId = id ?? fallbackId;
  const validation = useMemo(() => validateJson(value), [value]);
  const errorText = validation.valid ? undefined : validation.error;
  const descriptionId = fieldDescriptionId(textareaId, errorText, helperText);

  useEffect(() => {
    onValidityChange?.(validation.valid, validation.valid ? undefined : validation.error);
  }, [onValidityChange, validation]);

  const textareaClassName = [
    styles.textarea,
    errorText ? styles.textareaError : '',
    className ?? '',
  ]
    .join(' ')
    .trim();

  return (
    <Field label={label} htmlFor={textareaId} helperText={helperText} errorText={errorText}>
      <textarea
        {...rest}
        id={textareaId}
        className={textareaClassName}
        value={value}
        rows={rows}
        disabled={disabled}
        spellCheck={false}
        aria-invalid={Boolean(errorText)}
        aria-describedby={descriptionId}
        onChange={(event) => onChange(event.target.value)}
      />
    </Field>
  );
}
