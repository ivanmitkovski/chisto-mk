'use client';

import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import { localeCompleteness } from '../lib/news-locale-utils';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import styles from './news-publish-checklist-dialog.module.css';

type ChecklistItem = 'title' | 'excerpt' | 'body' | 'cover';

function localeChecklist(
  values: NewsPostFormValues,
  locale: NewsFormLocale,
  hasCover: boolean,
): { item: ChecklistItem; ok: boolean }[] {
  const entry = values.translations[locale];
  const bodyOk =
    entry.body.length > 0 &&
    entry.body.every(
      (b) =>
        (b.type === 'paragraph' && b.text.trim()) ||
        ((b.type === 'image' || b.type === 'video') && b.mediaId.trim()),
    );
  return [
    { item: 'title', ok: Boolean(entry.title.trim()) },
    { item: 'excerpt', ok: Boolean(entry.excerpt.trim()) },
    { item: 'body', ok: bodyOk },
    { item: 'cover', ok: hasCover },
  ];
}

type NewsPublishChecklistDialogProps = {
  open: boolean;
  values: NewsPostFormValues;
  hasCover: boolean;
  onClose: () => void;
  onConfirm: () => void;
  onGoToLocale: (locale: NewsFormLocale) => void;
};

export function NewsPublishChecklistDialog({
  open,
  values,
  hasCover,
  onClose,
  onConfirm,
  onGoToLocale,
}: NewsPublishChecklistDialogProps) {
  const t = useTranslations('news');
  const scores = localeCompleteness(values, hasCover);
  const allReady = NEWS_LOCALES.every((loc) => scores[loc]);

  return (
    <Modal
      open={open}
      title={t('checklist.title')}
      description={t('checklist.description')}
      onClose={onClose}
      footer={
        <div className={styles.footer}>
          <Button variant="outline" onClick={onClose}>
            {t('actions.back')}
          </Button>
          <Button onClick={onConfirm} disabled={!allReady}>
            {t('checklist.confirmPublish')}
          </Button>
        </div>
      }
    >
      <div className={styles.locales}>
        {NEWS_LOCALES.map((loc) => {
          const items = localeChecklist(values, loc, hasCover);
          const ready = scores[loc];
          return (
            <section key={loc} className={styles.localeBlock}>
              <header className={styles.localeHeader}>
                <span className={ready ? styles.localeReady : styles.localeIncomplete}>
                  {loc.toUpperCase()}
                </span>
                {!ready ? (
                  <Button type="button" variant="ghost" size="sm" onClick={() => onGoToLocale(loc)}>
                    {t('checklist.goToLocale', { locale: loc.toUpperCase() })}
                  </Button>
                ) : null}
              </header>
              <ul className={styles.items}>
                {items.map(({ item, ok }) => (
                  <li key={item} className={ok ? styles.itemOk : styles.itemMissing}>
                    {t(`checklist.${item}Field`)}
                  </li>
                ))}
              </ul>
            </section>
          );
        })}
      </div>
      {allReady ? <p className={styles.allReady}>{t('checklist.allReady')}</p> : null}
    </Modal>
  );
}
