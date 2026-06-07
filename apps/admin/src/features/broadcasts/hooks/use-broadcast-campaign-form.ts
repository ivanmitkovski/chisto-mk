'use client';

import { useCallback, useMemo, useState } from 'react';
import type { BroadcastCampaign, BroadcastCampaignFormValues, BroadcastFormMode } from '../types';
import { formatAudienceUserIds, toDatetimeLocalValue } from '../lib/broadcast-campaign-policy';

const EMPTY_FORM: BroadcastCampaignFormValues = {
  title: '',
  body: '',
  audience: 'all',
  audienceUserIds: '',
  deeplink: '',
  scheduledAt: '',
};

export function useBroadcastCampaignForm() {
  const [mode, setMode] = useState<BroadcastFormMode>('create');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [values, setValues] = useState<BroadcastCampaignFormValues>(EMPTY_FORM);
  const [baseline, setBaseline] = useState<BroadcastCampaignFormValues>(EMPTY_FORM);

  const parsedUserIds = useMemo(
    () =>
      values.audienceUserIds
        .split(/[\s,]+/)
        .map((id) => id.trim())
        .filter(Boolean),
    [values.audienceUserIds],
  );

  const isDirty = useMemo(
    () => JSON.stringify(values) !== JSON.stringify(baseline),
    [baseline, values],
  );

  const resetForm = useCallback(() => {
    setMode('create');
    setEditingId(null);
    setValues(EMPTY_FORM);
    setBaseline(EMPTY_FORM);
  }, []);

  const startCreate = useCallback(() => {
    setMode('create');
    setEditingId(null);
    setValues(EMPTY_FORM);
    setBaseline(EMPTY_FORM);
  }, []);

  const startEdit = useCallback((campaign: BroadcastCampaign) => {
    const nextValues: BroadcastCampaignFormValues = {
      title: campaign.title,
      body: campaign.body,
      audience: campaign.audience === 'active' || campaign.audience === 'users' ? campaign.audience : 'all',
      audienceUserIds: formatAudienceUserIds(campaign.audienceUserIds),
      deeplink: campaign.deeplink ?? '',
      scheduledAt: toDatetimeLocalValue(campaign.scheduledAt),
    };
    setMode('edit');
    setEditingId(campaign.id);
    setValues(nextValues);
    setBaseline(nextValues);
  }, []);

  const updateField = useCallback(<K extends keyof BroadcastCampaignFormValues>(key: K, value: BroadcastCampaignFormValues[K]) => {
    setValues((current) => ({ ...current, [key]: value }));
  }, []);

  return {
    mode,
    editingId,
    values,
    parsedUserIds,
    isDirty,
    resetForm,
    startCreate,
    startEdit,
    updateField,
  };
}
