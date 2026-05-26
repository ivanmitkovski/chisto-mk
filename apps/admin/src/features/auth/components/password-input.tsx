'use client';

import { useState } from 'react';
import { Input, type InputProps } from '@/components/ui';
import styles from './password-input.module.css';

type PasswordInputProps = Omit<InputProps, 'type' | 'rightSlot'>;

export function PasswordInput(props: PasswordInputProps) {
  const [visible, setVisible] = useState(false);
  const [capsLockOn, setCapsLockOn] = useState(false);
  const helperText = capsLockOn
    ? 'Caps Lock is on.'
    : props.helperText;

  return (
    <Input
      {...props}
      type={visible ? 'text' : 'password'}
      helperText={helperText}
      onKeyUp={(event) => {
        setCapsLockOn(event.getModifierState('CapsLock'));
        props.onKeyUp?.(event);
      }}
      onBlur={(event) => {
        setCapsLockOn(false);
        props.onBlur?.(event);
      }}
      rightSlot={
        <button
          type="button"
          className={styles.toggle}
          aria-label={visible ? 'Hide password' : 'Show password'}
          aria-pressed={visible}
          onClick={() => setVisible((current) => !current)}
        >
          {visible ? 'Hide' : 'Show'}
        </button>
      }
    />
  );
}
