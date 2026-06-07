'use client';

import { useTranslations } from 'next-intl';
import { Badge, Button, Card } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { audienceTranslationKey } from '../config/broadcast-audience-options';
import {
  isBroadcastCancellable,
  isBroadcastDeletable,
  isBroadcastEditable,
  isBroadcastSendable,
} from '../lib/broadcast-campaign-policy';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import type { BroadcastAudience, BroadcastCampaign } from '../types';
import styles from './broadcast-campaign-card.module.css';

type BroadcastCampaignCardProps = {
  campaign: BroadcastCampaign;
  busy: boolean;
  isEditing: boolean;
  onEdit: (campaign: BroadcastCampaign) => void;
  onSend: (campaign: BroadcastCampaign) => void;
  onCancel: (campaign: BroadcastCampaign) => void;
  onDelete: (campaign: BroadcastCampaign) => void;
};

export function BroadcastCampaignCard({
  campaign,
  busy,
  isEditing,
  onEdit,
  onSend,
  onCancel,
  onDelete,
}: BroadcastCampaignCardProps) {
  const t = useTranslations('broadcasts');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();

  const statusKey = campaign.status as 'draft' | 'scheduled' | 'sent' | 'cancelled';
  const statusLabel = t(`status.${statusKey}`);
  const audienceLabel = t(`audience.${audienceTranslationKey(campaign.audience as BroadcastAudience)}`);

  return (
    <Card padding="md" className={isEditing ? styles.editing : undefined}>
      <div className={styles.header}>
        <strong>{campaign.title}</strong>
        <Badge tone={campaign.status === 'sent' ? 'success' : campaign.status === 'cancelled' ? 'neutral' : 'info'}>
          {statusLabel}
        </Badge>
      </div>
      <p className={styles.body}>{campaign.body}</p>
      <p className={styles.meta}>
        {t('card.audienceLabel', { audience: audienceLabel })}
        {campaign.audienceUserIds?.length
          ? ` · ${t('card.userCount', { count: campaign.audienceUserIds.length })}`
          : ''}
        {campaign.scheduledAt
          ? ` · ${t('card.scheduledAt', { date: formatAdminDateTime(campaign.scheduledAt, locale) })}`
          : ''}
        {campaign.sentAt ? ` · ${t('card.sentAt', { date: formatAdminDateTime(campaign.sentAt, locale) })}` : ''}
        {campaign.updatedAt
          ? ` · ${t('card.updatedAt', { date: formatAdminDateTime(campaign.updatedAt, locale) })}`
          : ''}
      </p>
      {campaign.sentCount != null ? (
        <div className={styles.delivery}>{t('card.deliveredTo', { count: campaign.sentCount })}</div>
      ) : null}
      <Can permission="notifications:broadcast">
        <div className={styles.actions}>
          {isBroadcastEditable(campaign.status) ? (
            <Button variant="outline" disabled={busy} onClick={() => onEdit(campaign)}>
              {t('actions.edit')}
            </Button>
          ) : null}
          {isBroadcastSendable(campaign) ? (
            <Button variant="outline" disabled={busy} onClick={() => onSend(campaign)}>
              {t('sendNow')}
            </Button>
          ) : null}
          {isBroadcastCancellable(campaign.status) ? (
            <Button variant="outline" disabled={busy} onClick={() => onCancel(campaign)}>
              {tCommon('cancel')}
            </Button>
          ) : null}
          {isBroadcastDeletable(campaign.status) ? (
            <Button variant="outline" disabled={busy} className={styles.danger} onClick={() => onDelete(campaign)}>
              {tCommon('delete')}
            </Button>
          ) : null}
        </div>
      </Can>
    </Card>
  );
}
