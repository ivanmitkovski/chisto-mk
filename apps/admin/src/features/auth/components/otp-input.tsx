'use client';

import { ClipboardEvent, KeyboardEvent, useMemo, useRef } from 'react';
import styles from './otp-input.module.css';

type OtpInputProps = {
  id: string;
  label: string;
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean | undefined;
  errorText?: string | undefined;
};

const OTP_LENGTH = 6;

export function OtpInput({ id, label, value, onChange, disabled, errorText }: OtpInputProps) {
  const refs = useRef<Array<HTMLInputElement | null>>([]);
  const digits = useMemo(() => value.padEnd(OTP_LENGTH, ' ').slice(0, OTP_LENGTH).split(''), [value]);

  function updateAt(index: number, nextDigit: string): void {
    const next = digits.slice();
    next[index] = nextDigit;
    onChange(next.join('').replace(/\s/g, '').slice(0, OTP_LENGTH));
  }

  function focusIndex(index: number): void {
    refs.current[index]?.focus();
    refs.current[index]?.select();
  }

  function handlePaste(event: ClipboardEvent<HTMLInputElement>): void {
    const pasted = event.clipboardData.getData('text').replace(/\D/g, '').slice(0, OTP_LENGTH);
    if (!pasted) return;
    event.preventDefault();
    onChange(pasted);
    focusIndex(Math.min(pasted.length, OTP_LENGTH) - 1);
  }

  function handleKeyDown(index: number, event: KeyboardEvent<HTMLInputElement>): void {
    if (event.key === 'Backspace' && !digits[index]?.trim() && index > 0) {
      event.preventDefault();
      updateAt(index - 1, '');
      focusIndex(index - 1);
    }
    if (event.key === 'ArrowLeft' && index > 0) {
      event.preventDefault();
      focusIndex(index - 1);
    }
    if (event.key === 'ArrowRight' && index < OTP_LENGTH - 1) {
      event.preventDefault();
      focusIndex(index + 1);
    }
  }

  return (
    <fieldset className={styles.fieldset} aria-describedby={errorText ? `${id}-error` : undefined}>
      <legend className={styles.label}>{label}</legend>
      <div className={styles.cells}>
        {digits.map((digit, index) => (
          <input
            key={index}
            ref={(node) => {
              refs.current[index] = node;
            }}
            className={styles.cell}
            aria-label={`Digit ${index + 1}`}
            aria-invalid={Boolean(errorText)}
            inputMode="numeric"
            autoComplete={index === 0 ? 'one-time-code' : 'off'}
            pattern="[0-9]*"
            maxLength={1}
            disabled={disabled}
            value={digit.trim()}
            onPaste={handlePaste}
            onKeyDown={(event) => handleKeyDown(index, event)}
            onChange={(event) => {
              const next = event.target.value.replace(/\D/g, '').slice(-1);
              updateAt(index, next);
              if (next && index < OTP_LENGTH - 1) {
                focusIndex(index + 1);
              }
            }}
          />
        ))}
      </div>
      {errorText ? (
        <p id={`${id}-error`} className={styles.error}>
          {errorText}
        </p>
      ) : null}
    </fieldset>
  );
}
