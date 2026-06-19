'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { ConfirmDialog, PageHeader, Pagination } from '@/components/ui';
import { Can } from '@/lib/auth/rbac';
import { previewBroadcastAudience } from '../data/broadcast-audience-api';
import { BroadcastCampaignForm } from './broadcast-campaign-form';
import { BroadcastCampaignList } from './broadcast-campaign-list';
import { useBroadcastCampaignForm } from '../hooks/use-broadcast-campaign-form';
import { useBroadcastCampaignMutations } from '../hooks/use-broadcast-campaign-mutations';
import {
  filterCampaignsByStatus,
  formatAudiencePreview,
  type BroadcastStatusFilter,
} from '../lib/broadcast-campaign-policy';
import type { BroadcastCampaign } from '../types';
import { BROADCAST_PREFILL_STORAGE_KEY } from '../types';
import { audienceTranslationKey } from '../config/broadcast-audience-options';
import styles from './broadcasts-workspace.module.css';

const CAMPAIGNS_PAGE_SIZE = 10;

const STATUS_FILTERS: BroadcastStatusFilter[] = ['all', 'draft', 'scheduled', 'sent', 'cancelled'];

export function BroadcastsWorkspace({ initialCampaigns }: { initialCampaigns: BroadcastCampaign[] }) {
  const t = useTranslations('broadcasts');
  const tCommon = useTranslations('common');
  const searchParams = useSearchParams();
  const listPanelRef = useRef<HTMLDivElement>(null);
  const [campaigns, setCampaigns] = useState(initialCampaigns);
  const [statusFilter, setStatusFilter] = useState<BroadcastStatusFilter>('all');
  const [listPage, setListPage] = useState(1);
  const [cancelEditOpen, setCancelEditOpen] = useState(false);
  const [sendRecipientCount, setSendRecipientCount] = useState<number | null>(null);
  const form = useBroadcastCampaignForm();
  const mutations = useBroadcastCampaignMutations({ onCampaignsChange: setCampaigns });

  const filteredCampaigns = useMemo(
    () => filterCampaignsByStatus(campaigns, statusFilter),
    [campaigns, statusFilter],
  );

  const totalPages = Math.max(1, Math.ceil(filteredCampaigns.length / CAMPAIGNS_PAGE_SIZE));
  const pagedCampaigns = useMemo(() => {
    const start = (listPage - 1) * CAMPAIGNS_PAGE_SIZE;
    return filteredCampaigns.slice(start, start + CAMPAIGNS_PAGE_SIZE);
  }, [filteredCampaigns, listPage]);

  useEffect(() => {
    setListPage(1);
  }, [statusFilter]);

  useEffect(() => {
    setListPage((current) => Math.min(current, totalPages));
  }, [totalPages]);

  useEffect(() => {
    const audience = searchParams.get('audience');
    if (audience !== 'users') return;

    const prefillStorage = searchParams.get('prefill');
    const userIdsParam = searchParams.get('userIds');

    void (async () => {
      if (prefillStorage === 'storage' && typeof window !== 'undefined') {
        const raw = window.sessionStorage.getItem(BROADCAST_PREFILL_STORAGE_KEY);
        if (!raw) return;
        try {
          const userIds = JSON.parse(raw) as string[];
          window.sessionStorage.removeItem(BROADCAST_PREFILL_STORAGE_KEY);
          await form.prefillUsers(userIds);
        } catch {
          // ignore malformed prefill payload
        }
        return;
      }

      if (userIdsParam) {
        const userIds = userIdsParam.split(',').map((id) => id.trim()).filter(Boolean);
        if (userIds.length > 0) {
          await form.prefillUsers(userIds);
        }
      }
    })();
  }, [form, searchParams]);

  function audiencePreview(campaign: Pick<BroadcastCampaign, 'audience' | 'audienceUserIds'>) {
    return formatAudiencePreview(campaign, {
      audienceLabel: (audience) => t(`audience.${audienceTranslationKey(audience)}`),
      recipientCap: (label) => t('audiencePreview.recipientCap', { label }),
      userCount: (label, count) => t('audiencePreview.userCount', { label, count }),
    });
  }

  function handlePageChange(page: number) {
    setListPage(page);
    window.requestAnimationFrame(() => {
      listPanelRef.current?.scrollIntoView({ block: 'nearest' });
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
    void form.startEdit(campaign);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function requestCancelEdit() {
    if (form.isDirty) {
      setCancelEditOpen(true);
      return;
    }
    form.startCreate();
  }

  async function handleSend(campaign: BroadcastCampaign) {
    try {
      const preview = await previewBroadcastAudience({
        audience: campaign.audience as BroadcastCampaign['audience'],
        audienceUserIds: campaign.audienceUserIds,
      });
      setSendRecipientCount(preview.recipientCount);
    } catch {
      setSendRecipientCount(null);
    }
    mutations.setSendTarget(campaign);
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
          onSelectedUsersChange={form.setSelectedAudienceUsers}
          onSubmit={() => void handleSubmit()}
          {...(form.mode === 'edit' ? { onCancel: requestCancelEdit } : {})}
        />
      </Can>
      <div ref={listPanelRef} className={styles.listPanel}>
        <div className={styles.listToolbar}>
          <div className={styles.filtersRow} role="tablist" aria-label={t('filters.statusLabel')}>
            {STATUS_FILTERS.map((filter) => (
              <button
                key={filter}
                type="button"
                role="tab"
                aria-selected={statusFilter === filter}
                className={statusFilter === filter ? styles.filterActive : styles.filterButton}
                onClick={() => setStatusFilter(filter)}
              >
                {filter === 'all' ? t('filters.all') : t(`status.${filter}`)}
              </button>
            ))}
          </div>
        </div>
        <BroadcastCampaignList
          campaigns={pagedCampaigns}
          busy={mutations.busy}
          editingId={form.editingId}
          emptyMessage={statusFilter === 'all' ? t('empty') : t('emptyFiltered')}
          onEdit={handleEdit}
          onSend={(campaign) => void handleSend(campaign)}
          onCancel={(campaign) => mutations.cancelCampaign(campaign)}
          onDelete={mutations.setDeleteTarget}
        />
        <div className={styles.listFooter}>
          <p className={styles.meta}>
            {t('list.campaignsCount', { count: filteredCampaigns.length, page: listPage })}
          </p>
          {totalPages > 1 ? (
            <div className={styles.listPagination}>
              <Pagination
                totalPages={totalPages}
                currentPage={listPage}
                onPageChange={handlePageChange}
              />
            </div>
          ) : null}
        </div>
      </div>
      <ConfirmDialog
        open={mutations.sendTarget != null}
        title={t('confirmSendTitle')}
        tone="danger"
        description={
          mutations.sendTarget
            ? t('confirmSendDescription', {
                title: mutations.sendTarget.title,
                audience: audiencePreview(mutations.sendTarget),
                count: sendRecipientCount ?? '—',
              })
            : ''
        }
        confirmLabel={t('sendNow')}
        {...(mutations.sendTarget?.audience === 'all'
          ? { confirmPhrase: t('confirmSendPhrase') }
          : {})}
        isLoading={mutations.busy}
        onConfirm={() => void mutations.confirmSend()}
        onClose={() => {
          mutations.setSendTarget(null);
          setSendRecipientCount(null);
        }}
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
