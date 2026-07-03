'use client';

import type { Editor } from '@tiptap/react';
import { useTranslations } from 'next-intl';
import { useCallback, useEffect, useRef, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Modal } from '@/components/ui/modal';
import { useToast } from '@/components/ui/toast';
import {
  applyEditorLink,
  canApplyEditorLink,
  type LinkSelectionSnapshot,
} from '@/lib/rich-text/apply-editor-link';
import styles from './rich-text-editor.module.css';

type RichTextLinkDialogProps = {
  editor: Editor | null;
  snapshot: LinkSelectionSnapshot | null;
  open: boolean;
  onClose: () => void;
  onApplied?: () => void;
  dialogClassName?: string;
};

export function RichTextLinkDialog({
  editor,
  snapshot,
  open,
  onClose,
  onApplied,
  dialogClassName,
}: RichTextLinkDialogProps) {
  const t = useTranslations('news');
  const { showToast } = useToast();
  const snapshotRef = useRef<LinkSelectionSnapshot | null>(null);
  const [linkUrl, setLinkUrl] = useState('https://');
  const [linkText, setLinkText] = useState('');
  const [linkNewTab, setLinkNewTab] = useState(true);
  const [selectionWasEmpty, setSelectionWasEmpty] = useState(false);

  useEffect(() => {
    if (!open || !snapshot) return;
    snapshotRef.current = snapshot;
    setSelectionWasEmpty(snapshot.empty && !snapshot.hadLink);
    setLinkUrl(snapshot.href ?? 'https://');
    setLinkText(
      snapshot.empty
        ? ''
        : editor?.state.doc.textBetween(snapshot.from, snapshot.to, ' ') ?? '',
    );
    setLinkNewTab(snapshot.target === '_blank' || !snapshot.href);
  }, [editor, open, snapshot]);

  const handleClose = useCallback(() => {
    snapshotRef.current = null;
    onClose();
  }, [onClose]);

  const applyLink = useCallback(() => {
    if (!editor || !snapshotRef.current) return;
    const snapshot = snapshotRef.current;
    const result = applyEditorLink(editor, snapshot, {
      url: linkUrl,
      newTab: linkNewTab,
      linkText,
    });

    if (!result.ok) {
      const message =
        result.error === 'invalid_url'
          ? t('form.linkInvalidUrl')
          : result.error === 'no_target'
            ? t('form.linkTextRequired')
            : t('form.linkApplyFailed');
      showToast({ tone: 'danger', title: t('toast.error'), message });
      return;
    }

    snapshotRef.current = null;
    onClose();
    onApplied?.();
  }, [editor, linkNewTab, linkText, linkUrl, onApplied, onClose, showToast, t]);

  const removeLink = useCallback(() => {
    if (!editor || !snapshotRef.current) return;
    editor
      .chain()
      .focus()
      .setTextSelection({ from: snapshotRef.current.from, to: snapshotRef.current.to })
      .extendMarkRange('link')
      .unsetLink()
      .run();
    snapshotRef.current = null;
    onClose();
    onApplied?.();
  }, [editor, onApplied, onClose]);

  const activeSnapshot = snapshotRef.current;
  const canApply = activeSnapshot
    ? canApplyEditorLink(activeSnapshot, { url: linkUrl, newTab: linkNewTab, linkText })
    : false;

  const description = selectionWasEmpty
    ? t('form.linkDialogDescriptionInsert')
    : linkText.trim()
      ? t('form.linkDialogDescriptionWithText', { text: linkText.trim() })
      : t('form.linkDialogDescription');

  return (
    <Modal open={open} title={t('form.linkDialogTitle')} description={description} onClose={handleClose}>
      <div className={dialogClassName ?? styles.linkDialog}>
        <div className={styles.linkTextPreview} aria-live="polite">
          <span className={styles.linkTextLabel}>{t('form.linkText')}</span>
          {selectionWasEmpty ? (
            <input
              type="text"
              className={styles.linkTextInput}
              value={linkText}
              onChange={(event) => setLinkText(event.target.value)}
              placeholder={t('form.linkTextPlaceholder')}
              autoFocus
            />
          ) : linkText.trim() ? (
            <p className={styles.linkTextValue}>{linkText.trim()}</p>
          ) : (
            <p className={styles.linkTextEmpty}>{t('form.linkTextEmpty')}</p>
          )}
        </div>
        <label className={styles.linkField}>
          <span>{t('form.linkUrl')}</span>
          <input
            type="url"
            value={linkUrl}
            onChange={(event) => setLinkUrl(event.target.value)}
            placeholder="https://"
            autoFocus={!selectionWasEmpty}
          />
        </label>
        <label className={styles.checkboxRow}>
          <input type="checkbox" checked={linkNewTab} onChange={(event) => setLinkNewTab(event.target.checked)} />
          {t('form.linkOpenNewTab')}
        </label>
        <div className={styles.linkActions}>
          <Button type="button" variant="ghost" onClick={removeLink}>
            {t('form.removeLink')}
          </Button>
          <Button type="button" onClick={applyLink} disabled={!canApply}>
            {t('form.applyLink')}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
