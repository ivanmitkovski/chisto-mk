'use client';

import { useMemo, useState } from 'react';
import { SnackState } from '@/components/ui';
import { DuplicateReportGroup, MergeDuplicateReportsResult } from '../types';

type UseDuplicatesOptions = {
  initialGroups: DuplicateReportGroup[];
  initialSelectedGroupId?: string | null;
};

function defaultSelection(groups: DuplicateReportGroup[]): Record<string, string[]> {
  const selection: Record<string, string[]> = {};
  for (const group of groups) {
    selection[group.primaryReport.id] = group.duplicateReports.map((duplicate) => duplicate.id);
  }
  return selection;
}

export function useDuplicates({ initialGroups, initialSelectedGroupId = null }: UseDuplicatesOptions) {
  const defaultSelectedGroupId =
    initialSelectedGroupId && initialGroups.some((group) => group.primaryReport.id === initialSelectedGroupId)
      ? initialSelectedGroupId
      : initialGroups[0]?.primaryReport.id ?? null;
  const [groups, setGroups] = useState<DuplicateReportGroup[]>(initialGroups);
  const [selectedGroupId, setSelectedGroupId] = useState<string | null>(defaultSelectedGroupId);
  const [selectedChildIdsByGroup, setSelectedChildIdsByGroup] = useState<Record<string, string[]>>(
    defaultSelection(initialGroups),
  );
  const [isMerging, setIsMerging] = useState(false);
  const [snack, setSnack] = useState<SnackState | null>(null);

  const selectedGroup = useMemo(
    () => groups.find((group) => group.primaryReport.id === selectedGroupId) ?? null,
    [groups, selectedGroupId],
  );

  const selectedChildIds = selectedGroup ? selectedChildIdsByGroup[selectedGroup.primaryReport.id] ?? [] : [];

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

    setSelectedChildIdsByGroup((prev) => ({
      ...prev,
      [selectedGroup.primaryReport.id]: selectedGroup.duplicateReports.map((duplicate) => duplicate.id),
    }));
  }

  async function mergeSelected(reason?: string): Promise<boolean> {
    if (!selectedGroup) {
      return false;
    }

    const mergeChildIds = selectedChildIdsByGroup[selectedGroup.primaryReport.id] ?? [];
    if (mergeChildIds.length === 0) {
      setSnack({
        tone: 'warning',
        title: 'No duplicates selected',
        message: 'Select at least one duplicate report before merging.',
      });
      return false;
    }

    setIsMerging(true);
    try {
      const res = await fetch(`/api/reports/${encodeURIComponent(selectedGroup.primaryReport.id)}/merge`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
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
          : 'Unable to merge duplicate reports right now.';

      if (!res.ok) {
        setSnack({
          tone: 'error',
          title: 'Merge failed',
          message,
        });
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
          setSelectedGroupId(nextGroups[0].primaryReport.id);
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

      setSnack({
        tone: 'success',
        title: 'Duplicates merged',
        message: `Merged ${mergeResult.mergedChildCount} duplicate report(s) into ${selectedGroup.primaryReport.reportNumber}.`,
      });
      return true;
    } catch {
      setSnack({
        tone: 'error',
        title: 'Merge failed',
        message: 'Unable to merge duplicate reports right now.',
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
    snack,
    setSelectedGroupId,
    toggleChildSelection,
    selectAllChildren,
    mergeSelected,
    clearSnack: () => setSnack(null),
  };
}
