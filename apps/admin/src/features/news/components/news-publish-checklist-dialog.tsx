'use client';

import { useTranslations } from 'next-intl';
import { Button, Modal } from '@/components/ui';
import {
  allLocalesPublishReady,
  localeCompleteness,
  localePublishChecklist,
} from '../lib/news-locale-utils';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import type { NewsMediaDto } from '../news-api-types';
import styles from './news-publish-checklist-dialog.module.css';

type NewsPublishChecklistDialogProps = {
  open: boolean;
  values: NewsPostFormValues;
  hasCover: boolean;
  dirty?: boolean;
  media?: NewsMediaDto[];
  onClose: () => void;
  onConfirm: () => void;
  onSaveAndPublish?: () => void;
  onGoToLocale: (locale: NewsFormLocale) => void;
};

export function NewsPublishChecklistDialog({
  open,
  values,
  hasCover,
  dirty = false,
  media = [],
  onClose,
  onConfirm,
  onSaveAndPublish,
  onGoToLocale,
}: NewsPublishChecklistDialogProps) {
  const t = useTranslations('news');
  const scores = localeCompleteness(values, hasCover, media);
  const allReady = allLocalesPublishReady(values, hasCover, media);

  return (
    <Modal
      open={open}
      title={t('checklist.title')}
      description={t('checklist.description')}
      onClose={onClose}
      footer={
        <div className={styles.footer}>
          <Button variant="outline" onClick={onClose}>
            {t('checklist.cancel')}
          </Button>
          {dirty && onSaveAndPublish ? (
            <Button onClick={onSaveAndPublish} disabled={!allReady}>
              {t('checklist.saveAndPublish')}
            </Button>
          ) : (
            <Button onClick={onConfirm} disabled={!allReady}>
              {t('checklist.confirmPublish')}
            </Button>
          )}
        </div>
      }
    >
      <div className={styles.locales}>
        {NEWS_LOCALES.map((loc) => {
          const items = localePublishChecklist(values, loc, hasCover, media);
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
