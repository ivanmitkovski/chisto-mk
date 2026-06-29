'use client';

import { useCallback, useRef, useState, type DragEvent, type ReactNode } from 'react';
import { Button, Spinner } from '@/components/ui';
import styles from './media-upload-zone.module.css';

export type MediaUploadZoneProps = {
  accept: string;
  label: string;
  hint?: string;
  dropRegionAriaLabel?: string;
  error?: string | null;
  busy?: boolean;
  compact?: boolean;
  disabled?: boolean;
  onFileSelected: (file: File) => void;
  action?: ReactNode;
};

export function MediaUploadZone({
  accept,
  label,
  hint,
  dropRegionAriaLabel,
  error,
  busy = false,
  compact = false,
  disabled = false,
  onFileSelected,
  action,
}: MediaUploadZoneProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = useState(false);

  const pickFile = useCallback(
    (file: File | undefined) => {
      if (!file || disabled || busy) return;
      onFileSelected(file);
    },
    [busy, disabled, onFileSelected],
  );

  const onInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      pickFile(e.target.files?.[0]);
      e.target.value = '';
    },
    [pickFile],
  );

  const onDrop = useCallback(
    (e: DragEvent) => {
      e.preventDefault();
      setDragOver(false);
      if (disabled || busy) return;
      pickFile(e.dataTransfer.files?.[0]);
    },
    [busy, disabled, pickFile],
  );

  const rootClass = [
    styles.root,
    compact ? styles.compact : '',
    dragOver ? styles.dragOver : '',
    disabled || busy ? styles.disabled : '',
    error ? styles.hasError : '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div
      className={rootClass}
      role="region"
      aria-label={dropRegionAriaLabel ?? label}
      onDragOver={(e) => {
        e.preventDefault();
        if (!disabled && !busy) setDragOver(true);
      }}
      onDragLeave={() => setDragOver(false)}
      onDrop={onDrop}
      aria-busy={busy}
    >
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        className={styles.input}
        disabled={disabled || busy}
        onChange={onInputChange}
        tabIndex={-1}
        aria-hidden
      />
      <div className={styles.content}>
        {busy ? <Spinner size="sm" /> : null}
        <p className={styles.label}>{label}</p>
        {hint ? <p className={styles.hint}>{hint}</p> : null}
        {error ? (
          <p className={styles.error} role="alert">
            {error}
          </p>
        ) : null}
        <Button
          type="button"
          variant="outline"
          size="sm"
          disabled={disabled || busy}
          onClick={() => inputRef.current?.click()}
        >
          {label}
        </Button>
        {action}
      </div>
      {busy ? <div className={styles.progressTrack} aria-hidden /> : null}
    </div>
  );
}
