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
  mode?: 'publish' | 'update';
  values: NewsPostFormValues;
  hasCover: boolean;
  dirty?: boolean;
  isLoading?: boolean;
  media?: NewsMediaDto[];
  onClose: () => void;
  onConfirm: () => void;
  onSaveAndConfirm?: () => void;
  onGoToLocale: (locale: NewsFormLocale) => void;
};

export function NewsPublishChecklistDialog({
  open,
  mode = 'publish',
  values,
  hasCover,
  dirty = false,
  isLoading = false,
  media = [],
  onClose,
  onConfirm,
  onSaveAndConfirm,
  onGoToLocale,
}: NewsPublishChecklistDialogProps) {
  const t = useTranslations('news');
  const scores = localeCompleteness(values, hasCover, media);
  const allReady = allLocalesPublishReady(values, hasCover, media);
  const isUpdate = mode === 'update';

  return (
    <Modal
      open={open}
      title={isUpdate ? t('checklist.titleUpdate') : t('checklist.title')}
      description={isUpdate ? t('checklist.descriptionUpdate') : t('checklist.description')}
      onClose={isLoading ? () => undefined : onClose}
      footer={
        <div className={styles.footer}>
          <Button variant="outline" onClick={onClose} disabled={isLoading}>
            {t('checklist.cancel')}
          </Button>
          {dirty && onSaveAndConfirm ? (
            <Button onClick={onSaveAndConfirm} disabled={!allReady} isLoading={isLoading}>
              {isUpdate ? t('checklist.saveAndUpdate') : t('checklist.saveAndPublish')}
            </Button>
          ) : (
            <Button onClick={onConfirm} disabled={!allReady} isLoading={isLoading}>
              {isUpdate ? t('checklist.confirmUpdate') : t('checklist.confirmPublish')}
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
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => onGoToLocale(loc)}
                    disabled={isLoading}
                  >
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
      {allReady ? (
        <p className={styles.allReady}>
          {isUpdate ? t('checklist.allReadyUpdate') : t('checklist.allReady')}
        </p>
      ) : null}
    </Modal>
  );
}
