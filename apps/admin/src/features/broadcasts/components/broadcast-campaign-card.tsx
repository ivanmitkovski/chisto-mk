'use client';

import { useTranslations } from 'next-intl';
import { Badge, Button, Icon } from '@/components/ui';
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
    <article className={[styles.row, isEditing ? styles.editing : ''].filter(Boolean).join(' ')}>
      <div className={styles.header}>
        <div className={styles.titleGroup}>
          <h3 className={styles.title}>{campaign.title}</h3>
          <Badge tone={campaign.status === 'sent' ? 'success' : campaign.status === 'cancelled' ? 'neutral' : 'info'}>
            {statusLabel}
          </Badge>
        </div>
        <Can permission="notifications:broadcast">
          <div className={styles.actions}>
            {isBroadcastEditable(campaign.status) ? (
              <Button
                variant="icon"
                size="sm"
                className={styles.actionBtn}
                disabled={busy}
                aria-label={t('actions.editAria', { title: campaign.title })}
                title={t('actions.edit')}
                onClick={() => onEdit(campaign)}
              >
                <Icon name="document-text" size={14} aria-hidden />
              </Button>
            ) : null}
            {isBroadcastSendable(campaign) ? (
              <Button
                variant="icon"
                size="sm"
                className={styles.actionBtn}
                disabled={busy}
                aria-label={t('actions.sendAria', { title: campaign.title })}
                title={t('sendNow')}
                onClick={() => onSend(campaign)}
              >
                <Icon name="document-forward" size={14} aria-hidden />
              </Button>
            ) : null}
            {isBroadcastDeletable(campaign.status) ? (
              <Button
                variant="icon"
                size="sm"
                className={`${styles.actionBtn} ${styles.actionBtnDanger}`}
                disabled={busy}
                aria-label={t('actions.deleteAria', { title: campaign.title })}
                title={tCommon('delete')}
                onClick={() => onDelete(campaign)}
              >
                <Icon name="trash" size={14} aria-hidden />
              </Button>
            ) : null}
            {isBroadcastCancellable(campaign.status) ? (
              <Button
                variant="outline"
                size="sm"
                className={styles.cancelBtn}
                disabled={busy}
                aria-label={t('actions.cancelAria', { title: campaign.title })}
                onClick={() => onCancel(campaign)}
              >
                {tCommon('cancel')}
              </Button>
            ) : null}
          </div>
        </Can>
      </div>
      <p className={styles.body}>{campaign.body}</p>
      <p className={styles.meta}>
        {t('card.audienceLabel', { audience: audienceLabel })}
        {campaign.audienceUserIds?.length
          ? ` · ${t('card.selectedUsers', { count: campaign.audienceUserIds.length })}`
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
    </article>
  );
}
