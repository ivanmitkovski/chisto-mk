'use client';

import Link from 'next/link';
import { useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, Input, PageHeader, SectionState, StickyTableWrap, useToast } from '@/components/ui';
import { useUnsavedChangesGuard } from '@/features/admin-shell/hooks/use-unsaved-changes-guard';
import { useReadOnlyUnless } from '@/lib/auth/rbac/use-read-only-unless';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import { formatAdminDate, useAdminBcp47Locale } from '@/lib/i18n';
import { parseLevelThresholds, validateGamificationConfig } from '../lib/gamification-validation';
import type { GamificationConfig, WeeklyRankingsResponse } from '../types';
import styles from './gamification-workspace.module.css';

type Tab = 'config' | 'rankings';

function shiftWeekIso(weekStartsAtIso: string, weeks: number): string {
  const date = new Date(weekStartsAtIso);
  date.setUTCDate(date.getUTCDate() + weeks * 7);
  return date.toISOString();
}

export function GamificationWorkspace({
  initialConfig,
  initialRankings,
}: {
  initialConfig: GamificationConfig;
  initialRankings: WeeklyRankingsResponse;
}) {
  const t = useTranslations('gamification');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const [tab, setTab] = useState<Tab>('config');
  const [config, setConfig] = useState(initialConfig);
  const [configBaseline, setConfigBaseline] = useState(initialConfig);
  const [rankings, setRankings] = useState(initialRankings);
  const [thresholdsText, setThresholdsText] = useState(initialConfig.levelThresholds.join(', '));
  const [thresholdsBaseline, setThresholdsBaseline] = useState(initialConfig.levelThresholds.join(', '));
  const [selectedWeek, setSelectedWeek] = useState(initialRankings.weekStartsAt);
  const [configBusy, setConfigBusy] = useState(false);
  const [rankingsBusy, setRankingsBusy] = useState(false);
  const { showToast } = useToast();
  const readOnly = useReadOnlyUnless('gamification:write');
  const configDirty =
    JSON.stringify(config.pointValues) !== JSON.stringify(configBaseline.pointValues) ||
    thresholdsText !== thresholdsBaseline;
  useUnsavedChangesGuard(tab === 'config' && configDirty);

  const validationErrorKey = useMemo(
    () => validateGamificationConfig(config, thresholdsText),
    [config, thresholdsText],
  );

  const pointKeys = Object.keys(config.pointValues).sort();
  const [draftActionKeys, setDraftActionKeys] = useState<Record<string, string>>({});

  function commitActionKeyRename(oldKey: string) {
    const draft = draftActionKeys[oldKey];
    if (draft == null) return;
    renamePointKey(oldKey, draft);
    setDraftActionKeys((current) => {
      const next = { ...current };
      delete next[oldKey];
      return next;
    });
  }

  function updatePointValue(key: string, value: number) {
    if (!Number.isFinite(value)) {
      return;
    }
    setConfig((current) => ({
      ...current,
      pointValues: { ...current.pointValues, [key]: Math.max(0, value) },
    }));
  }

  function renamePointKey(oldKey: string, nextKey: string) {
    const trimmed = nextKey.trim().toUpperCase();
    if (!trimmed || trimmed === oldKey || config.pointValues[trimmed] != null) {
      return;
    }
    setConfig((current) => {
      const next = { ...current.pointValues };
      next[trimmed] = next[oldKey] ?? 0;
      delete next[oldKey];
      return { ...current, pointValues: next };
    });
  }

  function addPointKey() {
    const base = 'NEW_ACTION';
    let key = base;
    let i = 1;
    while (config.pointValues[key] != null) {
      key = `${base}_${i++}`;
    }
    updatePointValue(key, 0);
  }

  function removePointKey(key: string) {
    setConfig((current) => {
      const next = { ...current.pointValues };
      delete next[key];
      return { ...current, pointValues: next };
    });
  }

  async function saveConfig() {
    if (validationErrorKey) {
      showToast({
        tone: 'warning',
        title: t('toast.invalidConfigTitle'),
        message: t(`validation.${validationErrorKey}`),
      });
      return;
    }

    setConfigBusy(true);
    try {
      const levelThresholds = parseLevelThresholds(thresholdsText);
      const updated = await adminBrowserFetch<GamificationConfig>('/admin/gamification/config', {
        method: 'PATCH',
        body: { ...config, levelThresholds },
      });
      setConfig(updated);
      setConfigBaseline(updated);
      setThresholdsText(updated.levelThresholds.join(', '));
      setThresholdsBaseline(updated.levelThresholds.join(', '));
      showToast({ tone: 'success', title: tCommon('saved'), message: t('toast.savedMessage') });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: t('toast.saveFailedTitle'),
        message: error instanceof Error ? error.message : t('toast.saveFailedMessage'),
      });
    } finally {
      setConfigBusy(false);
    }
  }

  async function loadRankings(weekStartsAt?: string) {
    setRankingsBusy(true);
    try {
      const search = new URLSearchParams({ limit: '50' });
      if (weekStartsAt) {
        search.set('weekStartsAt', weekStartsAt);
      }
      const next = await adminBrowserFetch<WeeklyRankingsResponse>(
        `/admin/gamification/rankings/weekly?${search.toString()}`,
      );
      setRankings(next);
      setSelectedWeek(next.weekStartsAt);
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tCommon('loadFailed'),
        message: error instanceof Error ? error.message : t('toast.loadFailedMessage'),
      });
    } finally {
      setRankingsBusy(false);
    }
  }

  const tabItems: Array<{ id: Tab; label: string }> = [
    { id: 'config', label: t('tabs.config') },
    { id: 'rankings', label: t('tabs.weeklyRankings') },
  ];

  function focusTab(id: Tab) {
    setTab(id);
    document.getElementById(`gamification-tab-${id}`)?.focus();
  }

  function handleTabKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    const currentIndex = tabItems.findIndex((item) => item.id === tab);
    if (currentIndex < 0) return;
    if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
      event.preventDefault();
      focusTab(tabItems[(currentIndex + 1) % tabItems.length]!.id);
    } else if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
      event.preventDefault();
      focusTab(tabItems[(currentIndex - 1 + tabItems.length) % tabItems.length]!.id);
    } else if (event.key === 'Home') {
      event.preventDefault();
      focusTab(tabItems[0]!.id);
    } else if (event.key === 'End') {
      event.preventDefault();
      focusTab(tabItems[tabItems.length - 1]!.id);
    }
  }

  return (
    <div className={styles.stack}>
      <PageHeader title={t('pageTitle')} description={t('description')} />
      <div
        className={styles.tabs}
        role="tablist"
        aria-label={t('tabsAria')}
        onKeyDown={handleTabKeyDown}
      >
        {tabItems.map((item) => {
          const selected = tab === item.id;
          return (
            <button
              key={item.id}
              type="button"
              role="tab"
              id={`gamification-tab-${item.id}`}
              aria-selected={selected}
              aria-controls={`gamification-panel-${item.id}`}
              tabIndex={selected ? 0 : -1}
              className={selected ? styles.tabActive : styles.tab}
              onClick={() => setTab(item.id)}
            >
              {item.label}
            </button>
          );
        })}
      </div>

      {tab === 'config' ? (
        <div id="gamification-panel-config" role="tabpanel" aria-labelledby="gamification-tab-config">
        <Card padding="md">
          <Input
            label={t('config.levelThresholds')}
            value={thresholdsText}
            readOnly={readOnly}
            onChange={(e) => setThresholdsText(e.target.value)}
          />
          {validationErrorKey ? (
            <p className={styles.validationError} role="alert">
              {t(`validation.${validationErrorKey}`)}
            </p>
          ) : null}
          <h3>{t('config.pointValues')}</h3>
          <div className={styles.pointGrid}>
            {pointKeys.map((key) => (
              <div key={key} className={styles.pointRow}>
                <Input
                  label={t('config.action')}
                  value={draftActionKeys[key] ?? key}
                  readOnly={readOnly}
                  onChange={(e) => setDraftActionKeys((current) => ({ ...current, [key]: e.target.value }))}
                  onBlur={() => commitActionKeyRename(key)}
                />
                <Input
                  label={t('config.points')}
                  type="number"
                  min={0}
                  value={String(config.pointValues[key] ?? 0)}
                  readOnly={readOnly}
                  onChange={(e) => updatePointValue(key, Number(e.target.value))}
                />
                <Can permission="gamification:write">
                  <Button variant="outline" onClick={() => removePointKey(key)}>
                    {t('config.remove')}
                  </Button>
                </Can>
              </div>
            ))}
          </div>
          <Can permission="gamification:write">
            <div className={styles.actions}>
              <Button variant="outline" onClick={addPointKey}>
                {t('config.addAction')}
              </Button>
              <Button onClick={() => void saveConfig()} disabled={configBusy || !!validationErrorKey || !configDirty}>
                {configBusy ? t('config.saving') : t('config.saveConfig')}
              </Button>
            </div>
          </Can>
        </Card>
        </div>
      ) : (
        <div id="gamification-panel-rankings" role="tabpanel" aria-labelledby="gamification-tab-rankings">
        <Card padding="md">
          <div className={styles.weekPicker}>
            <Button
              variant="outline"
              size="sm"
              disabled={rankingsBusy}
              onClick={() => void loadRankings(shiftWeekIso(selectedWeek, -1))}
            >
              {t('rankings.previousWeek')}
            </Button>
            <span>
              {t('rankings.weekRange', {
                start: formatAdminDate(rankings.weekStartsAt, locale),
                end: formatAdminDate(rankings.weekEndsAt, locale),
              })}
            </span>
            <Button
              variant="outline"
              size="sm"
              disabled={rankingsBusy}
              onClick={() => void loadRankings(shiftWeekIso(selectedWeek, 1))}
            >
              {t('rankings.nextWeek')}
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={rankingsBusy}
              onClick={() => void loadRankings()}
            >
              {t('rankings.currentWeek')}
            </Button>
          </div>
          {rankings.entries.length === 0 ? (
            <SectionState variant="empty" message={t('rankings.empty')} />
          ) : (
            <StickyTableWrap className={styles.rankingsTableWrap}>
              <table className={styles.rankingsTable}>
                <thead>
                  <tr>
                    <th>{t('rankings.columns.rank')}</th>
                    <th>{t('rankings.columns.user')}</th>
                    <th>{t('rankings.columns.email')}</th>
                    <th>{t('rankings.columns.points')}</th>
                    <th>{t('rankings.columns.leaderboard')}</th>
                  </tr>
                </thead>
                <tbody>
                  {rankings.entries.map((entry) => (
                    <tr key={entry.userId}>
                      <td>{entry.rank}</td>
                      <td>
                        <Link href={`/dashboard/users/${entry.userId}`} className={styles.userLink}>
                          {entry.displayName ?? '—'}
                        </Link>
                      </td>
                      <td>{entry.email ?? '—'}</td>
                      <td>{entry.weeklyPoints}</td>
                      <td>
                        {entry.showOnLeaderboard
                          ? t('rankings.showOnLeaderboardYes')
                          : t('rankings.showOnLeaderboardNo')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </StickyTableWrap>
          )}
        </Card>
        </div>
      )}
    </div>
  );
}
