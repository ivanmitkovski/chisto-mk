'use client';

import { useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { ConfirmDialog, PageHeader, Pagination, StickyTableWrap } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { BroadcastCampaignForm } from './broadcast-campaign-form';
import { BroadcastCampaignList } from './broadcast-campaign-list';
import { useBroadcastCampaignForm } from '../hooks/use-broadcast-campaign-form';
import { useBroadcastCampaignMutations } from '../hooks/use-broadcast-campaign-mutations';
import { formatAudiencePreview } from '../lib/broadcast-campaign-policy';
import type { BroadcastCampaign } from '../types';
import { audienceTranslationKey } from '../config/broadcast-audience-options';
import styles from './broadcasts-workspace.module.css';

const CAMPAIGNS_PAGE_SIZE = 10;

export function BroadcastsWorkspace({ initialCampaigns }: { initialCampaigns: BroadcastCampaign[] }) {
  const t = useTranslations('broadcasts');
  const tCommon = useTranslations('common');
  const [campaigns, setCampaigns] = useState(initialCampaigns);
  const [listPage, setListPage] = useState(1);
  const [cancelEditOpen, setCancelEditOpen] = useState(false);
  const form = useBroadcastCampaignForm();
  const mutations = useBroadcastCampaignMutations({ onCampaignsChange: setCampaigns });

  const totalPages = Math.max(1, Math.ceil(campaigns.length / CAMPAIGNS_PAGE_SIZE));
  const pagedCampaigns = useMemo(() => {
    const start = (listPage - 1) * CAMPAIGNS_PAGE_SIZE;
    return campaigns.slice(start, start + CAMPAIGNS_PAGE_SIZE);
  }, [campaigns, listPage]);

  function audiencePreview(campaign: Pick<BroadcastCampaign, 'audience' | 'audienceUserIds'>) {
    return formatAudiencePreview(campaign, {
      audienceLabel: (audience) => t(`audience.${audienceTranslationKey(audience)}`),
      recipientCap: (label) => t('audiencePreview.recipientCap', { label }),
      userIdCount: (label, count) =>
        count === 1
          ? t('audiencePreview.userIdCount', { label, count })
          : t('audiencePreview.userIdCountPlural', { label, count }),
    });
  }

  async function handleSubmit() {
    if (form.mode === 'create') {
      const ok = await mutations.createCampaign(form.values, form.parsedUserIds);
      if (ok) form.resetForm();
      return;
    }
    if (!form.editingId) return;
    const ok = await mutations.updateCampaign(form.editingId, form.values, form.parsedUserIds);
    if (ok) form.resetForm();
  }

  function handleEdit(campaign: BroadcastCampaign) {
    form.startEdit(campaign);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function requestCancelEdit() {
    if (form.isDirty) {
      setCancelEditOpen(true);
      return;
    }
    form.startCreate();
  }

  return (
    <div className={styles.stack}>
      <PageHeader title={t('pageTitle')} description={t('description')} />
      <Can permission="notifications:broadcast">
        <BroadcastCampaignForm
          mode={form.mode}
          values={form.values}
          busy={mutations.busy}
          onChange={form.updateField}
          onSubmit={() => void handleSubmit()}
          {...(form.mode === 'edit' ? { onCancel: requestCancelEdit } : {})}
        />
      </Can>
      <StickyTableWrap className={styles.campaignsTableArea}>
        <BroadcastCampaignList
          campaigns={pagedCampaigns}
          busy={mutations.busy}
          editingId={form.editingId}
          onEdit={handleEdit}
          onSend={(campaign) => mutations.setSendTarget(campaign)}
          onCancel={(campaign) => mutations.cancelCampaign(campaign)}
          onDelete={mutations.setDeleteTarget}
        />
        {campaigns.length > CAMPAIGNS_PAGE_SIZE ? (
          <div className={styles.listPagination}>
            <Pagination
              totalPages={totalPages}
              currentPage={listPage}
              onPageChange={setListPage}
            />
          </div>
        ) : null}
      </StickyTableWrap>
      <ConfirmDialog
        open={mutations.sendTarget != null}
        title={t('confirmSendTitle')}
        tone="danger"
        description={
          mutations.sendTarget
            ? t('confirmSendDescription', {
                title: mutations.sendTarget.title,
                audience: audiencePreview(mutations.sendTarget),
              })
            : ''
        }
        confirmLabel={t('sendNow')}
        {...(mutations.sendTarget?.audience === 'all'
          ? { confirmPhrase: t('confirmSendPhrase') }
          : {})}
        isLoading={mutations.busy}
        onConfirm={() => void mutations.confirmSend()}
        onClose={() => mutations.setSendTarget(null)}
      />
      <ConfirmDialog
        open={mutations.cancelTarget != null}
        title={t('confirmCancelTitle')}
        tone="danger"
        description={
          mutations.cancelTarget
            ? t('confirmCancelDescription', { title: mutations.cancelTarget.title })
            : ''
        }
        confirmLabel={tCommon('cancel')}
        isLoading={mutations.busy}
        onConfirm={() => void mutations.confirmCancel()}
        onClose={() => mutations.setCancelTarget(null)}
      />
      <ConfirmDialog
        open={mutations.deleteTarget != null}
        title={t('confirmDeleteTitle')}
        tone="danger"
        description={
          mutations.deleteTarget
            ? t('confirmDeleteDescription', { title: mutations.deleteTarget.title })
            : ''
        }
        confirmLabel={tCommon('delete')}
        isLoading={mutations.busy}
        onConfirm={() => void mutations.confirmDelete()}
        onClose={() => mutations.setDeleteTarget(null)}
      />
      <ConfirmDialog
        open={cancelEditOpen}
        title={t('confirmDiscardEditTitle')}
        description={t('confirmDiscardEditDescription')}
        tone="danger"
        confirmLabel={t('form.cancelEdit')}
        onConfirm={() => {
          setCancelEditOpen(false);
          form.startCreate();
        }}
        onClose={() => setCancelEditOpen(false)}
      />
    </div>
  );
}
