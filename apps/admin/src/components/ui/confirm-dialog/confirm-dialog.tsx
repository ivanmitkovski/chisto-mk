'use client';

import { useEffect, useId, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button } from '../button';
import { Input } from '../input';
import { Modal } from '../modal';

export type ConfirmDialogTone = 'default' | 'danger';

export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel,
  cancelLabel,
  tone = 'default',
  isLoading,
  confirmPhrase,
  children,
  onConfirm,
  onClose,
}: {
  open: boolean;
  title: string;
  description?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  tone?: ConfirmDialogTone;
  isLoading?: boolean;
  /** When set, user must type this phrase exactly before confirming. */
  confirmPhrase?: string;
  children?: React.ReactNode;
  onConfirm: () => void;
  onClose: () => void;
}) {
  const t = useTranslations('ui');
  const [typedPhrase, setTypedPhrase] = useState('');
  const phraseInputId = useId();
  const resolvedConfirm = confirmLabel ?? t('confirm');
  const resolvedCancel = cancelLabel ?? t('cancel');
  const phraseRequired = Boolean(confirmPhrase);
  const phraseMatches = !phraseRequired || typedPhrase === confirmPhrase;

  useEffect(() => {
    if (!open) setTypedPhrase('');
  }, [open]);

  return (
    <Modal
      open={open}
      title={title}
      {...(description ? { description } : {})}
      onClose={onClose}
      footer={
        <>
          <Button type="button" variant="outline" onClick={onClose} disabled={isLoading}>
            {resolvedCancel}
          </Button>
          <Button
            type="button"
            variant={tone === 'danger' ? 'danger' : 'solid'}
            onClick={onConfirm}
            isLoading={Boolean(isLoading)}
            disabled={!phraseMatches}
          >
            {resolvedConfirm}
          </Button>
        </>
      }
    >
      {phraseRequired ? (
        <Input
          id={phraseInputId}
          label={t('typeToConfirm', { phrase: confirmPhrase ?? '' })}
          value={typedPhrase}
          onChange={(event) => setTypedPhrase(event.target.value)}
          autoComplete="off"
          spellCheck={false}
        />
      ) : null}
      {children}
    </Modal>
  );
}
