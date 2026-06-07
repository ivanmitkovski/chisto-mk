'use client';

import { useCallback, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import type { BroadcastCampaign, BroadcastCampaignFormValues } from '../types';
import { validateBroadcastForm } from '../lib/broadcast-campaign-policy';
import {
  cancelBroadcastCampaign,
  createBroadcastCampaign,
  deleteBroadcastCampaign,
  listBroadcastCampaignsClient,
  sendBroadcastCampaign,
  updateBroadcastCampaign,
} from '../data/broadcasts-adapter-client';

type UseBroadcastCampaignMutationsOptions = {
  onCampaignsChange: (updater: (current: BroadcastCampaign[]) => BroadcastCampaign[]) => void;
};

export function useBroadcastCampaignMutations({ onCampaignsChange }: UseBroadcastCampaignMutationsOptions) {
  const t = useTranslations('broadcasts');
  const [busy, setBusy] = useState(false);
  const { showToast } = useToast();
  const [deleteTarget, setDeleteTargetState] = useState<BroadcastCampaign | null>(null);
  const [sendTarget, setSendTargetState] = useState<BroadcastCampaign | null>(null);
  const [cancelTarget, setCancelTargetState] = useState<BroadcastCampaign | null>(null);
  const sendIdempotencyKeyRef = useRef<string | null>(null);

  const setSendTarget = useCallback((campaign: BroadcastCampaign | null) => {
    sendIdempotencyKeyRef.current = campaign ? crypto.randomUUID() : null;
    setSendTargetState(campaign);
  }, []);

  const setDeleteTarget = useCallback((campaign: BroadcastCampaign | null) => {
    setDeleteTargetState(campaign);
  }, []);

  const setCancelTarget = useCallback((campaign: BroadcastCampaign | null) => {
    setCancelTargetState(campaign);
  }, []);

  const refreshCampaigns = useCallback(async () => {
    const refreshed = await listBroadcastCampaignsClient();
    onCampaignsChange(() => refreshed);
  }, [onCampaignsChange]);

  const run = useCallback(async (action: () => Promise<void>) => {
    setBusy(true);
    try {
      await action();
    } finally {
      setBusy(false);
    }
  }, []);

  const createCampaign = useCallback(
    async (values: BroadcastCampaignFormValues, parsedUserIds: string[]): Promise<boolean> => {
      const validationError = validateBroadcastForm({
        title: values.title,
        body: values.body,
        audience: values.audience,
        audienceUserIds: parsedUserIds,
        deeplink: values.deeplink,
        scheduledAt: values.scheduledAt,
      });
      if (validationError) {
        showToast({
          tone: 'warning',
          title: t('toast.validationTitle'),
          message: t(`validation.${validationError}`),
        });
        return false;
      }

      setBusy(true);
      try {
        await createBroadcastCampaign(values);
        await refreshCampaigns();
        showToast({
          tone: 'success',
          title: t('toast.draftCreatedTitle'),
          message: t('toast.draftCreatedMessage'),
        });
        return true;
      } catch (error) {
        showToast({
          tone: 'warning',
          title: t('toast.createFailedTitle'),
          message: error instanceof Error ? error.message : t('toast.createFailedMessage'),
        });
        return false;
      } finally {
        setBusy(false);
      }
    },
    [refreshCampaigns, showToast, t],
  );

  const updateCampaign = useCallback(
    async (id: string, values: BroadcastCampaignFormValues, parsedUserIds: string[]): Promise<boolean> => {
      const validationError = validateBroadcastForm({
        title: values.title,
        body: values.body,
        audience: values.audience,
        audienceUserIds: parsedUserIds,
        deeplink: values.deeplink,
        scheduledAt: values.scheduledAt,
      });
      if (validationError) {
        showToast({
          tone: 'warning',
          title: t('toast.validationTitle'),
          message: t(`validation.${validationError}`),
        });
        return false;
      }

      setBusy(true);
      try {
        await updateBroadcastCampaign(id, values);
        await refreshCampaigns();
        showToast({
          tone: 'success',
          title: t('toast.savedTitle'),
          message: t('toast.savedMessage'),
        });
        return true;
      } catch (error) {
        showToast({
          tone: 'warning',
          title: t('toast.updateFailedTitle'),
          message: error instanceof Error ? error.message : t('toast.updateFailedMessage'),
        });
        return false;
      } finally {
        setBusy(false);
      }
    },
    [refreshCampaigns, showToast, t],
  );

  const confirmSend = useCallback(async () => {
    if (!sendTarget) return;
    const id = sendTarget.id;
    await run(async () => {
      try {
        const result = await sendBroadcastCampaign(id, sendIdempotencyKeyRef.current ?? undefined);
        await refreshCampaigns();
        showToast({
          tone: 'success',
          title: t('toast.broadcastSentTitle'),
          message: t('toast.broadcastSentMessage', {
            sentCount: result.sentCount,
            failedSuffix: result.failedCount
              ? t('toast.broadcastSentFailedSuffix', { failedCount: result.failedCount })
              : '',
          }),
        });
        setSendTarget(null);
        sendIdempotencyKeyRef.current = null;
      } catch (error) {
        showToast({
          tone: 'warning',
          title: t('toast.sendFailedTitle'),
          message: error instanceof Error ? error.message : t('toast.sendFailedMessage'),
        });
      }
    });
  }, [refreshCampaigns, run, sendTarget, showToast, t]);

  const confirmCancel = useCallback(async () => {
    if (!cancelTarget) return;
    const id = cancelTarget.id;
    await run(async () => {
      try {
        await cancelBroadcastCampaign(id);
        await refreshCampaigns();
        showToast({
          tone: 'success',
          title: t('toast.cancelledTitle'),
          message: t('toast.cancelledMessage'),
        });
        setCancelTarget(null);
      } catch (error) {
        showToast({
          tone: 'warning',
          title: t('toast.cancelFailedTitle'),
          message: error instanceof Error ? error.message : t('toast.cancelFailedMessage'),
        });
      }
    });
  }, [cancelTarget, refreshCampaigns, run, showToast, t]);

  const cancelCampaign = useCallback(
    (campaign: BroadcastCampaign) => {
      setCancelTarget(campaign);
    },
    [],
  );

  const confirmDelete = useCallback(async () => {
    if (!deleteTarget) return;
    const id = deleteTarget.id;
    await run(async () => {
      try {
        await deleteBroadcastCampaign(id);
        await refreshCampaigns();
        showToast({
          tone: 'success',
          title: t('toast.deletedTitle'),
          message: t('toast.deletedMessage'),
        });
        setDeleteTarget(null);
      } catch (error) {
        showToast({
          tone: 'warning',
          title: t('toast.deleteFailedTitle'),
          message: error instanceof Error ? error.message : t('toast.deleteFailedMessage'),
        });
      }
    });
  }, [deleteTarget, refreshCampaigns, run, showToast, t]);

  return {
    busy,
    deleteTarget,
    setDeleteTarget,
    cancelTarget,
    setCancelTarget,
    sendTarget,
    setSendTarget,
    createCampaign,
    updateCampaign,
    confirmSend,
    confirmCancel,
    cancelCampaign,
    confirmDelete,
  };
}
