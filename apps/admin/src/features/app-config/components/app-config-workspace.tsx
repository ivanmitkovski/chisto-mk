'use client';

import { useEffect, useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Card, Checkbox, ConfirmDialog, Input, JsonEditor, PageHeader, SectionState, Select, useToast } from '@/components/ui';
import { useUnsavedChangesGuard } from '@/features/admin-shell/hooks/use-unsaved-changes-guard';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { useReadOnlyUnless } from '@/lib/auth/rbac/use-read-only-unless';
import { Can } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import type { AppConfigSnapshot, FeedRankingConfig, ReportCreditsConfig } from '../types';
import styles from './app-config-workspace.module.css';

function parseQuizJson(value: string): { ok: true; data: Record<string, unknown> } | { ok: false; error: string } {
  try {
    const parsed = JSON.parse(value) as unknown;
    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
      return { ok: false, error: 'invalidObject' };
    }
    return { ok: true, data: parsed as Record<string, unknown> };
  } catch {
    return { ok: false, error: 'invalidJson' };
  }
}

function isPositiveInt(value: number): boolean {
  return Number.isInteger(value) && value > 0;
}

function isValidTermsVersion(value: string): boolean {
  const trimmed = value.trim();
  return trimmed.length >= 1 && trimmed.length <= 32 && /^[A-Za-z0-9._-]+$/.test(trimmed);
}

export function AppConfigWorkspace({ initialSnapshot }: { initialSnapshot: AppConfigSnapshot }) {
  const t = useTranslations('appConfig');
  const tCommon = useTranslations('common');
  const [reportCredits, setReportCredits] = useServerSyncedState(initialSnapshot.reportCredits);
  const [feedRanking, setFeedRanking] = useServerSyncedState(initialSnapshot.feedRanking);
  const [termsVersion, setTermsVersion] = useServerSyncedState(initialSnapshot.termsVersion);
  const [creditsBaseline, setCreditsBaseline] = useState(initialSnapshot.reportCredits);
  const [feedBaseline, setFeedBaseline] = useState(initialSnapshot.feedRanking);
  const [termsBaseline, setTermsBaseline] = useState(initialSnapshot.termsVersion);
  const [quizLocale, setQuizLocale] = useState('en');
  const [pendingQuizLocale, setPendingQuizLocale] = useState<string | null>(null);
  const [localeConfirmOpen, setLocaleConfirmOpen] = useState(false);
  const [quizBaseline, setQuizBaseline] = useState(JSON.stringify(initialSnapshot.organizerQuiz, null, 2));
  const [quizJson, setQuizJson] = useState(JSON.stringify(initialSnapshot.organizerQuiz, null, 2));
  const [quizLocaleLoading, setQuizLocaleLoading] = useState(false);
  const [quizLoadError, setQuizLoadError] = useState<string | null>(null);
  const [experimentConfirmOpen, setExperimentConfirmOpen] = useState(false);
  const [pendingExperimentEnabled, setPendingExperimentEnabled] = useState<boolean | null>(null);
  const [busySection, setBusySection] = useState<'credits' | 'feed' | 'quiz' | 'terms' | null>(null);
  const { showToast } = useToast();

  const readOnlyAppConfig = useReadOnlyUnless('app-config:write');
  const readOnlyConfig = useReadOnlyUnless('config:write');

  const quizParse = useMemo(() => parseQuizJson(quizJson), [quizJson]);

  useEffect(() => {
    setCreditsBaseline(initialSnapshot.reportCredits);
    setFeedBaseline(initialSnapshot.feedRanking);
    setTermsBaseline(initialSnapshot.termsVersion);
  }, [initialSnapshot]);

  const creditsDirty = JSON.stringify(reportCredits) !== JSON.stringify(creditsBaseline);
  const feedDirty = JSON.stringify(feedRanking) !== JSON.stringify(feedBaseline);
  const termsDirty = termsVersion !== termsBaseline;
  const quizDirty = quizJson !== quizBaseline;

  const creditsValid =
    isPositiveInt(reportCredits.dailyCredits) &&
    isPositiveInt(reportCredits.emergencyWindowHours) &&
    isPositiveInt(reportCredits.refillIntervalHours);

  const feedValid = feedRanking.defaultVariant.trim().length > 0;
  const termsValid = isValidTermsVersion(termsVersion);

  useUnsavedChangesGuard(creditsDirty || feedDirty || termsDirty || quizDirty);

  function handleQuizLocaleChange(nextLocale: string) {
    if (nextLocale === quizLocale) return;
    if (quizDirty) {
      setPendingQuizLocale(nextLocale);
      setLocaleConfirmOpen(true);
      return;
    }
    setQuizLocale(nextLocale);
  }

  function confirmQuizLocaleChange() {
    if (pendingQuizLocale) setQuizLocale(pendingQuizLocale);
    setPendingQuizLocale(null);
    setLocaleConfirmOpen(false);
  }

  useEffect(() => {
    let cancelled = false;
    async function loadQuizForLocale() {
      setQuizLocaleLoading(true);
      setQuizLoadError(null);
      try {
        const data = await adminBrowserFetch<Record<string, unknown>>(
          `/admin/app-config/organizer-quiz?locale=${encodeURIComponent(quizLocale)}`,
        );
        if (!cancelled) {
          const next = JSON.stringify(data, null, 2);
          setQuizJson(next);
          setQuizBaseline(next);
        }
      } catch (error) {
        if (!cancelled) {
          const message = error instanceof Error ? error.message : t('organizerQuiz.loadFailedMessage');
          setQuizLoadError(message);
          showToast({
            tone: 'warning',
            title: tCommon('loadFailed'),
            message,
          });
        }
      } finally {
        if (!cancelled) setQuizLocaleLoading(false);
      }
    }
    void loadQuizForLocale();
    return () => {
      cancelled = true;
    };
  }, [quizLocale, showToast, t, tCommon]);

  async function saveReportCredits() {
    if (!creditsValid) {
      showToast({
        tone: 'warning',
        title: tCommon('validation'),
        message: t('reportCredits.invalidValuesMessage'),
      });
      return;
    }
    setBusySection('credits');
    try {
      const updated = await adminBrowserFetch<ReportCreditsConfig>('/admin/app-config/report-credits', {
        method: 'PATCH',
        body: reportCredits,
      });
      setReportCredits(updated);
      setCreditsBaseline(updated);
      showToast({ tone: 'success', title: tCommon('saved'), message: t('reportCredits.savedMessage') });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tCommon('saveFailed'),
        message: error instanceof Error ? error.message : tCommon('errorGeneric'),
      });
    } finally {
      setBusySection(null);
    }
  }

  async function saveFeedRanking() {
    if (!feedValid) {
      showToast({
        tone: 'warning',
        title: tCommon('validation'),
        message: t('feedRanking.defaultVariantRequired'),
      });
      return;
    }
    setBusySection('feed');
    try {
      const updated = await adminBrowserFetch<FeedRankingConfig>('/admin/app-config/feed-ranking', {
        method: 'PATCH',
        body: feedRanking,
      });
      setFeedRanking(updated);
      setFeedBaseline(updated);
      showToast({ tone: 'success', title: tCommon('saved'), message: t('feedRanking.savedMessage') });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tCommon('saveFailed'),
        message: error instanceof Error ? error.message : tCommon('errorGeneric'),
      });
    } finally {
      setBusySection(null);
    }
  }

  async function saveTermsVersion() {
    if (!termsValid) {
      showToast({
        tone: 'warning',
        title: tCommon('validation'),
        message: t('terms.invalidVersionMessage'),
      });
      return;
    }
    setBusySection('terms');
    try {
      const updated = await adminBrowserFetch<{ version: string }>('/admin/app-config/terms-version', {
        method: 'PATCH',
        body: { version: termsVersion },
      });
      setTermsVersion(updated.version);
      setTermsBaseline(updated.version);
      showToast({ tone: 'success', title: tCommon('saved'), message: t('terms.savedMessage') });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tCommon('saveFailed'),
        message: error instanceof Error ? error.message : tCommon('errorGeneric'),
      });
    } finally {
      setBusySection(null);
    }
  }

  async function saveOrganizerQuiz() {
    if (!quizParse.ok) {
      showToast({
        tone: 'warning',
        title: tCommon('validation'),
        message:
          quizParse.error === 'invalidObject'
            ? t('organizerQuiz.invalidObject')
            : tCommon('errorGeneric'),
      });
      return;
    }
    setBusySection('quiz');
    try {
      const updated = await adminBrowserFetch<Record<string, unknown>>(
        `/admin/app-config/organizer-quiz?locale=${encodeURIComponent(quizLocale)}`,
        { method: 'PATCH', body: quizParse.data },
      );
      const next = JSON.stringify(updated, null, 2);
      setQuizJson(next);
      setQuizBaseline(next);
      showToast({ tone: 'success', title: tCommon('saved'), message: t('organizerQuiz.savedMessage') });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tCommon('saveFailed'),
        message: error instanceof Error ? error.message : tCommon('errorGeneric'),
      });
    } finally {
      setBusySection(null);
    }
  }

  return (
    <div className={styles.stack}>
      <PageHeader title={t('pageTitle')} description={t('description')} />
      <Card padding="md" className={styles.section}>
        <h3>{t('reportCredits.title')}</h3>
        <Input
          label={t('reportCredits.dailyCredits')}
          type="number"
          min={1}
          value={String(reportCredits.dailyCredits)}
          readOnly={readOnlyAppConfig}
          onChange={(e) => setReportCredits((c) => ({ ...c, dailyCredits: Number(e.target.value) }))}
        />
        <Input
          label={t('reportCredits.emergencyWindowHours')}
          type="number"
          min={1}
          value={String(reportCredits.emergencyWindowHours)}
          readOnly={readOnlyAppConfig}
          onChange={(e) => setReportCredits((c) => ({ ...c, emergencyWindowHours: Number(e.target.value) }))}
        />
        <Input
          label={t('reportCredits.refillIntervalHours')}
          type="number"
          min={1}
          value={String(reportCredits.refillIntervalHours)}
          readOnly={readOnlyAppConfig}
          onChange={(e) => setReportCredits((c) => ({ ...c, refillIntervalHours: Number(e.target.value) }))}
        />
        {!creditsValid ? <p className={styles.fieldError}>{t('reportCredits.validationError')}</p> : null}
        <Can permission="app-config:write">
          <div className={styles.actions}>
            <Button
              onClick={() => void saveReportCredits()}
              disabled={busySection !== null || !creditsDirty || !creditsValid}
              aria-busy={busySection === 'credits'}
            >
              {busySection === 'credits' ? tCommon('saving') : t('reportCredits.save')}
            </Button>
          </div>
        </Can>
      </Card>
      <Card padding="md" className={styles.section}>
        <h3>{t('feedRanking.title')}</h3>
        <Input
          label={t('feedRanking.defaultVariant')}
          value={feedRanking.defaultVariant}
          readOnly={readOnlyAppConfig}
          onChange={(e) => setFeedRanking((c) => ({ ...c, defaultVariant: e.target.value }))}
        />
        <Checkbox
          id="experiment-enabled"
          className={styles.checkboxRow}
          checked={feedRanking.experimentEnabled}
          disabled={readOnlyAppConfig}
          onChange={(e) => {
            const next = e.target.checked;
            if (next && !feedRanking.experimentEnabled) {
              setPendingExperimentEnabled(true);
              setExperimentConfirmOpen(true);
              return;
            }
            setFeedRanking((c) => ({ ...c, experimentEnabled: next }));
          }}
          label={t('feedRanking.experimentEnabled')}
        />
        <Can permission="app-config:write">
          <div className={styles.actions}>
            <Button
              onClick={() => void saveFeedRanking()}
              disabled={busySection !== null || !feedDirty || !feedValid}
              aria-busy={busySection === 'feed'}
            >
              {busySection === 'feed' ? tCommon('saving') : t('feedRanking.save')}
            </Button>
          </div>
        </Can>
      </Card>
      <Card padding="md" className={styles.section}>
        <h3>{t('organizerQuiz.title')}</h3>
        {quizLoadError ? <SectionState variant="error" message={quizLoadError} /> : null}
        <Select
          label={t('organizerQuiz.locale')}
          value={quizLocale}
          options={[
            { value: 'en', label: t('organizerQuiz.localeEnglish') },
            { value: 'mk', label: t('organizerQuiz.localeMacedonian') },
          ]}
          onChange={(event) => handleQuizLocaleChange(event.target.value)}
        />
        <JsonEditor
          label={t('organizerQuiz.jsonAria')}
          value={quizJson}
          disabled={readOnlyConfig || quizLocaleLoading}
          onChange={setQuizJson}
          rows={16}
        />
        {quizLocaleLoading ? <p className={styles.hint}>{t('organizerQuiz.loading', { locale: quizLocale })}</p> : null}
        <Can permission="config:write">
          <div className={styles.actions}>
            <Button
              onClick={() => void saveOrganizerQuiz()}
              disabled={busySection !== null || quizLocaleLoading || !quizDirty || !quizParse.ok}
              aria-busy={busySection === 'quiz'}
            >
              {busySection === 'quiz' ? tCommon('saving') : t('organizerQuiz.save')}
            </Button>
          </div>
        </Can>
      </Card>
      <Card padding="md">
        <h3>{t('terms.title')}</h3>
        <Input
          label={t('terms.version')}
          value={termsVersion}
          readOnly={readOnlyConfig}
          onChange={(e) => setTermsVersion(e.target.value)}
        />
        {!termsValid ? <p className={styles.fieldError}>{t('terms.validationError')}</p> : null}
        <Can permission="config:write">
          <div className={styles.actions}>
            <Button
              onClick={() => void saveTermsVersion()}
              disabled={busySection !== null || !termsDirty || !termsValid}
              aria-busy={busySection === 'terms'}
            >
              {busySection === 'terms' ? tCommon('saving') : t('terms.save')}
            </Button>
          </div>
        </Can>
      </Card>
      <ConfirmDialog
        open={experimentConfirmOpen}
        title={t('feedRanking.experimentConfirmTitle')}
        description={t('feedRanking.experimentConfirmDescription')}
        tone="danger"
        confirmLabel={t('feedRanking.experimentConfirmAction')}
        onConfirm={() => {
          if (pendingExperimentEnabled != null) {
            setFeedRanking((c) => ({ ...c, experimentEnabled: pendingExperimentEnabled }));
          }
          setPendingExperimentEnabled(null);
          setExperimentConfirmOpen(false);
        }}
        onClose={() => {
          setPendingExperimentEnabled(null);
          setExperimentConfirmOpen(false);
        }}
      />
      <ConfirmDialog
        open={localeConfirmOpen}
        title={t('organizerQuiz.discardLocaleTitle')}
        description={t('organizerQuiz.discardLocaleDescription')}
        tone="danger"
        confirmLabel={t('organizerQuiz.discardLocaleConfirm')}
        onConfirm={confirmQuizLocaleChange}
        onClose={() => {
          setLocaleConfirmOpen(false);
          setPendingQuizLocale(null);
        }}
      />
    </div>
  );
}
