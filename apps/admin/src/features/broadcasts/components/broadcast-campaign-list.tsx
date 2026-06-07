'use client';

import { useTranslations } from 'next-intl';
import { SectionState } from '@/components/ui';
import type { BroadcastCampaign } from '../types';
import { BroadcastCampaignCard } from './broadcast-campaign-card';
import styles from './broadcast-campaign-list.module.css';

type BroadcastCampaignListProps = {
  campaigns: BroadcastCampaign[];
  busy: boolean;
  editingId: string | null;
  onEdit: (campaign: BroadcastCampaign) => void;
  onSend: (campaign: BroadcastCampaign) => void;
  onCancel: (campaign: BroadcastCampaign) => void;
  onDelete: (campaign: BroadcastCampaign) => void;
};

export function BroadcastCampaignList({
  campaigns,
  busy,
  editingId,
  onEdit,
  onSend,
  onCancel,
  onDelete,
}: BroadcastCampaignListProps) {
  const t = useTranslations('broadcasts');

  if (campaigns.length === 0) {
    return <SectionState variant="empty" message={t('empty')} />;
  }

  return (
    <div className={styles.list}>
      {campaigns.map((campaign) => (
        <BroadcastCampaignCard
          key={campaign.id}
          campaign={campaign}
          busy={busy}
          isEditing={editingId === campaign.id}
          onEdit={onEdit}
          onSend={onSend}
          onCancel={onCancel}
          onDelete={onDelete}
        />
      ))}
    </div>
  );
}
