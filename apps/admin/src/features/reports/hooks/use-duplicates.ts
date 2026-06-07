'use client';

import { useEffect, useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useToast } from '@/components/ui';
import { getAdminCsrfHeaders } from '@/features/auth/lib/admin-auth';
import { DuplicateReportGroup, MergeDuplicateReportsResult } from '../types';

type DuplicateGroupsMeta = { page: number; limit: number; total: number };

type UseDuplicatesOptions = {
  groups: DuplicateReportGroup[];
  setGroups: React.Dispatch<React.SetStateAction<DuplicateReportGroup[]>>;
  initialSelectedGroupId?: string | null;
  pagination: DuplicateGroupsMeta;
};

function defaultSelection(groups: DuplicateReportGroup[]): Record<string, string[]> {
  const selection: Record<string, string[]> = {};
  for (const group of groups) {
    selection[group.primaryReport.id] = group.duplicateReports.map((duplicate) => duplicate.id);
  }
  return selection;
}

async function fetchDuplicateGroupsFromApi(
  page: number,
  limit: number,
): Promise<{ data: DuplicateReportGroup[]; meta: DuplicateGroupsMeta } | null> {
  try {
    const search = new URLSearchParams({ page: String(page), limit: String(limit) });
    const res = await fetch(`/api/reports/duplicates?${search.toString()}`, { credentials: 'include' });
    if (!res.ok) {
      return null;
    }
    return res.json();
  } catch {
    return null;
  }
}

function isStaleMergeConflict(status: number, body: unknown): boolean {
  if (status === 409) {
    return true;
  }
  if (status !== 400 || !body || typeof body !== 'object') {
    return false;
  }
  const code = 'code' in body && typeof body.code === 'string' ? body.code : null;
  return code === 'INVALID_DUPLICATE_SELECTION';
}

export function useDuplicates({
  groups,
  setGroups,
  initialSelectedGroupId = null,
  pagination,
}: UseDuplicatesOptions) {
  const defaultSelectedGroupId =
    initialSelectedGroupId && groups.some((group) => group.primaryReport.id === initialSelectedGroupId)
      ? initialSelectedGroupId
      : groups[0]?.primaryReport.id ?? null;
  const [selectedGroupId, setSelectedGroupId] = useState<string | null>(defaultSelectedGroupId);
  const [selectedChildIdsByGroup, setSelectedChildIdsByGroup] = useState<Record<string, string[]>>(
    defaultSelection(groups),
  );
  const [isMerging, setIsMerging] = useState(false);
  const { showToast } = useToast();
  const t = useTranslations('reports.duplicates.toast');

  const selectedGroup = useMemo(
    () => groups.find((group) => group.primaryReport.id === selectedGroupId) ?? null,
    [groups, selectedGroupId],
  );

  const selectedChildIds = selectedGroup ? selectedChildIdsByGroup[selectedGroup.primaryReport.id] ?? [] : [];

  useEffect(() => {
    if (selectedGroupId && groups.some((group) => group.primaryReport.id === selectedGroupId)) {
      return;
    }
    setSelectedGroupId(groups[0]?.primaryReport.id ?? null);
  }, [groups, selectedGroupId]);

  async function refetchGroups(): Promise<boolean> {
    const refreshed = await fetchDuplicateGroupsFromApi(pagination.page, pagination.limit);
    if (!refreshed) {
      return false;
    }

    setGroups(refreshed.data);
    setSelectedChildIdsByGroup((prev) => {
      const next = { ...prev };
      for (const group of refreshed.data) {
        if (!next[group.primaryReport.id]) {
          next[group.primaryReport.id] = group.duplicateReports.map((duplicate) => duplicate.id);
        }
      }
      return next;
    });

    if (refreshed.data.length === 0) {
      setSelectedGroupId(null);
    } else if (!refreshed.data.some((group) => group.primaryReport.id === selectedGroupId)) {
      setSelectedGroupId(refreshed.data[0]?.primaryReport.id ?? null);
    }

    return true;
  }

  function toggleChildSelection(childId: string) {
    if (!selectedGroup) {
      return;
    }

    const groupId = selectedGroup.primaryReport.id;
    setSelectedChildIdsByGroup((prev) => {
      const current = prev[groupId] ?? [];
      const next = current.includes(childId) ? current.filter((id) => id !== childId) : [...current, childId];
      return {
        ...prev,
        [groupId]: next,
      };
    });
  }

  function selectAllChildren() {
    if (!selectedGroup) {
      return;
    }

    const groupId = selectedGroup.primaryReport.id;
    const allIds = selectedGroup.duplicateReports.map((d) => d.id);

    setSelectedChildIdsByGroup((prev) => {
      const current = prev[groupId] ?? [];
      const allSelected = allIds.length > 0 && current.length === allIds.length;
      return {
        ...prev,
        [groupId]: allSelected ? [] : allIds,
      };
    });
  }

  async function mergeSelected(reason?: string): Promise<boolean> {
    if (!selectedGroup) {
      return false;
    }

    const mergeChildIds = selectedChildIdsByGroup[selectedGroup.primaryReport.id] ?? [];
    if (mergeChildIds.length === 0) {
      showToast({
        tone: 'warning',
        title: t('noSelectionTitle'),
        message: t('noSelectionMessage'),
      });
      return false;
    }

    setIsMerging(true);
    try {
      const res = await fetch(`/api/reports/${encodeURIComponent(selectedGroup.primaryReport.id)}/merge`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...getAdminCsrfHeaders() },
        credentials: 'include',
        body: JSON.stringify({
          childReportIds: mergeChildIds,
          reason: reason?.trim() ? reason.trim() : undefined,
        }),
      });

      const body = await res.json().catch(() => ({}));
      const message =
        body && typeof body.message === 'string'
          ? body.message
          : t('mergeFailedMessage');

      if (!res.ok) {
        if (isStaleMergeConflict(res.status, body)) {
          const didRefetch = await refetchGroups();
          showToast({
            tone: 'warning',
            title: t('groupChangedTitle'),
            message: didRefetch ? t('groupChangedMessage') : t('groupChangedRefreshMessage'),
          });
        } else {
          showToast({
            tone: 'error',
            title: t('mergeFailedTitle'),
            message,
          });
        }
        return false;
      }

      const mergeResult = body as MergeDuplicateReportsResult;

      setGroups((prevGroups) => {
        const nextGroups = prevGroups.flatMap((group) => {
          if (group.primaryReport.id !== selectedGroup.primaryReport.id) {
            return [group];
          }

          const remainingDuplicates = group.duplicateReports.filter(
            (duplicate) => !mergeChildIds.includes(duplicate.id),
          );

          if (remainingDuplicates.length === 0) {
            return [];
          }

          return [
            {
              ...group,
              primaryReport: {
                ...group.primaryReport,
                status: mergeResult.primaryStatus,
              },
              duplicateReports: remainingDuplicates,
              totalReports: remainingDuplicates.length + 1,
            },
          ];
        });

        if (nextGroups.length === 0) {
          setSelectedGroupId(null);
        } else if (!nextGroups.some((group) => group.primaryReport.id === selectedGroup.primaryReport.id)) {
          setSelectedGroupId(nextGroups[0]?.primaryReport.id ?? null);
        }

        return nextGroups;
      });

      setSelectedChildIdsByGroup((prev) => {
        const remaining =
          selectedGroup.duplicateReports
            .filter((duplicate) => !mergeChildIds.includes(duplicate.id))
            .map((duplicate) => duplicate.id) ?? [];

        return {
          ...prev,
          [selectedGroup.primaryReport.id]: remaining,
        };
      });

      showToast({
        tone: 'success',
        title: t('mergeSuccessTitle'),
        message: t('mergeSuccessMessage', {
          count: mergeResult.mergedChildCount,
          reportNumber: selectedGroup.primaryReport.reportNumber,
        }),
      });
      return true;
    } catch {
      showToast({
        tone: 'error',
        title: t('mergeFailedTitle'),
        message: t('mergeFailedMessage'),
      });
      return false;
    } finally {
      setIsMerging(false);
    }
  }

  return {
    groups,
    selectedGroupId,
    selectedGroup,
    selectedChildIds,
    isMerging,
    setSelectedGroupId,
    toggleChildSelection,
    selectAllChildren,
    mergeSelected,
    refetchGroups,
  };
}
