'use client';

import { useCallback, useMemo, useState } from 'react';
import type { BroadcastCampaign, BroadcastCampaignFormValues, BroadcastFormMode, BroadcastAudienceUser } from '../types';
import { toDatetimeLocalValue } from '../lib/broadcast-campaign-policy';
import { formatBroadcastUserLabel } from '../lib/format-user-display-label';
import { lookupBroadcastAudienceUsers } from '../data/broadcast-audience-api';

const EMPTY_FORM: BroadcastCampaignFormValues = {
  title: '',
  body: '',
  audience: 'all',
  selectedAudienceUsers: [],
  deeplink: '',
  scheduledAt: '',
};

export function useBroadcastCampaignForm() {
  const [mode, setMode] = useState<BroadcastFormMode>('create');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [values, setValues] = useState<BroadcastCampaignFormValues>(EMPTY_FORM);
  const [baseline, setBaseline] = useState<BroadcastCampaignFormValues>(EMPTY_FORM);

  const parsedUserIds = useMemo(
    () => values.selectedAudienceUsers.map((user) => user.id),
    [values.selectedAudienceUsers],
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

  const hydrateSelectedUsers = useCallback(async (userIds: string[]) => {
    if (userIds.length === 0) {
      return [] as BroadcastAudienceUser[];
    }
    const { users } = await lookupBroadcastAudienceUsers(userIds);
    const byId = new Map(users.map((user) => [user.id, user]));
    return userIds.map((id) => {
      const user = byId.get(id);
      return {
        id,
        label: user ? formatBroadcastUserLabel(user) : id,
      };
    });
  }, []);

  const startEdit = useCallback(
    async (campaign: BroadcastCampaign) => {
      const userIds = campaign.audienceUserIds ?? [];
      const selectedAudienceUsers =
        campaign.audience === 'users' && userIds.length > 0
          ? await hydrateSelectedUsers(userIds)
          : [];

      const nextValues: BroadcastCampaignFormValues = {
        title: campaign.title,
        body: campaign.body,
        audience: campaign.audience === 'active' || campaign.audience === 'users' ? campaign.audience : 'all',
        selectedAudienceUsers,
        deeplink: campaign.deeplink ?? '',
        scheduledAt: toDatetimeLocalValue(campaign.scheduledAt),
      };
      setMode('edit');
      setEditingId(campaign.id);
      setValues(nextValues);
      setBaseline(nextValues);
    },
    [hydrateSelectedUsers],
  );

  const prefillUsers = useCallback(
    async (userIds: string[]) => {
      const selectedAudienceUsers = await hydrateSelectedUsers(userIds);
      setMode('create');
      setEditingId(null);
      setValues({
        ...EMPTY_FORM,
        audience: 'users',
        selectedAudienceUsers,
      });
      setBaseline(EMPTY_FORM);
    },
    [hydrateSelectedUsers],
  );

  const updateField = useCallback(<K extends keyof BroadcastCampaignFormValues>(key: K, value: BroadcastCampaignFormValues[K]) => {
    setValues((current) => ({ ...current, [key]: value }));
  }, []);

  const setSelectedAudienceUsers = useCallback((users: BroadcastAudienceUser[]) => {
    setValues((current) => ({ ...current, selectedAudienceUsers: users }));
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
    prefillUsers,
    updateField,
    setSelectedAudienceUsers,
  };
}
