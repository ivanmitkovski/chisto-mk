'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Button, Checkbox, Icon } from '@/components/ui';
import { useCreateCleanupEventForm } from '@/features/events/hooks/use-create-cleanup-event-form';
import { CreateEventSitePreviewPanel, type CreateEventSitePreview } from './create-event-site-preview';
import { CleanupEventFormFields } from './cleanup-event-form-fields';
import { DuplicateEventModal } from './duplicate-event-modal';
import styles from './create-event-form.module.css';

type CreateEventFormProps = {
  siteId: string;
  sitePreview: CreateEventSitePreview;
};

export function CreateEventForm({ siteId, sitePreview }: CreateEventFormProps) {
  const form = useCreateCleanupEventForm(siteId);
  const t = useTranslations('events');
  const tCommon = useTranslations('common');

  return (
    <div className={styles.layout}>
      <Link href="/dashboard/events" className={styles.backLink}>
        <Icon name="chevron-left" size={16} />
        {t('create.backToEvents')}
      </Link>

      <CreateEventSitePreviewPanel site={sitePreview} />

      <section className={styles.sectionCard}>
        <span className={styles.sectionLabel}>{t('create.newCleanupEvent')}</span>
        <p className={styles.hint}>
          {t('create.hint', { siteId })}{' '}
          <Link href={`/dashboard/sites/${siteId}`} className={styles.siteLink}>
            {t('create.viewSite')}
          </Link>
        </p>
        <div className={styles.form}>
          <CleanupEventFormFields
            idPrefix="create-event"
            values={form.formValues}
            fieldErrors={form.fieldErrors}
            recurrenceLabel={t('form.recurrenceLabel')}
            recurrencePlaceholder={t('form.recurrencePlaceholder')}
            recurrenceHint={t('form.recurrenceHint')}
            participantLabel={t('form.participantCount')}
            scheduleConflictHint={form.scheduleConflictHint}
            scheduleConflictChecking={form.scheduleConflictChecking}
            onFieldChange={form.handleFormFieldChange}
            onClearFieldError={form.clearFieldError}
            beforeParticipants={
              <Checkbox
                id="create-event-pending"
                className={styles.fieldCheck}
                checked={form.createAsPending}
                onChange={(e) => form.setCreateAsPending(e.target.checked)}
                label={t('form.createAsPending')}
              />
            }
          />

          <div className={styles.actions}>
            <Button onClick={() => void form.submit()} isLoading={form.saving}>
              {t('create.createEvent')}
            </Button>
            <Link href="/dashboard/events" className={styles.cancelLink}>
              {tCommon('cancel')}
            </Link>
          </div>
        </div>
      </section>

      {form.duplicateModal ? (
        <DuplicateEventModal
          open
          conflict={form.duplicateModal}
          onClose={() => form.setDuplicateModal(null)}
        />
      ) : null}
    </div>
  );
}
