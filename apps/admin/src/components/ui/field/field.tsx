import { ReactNode } from 'react';
import styles from './field.module.css';

export type FieldProps = {
  label?: string | undefined;
  htmlFor?: string | undefined;
  helperText?: string | undefined;
  errorText?: string | undefined;
  required?: boolean | undefined;
  children: ReactNode;
  className?: string | undefined;
};

export function fieldDescriptionId(
  htmlFor: string | undefined,
  errorText?: string,
  helperText?: string,
): string | undefined {
  if (!htmlFor) return undefined;
  if (errorText) return `${htmlFor}-error`;
  if (helperText) return `${htmlFor}-help`;
  return undefined;
}

export function Field({
  label,
  htmlFor,
  helperText,
  errorText,
  required,
  children,
  className,
}: FieldProps) {
  const hasError = Boolean(errorText);
  const descriptionId = fieldDescriptionId(htmlFor, errorText, helperText);

  const rootClassName = [styles.field, className ?? ''].join(' ').trim();

  return (
    <div className={rootClassName}>
      {label ? (
        <label className={styles.label} htmlFor={htmlFor}>
          {label}
          {required ? (
            <span className={styles.required} aria-hidden>
              {' '}
              *
            </span>
          ) : null}
        </label>
      ) : null}
      {children}
      {hasError ? (
        <p id={descriptionId} className={`${styles.message} ${styles.messageError}`}>
          {errorText}
        </p>
      ) : helperText ? (
        <p id={descriptionId} className={styles.message}>
          {helperText}
        </p>
      ) : null}
    </div>
  );
}
