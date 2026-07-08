'use client';

import { Button, Modal } from '@/components/ui';
import { summarizeImportedBlocks, type ClipboardImportResult } from '@chisto/news-content';
import { useTranslations } from 'next-intl';
import styles from './news-paste-confirm-dialog.module.css';

type NewsPasteConfirmDialogProps = {
  open: boolean;
  result: ClipboardImportResult | null;
  onReplace: () => void;
  onInsert: () => void;
  onClose: () => void;
};

export function NewsPasteConfirmDialog({
  open,
  result,
  onReplace,
  onInsert,
  onClose,
}: NewsPasteConfirmDialogProps) {
  const t = useTranslations('news');

  if (!result) return null;

  const summary = summarizeImportedBlocks(result.blocks);
  const parts: string[] = [];
  if (summary.quote) parts.push(t('paste.summaryQuote', { count: summary.quote }));
  if (summary.heading) parts.push(t('paste.summaryHeading', { count: summary.heading }));
  if (summary.paragraph) parts.push(t('paste.summaryParagraph', { count: summary.paragraph }));
  if (summary.list) parts.push(t('paste.summaryList', { count: summary.list }));
  if (summary.divider) parts.push(t('paste.summaryDivider', { count: summary.divider }));
  if (summary.other) parts.push(t('paste.summaryOther', { count: summary.other }));

  return (
    <Modal
      open={open}
      title={t('paste.confirmTitle')}
      description={t('paste.confirmDescription', { count: summary.total })}
      onClose={onClose}
      footer={
        <div className={styles.footer}>
          <Button type="button" variant="outline" onClick={onClose}>
            {t('paste.cancel')}
          </Button>
          <Button type="button" variant="outline" onClick={onInsert}>
            {t('paste.insertAtCursor')}
          </Button>
          <Button type="button" onClick={onReplace}>
            {t('paste.replaceBody')}
          </Button>
        </div>
      }
    >
      <p className={styles.summary}>{parts.join(' · ')}</p>
      {result.truncated ? <p className={styles.warn}>{t('paste.truncatedWarning')}</p> : null}
    </Modal>
  );
}
