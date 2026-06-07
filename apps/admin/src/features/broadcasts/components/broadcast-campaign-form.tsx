'use client';

import { useTranslations } from 'next-intl';
import { Button, Card, Input } from '@/components/ui';
import {
  audienceTranslationKey,
  BROADCAST_AUDIENCE_VALUES,
} from '../config/broadcast-audience-options';
import type { BroadcastCampaignFormValues, BroadcastFormMode } from '../types';
import styles from './broadcast-campaign-form.module.css';

type BroadcastCampaignFormProps = {
  mode: BroadcastFormMode;
  values: BroadcastCampaignFormValues;
  busy: boolean;
  onChange: <K extends keyof BroadcastCampaignFormValues>(key: K, value: BroadcastCampaignFormValues[K]) => void;
  onSubmit: () => void;
  onCancel?: () => void;
};

export function BroadcastCampaignForm({
  mode,
  values,
  busy,
  onChange,
  onSubmit,
  onCancel,
}: BroadcastCampaignFormProps) {
  const t = useTranslations('broadcasts');
  const tCommon = useTranslations('common');

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
        <div className={styles.audienceRow}>
          <label htmlFor="broadcast-audience">{t('form.audience')}</label>
          <select
            id="broadcast-audience"
            className={styles.audienceSelect}
            value={values.audience}
            onChange={(e) => onChange('audience', e.target.value as BroadcastCampaignFormValues['audience'])}
          >
            {BROADCAST_AUDIENCE_VALUES.map((value) => (
              <option key={value} value={value}>
                {t(`audience.${audienceTranslationKey(value)}`)}
              </option>
            ))}
          </select>
        </div>
        {values.audience === 'users' ? (
          <Input
            label={t('form.userIds')}
            value={values.audienceUserIds}
            onChange={(e) => onChange('audienceUserIds', e.target.value)}
          />
        ) : null}
        <Input
          label={t('form.schedule')}
          type="datetime-local"
          value={values.scheduledAt}
          onChange={(e) => onChange('scheduledAt', e.target.value)}
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
