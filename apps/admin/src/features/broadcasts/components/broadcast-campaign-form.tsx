'use client';

import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, DateTimePicker, Input, Select } from '@/components/ui';
import {
  audienceTranslationKey,
  BROADCAST_AUDIENCE_VALUES,
} from '../config/broadcast-audience-options';
import { useAudiencePreview } from '../hooks/use-audience-preview';
import type { BroadcastCampaignFormValues, BroadcastFormMode } from '../types';
import { BroadcastAudienceUserPicker } from './broadcast-audience-user-picker';
import styles from './broadcast-campaign-form.module.css';

type BroadcastCampaignFormProps = {
  mode: BroadcastFormMode;
  values: BroadcastCampaignFormValues;
  busy: boolean;
  onChange: <K extends keyof BroadcastCampaignFormValues>(key: K, value: BroadcastCampaignFormValues[K]) => void;
  onSelectedUsersChange: (users: BroadcastCampaignFormValues['selectedAudienceUsers']) => void;
  onSubmit: () => void;
  onCancel?: () => void;
};

export function BroadcastCampaignForm({
  mode,
  values,
  busy,
  onChange,
  onSelectedUsersChange,
  onSubmit,
  onCancel,
}: BroadcastCampaignFormProps) {
  const t = useTranslations('broadcasts');
  const tCommon = useTranslations('common');
  const audienceUserIds = useMemo(
    () => values.selectedAudienceUsers.map((user) => user.id),
    [values.selectedAudienceUsers],
  );
  const { preview, loading: previewLoading } = useAudiencePreview({
    audience: values.audience,
    audienceUserIds,
  });

  return (
    <Card padding="md" className={styles.card}>
      <h3 className={styles.heading}>{mode === 'create' ? t('form.newCampaign') : t('form.editCampaign')}</h3>
      <div className={styles.fields}>
        <Input label={t('form.title')} value={values.title} onChange={(e) => onChange('title', e.target.value)} />
        <label className={styles.bodyField} htmlFor="broadcast-body">
          <span className={styles.bodyLabel}>{t('form.body')}</span>
          <textarea
            id="broadcast-body"
            className={styles.bodyTextarea}
            value={values.body}
            rows={5}
            onChange={(e) => onChange('body', e.target.value)}
          />
        </label>
        <Input
          label={t('form.deeplink')}
          value={values.deeplink}
          onChange={(e) => onChange('deeplink', e.target.value)}
          placeholder="/reports/123"
        />
        <Select
          label={t('form.audience')}
          value={values.audience}
          options={BROADCAST_AUDIENCE_VALUES.map((value) => ({
            value,
            label: t(`audience.${audienceTranslationKey(value)}`),
          }))}
          onChange={(e) => onChange('audience', e.target.value as BroadcastCampaignFormValues['audience'])}
        />
        {values.audience === 'users' ? (
          <BroadcastAudienceUserPicker
            selectedUsers={values.selectedAudienceUsers}
            onChange={onSelectedUsersChange}
            disabled={busy}
          />
        ) : null}
        {preview ? (
          <p className={styles.preview} aria-live="polite">
            {previewLoading
              ? t('audiencePreview.loading')
              : preview.capped
                ? t('audiencePreview.recipientCountCapped', {
                    count: preview.recipientCount,
                    cap: preview.cap,
                  })
                : t('audiencePreview.recipientCount', { count: preview.recipientCount })}
          </p>
        ) : null}
        <DateTimePicker
          label={t('form.schedule')}
          helperText={t('form.scheduleHint')}
          value={values.scheduledAt}
          onValueChange={(next) => onChange('scheduledAt', next)}
          disabled={busy}
        />
      </div>
      <div className={styles.actions}>
        <Button
          onClick={onSubmit}
          disabled={busy || !values.title.trim() || !values.body.trim()}
          isLoading={busy}
        >
          {mode === 'create' ? t('form.saveDraft') : tCommon('saveChanges')}
        </Button>
        {mode === 'edit' && onCancel ? (
          <Button variant="outline" onClick={onCancel} disabled={busy}>
            {t('form.cancelEdit')}
          </Button>
        ) : null}
      </div>
    </Card>
  );
}
