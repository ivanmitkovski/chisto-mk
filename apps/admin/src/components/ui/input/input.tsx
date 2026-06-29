import { InputHTMLAttributes, ReactNode, RefObject, useId } from 'react';
import { Field, fieldDescriptionId } from '../field';
import styles from './input.module.css';

export type InputProps = Omit<InputHTMLAttributes<HTMLInputElement>, 'size'> & {
  label?: string | undefined;
  helperText?: string | undefined;
  errorText?: string | undefined;
  leftSlot?: ReactNode | undefined;
  rightSlot?: ReactNode | undefined;
  fieldClassName?: string | undefined;
  inputRef?: RefObject<HTMLInputElement | null> | undefined;
};

export function Input({
  id,
  label,
  helperText,
  errorText,
  leftSlot,
  rightSlot,
  fieldClassName,
  inputRef,
  className,
  required,
  ...rest
}: InputProps) {
  const fallbackId = useId();
  const inputId = id ?? fallbackId;
  const hasError = Boolean(errorText);
  const descriptionId = fieldDescriptionId(inputId, errorText, helperText);

  const inputClassName = [
    styles.input,
    leftSlot ? styles.withLeftSlot : '',
    rightSlot ? styles.withRightSlot : '',
    hasError ? styles.error : '',
    className ?? '',
  ]
    .join(' ')
    .trim();

  const { type, role, ...inputRest } = rest;
  const hasCustomClear = Boolean(rightSlot);
  const resolvedType = type === 'search' && hasCustomClear ? 'text' : type;
  const resolvedRole = role ?? (type === 'search' && hasCustomClear ? 'searchbox' : undefined);

  return (
    <Field
      label={label}
      htmlFor={inputId}
      helperText={helperText}
      errorText={errorText}
      required={required}
      className={fieldClassName}
    >
      <div className={styles.inputWrap}>
        {leftSlot ? <span className={styles.leftSlot}>{leftSlot}</span> : null}
        <input
          {...inputRest}
          type={resolvedType}
          {...(resolvedRole ? { role: resolvedRole } : {})}
          id={inputId}
          ref={inputRef}
          className={inputClassName}
          required={required}
          aria-invalid={hasError}
          aria-describedby={descriptionId}
        />
        {rightSlot ? <span className={styles.rightSlot}>{rightSlot}</span> : null}
      </div>
    </Field>
  );
}
