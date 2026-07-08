'use client';

import {
  buildEmbedIframeHtml,
  embedUrlFromVideoLink,
  sanitizeHtmlBlock,
} from '@chisto/news-content';
import { RenderNewsBlocks } from '@chisto/news-content/render';
import { useTranslations } from 'next-intl';
import { useMemo, useState } from 'react';
import { Badge, Button, EmptyState, Icon, Input } from '@/components/ui';
import styles from './news-html-block-editor.module.css';

type ViewMode = 'split' | 'source' | 'preview';

type NewsHtmlBlockEditorProps = {
  html?: string;
  readOnly: boolean;
  busy: boolean;
  onChange: (html: string) => void;
};

function sourceStats(html: string): { lines: number; chars: number } {
  if (!html) return { lines: 1, chars: 0 };
  return { lines: html.split('\n').length, chars: html.length };
}

export function NewsHtmlBlockEditor({
  html = '',
  readOnly,
  busy,
  onChange,
}: NewsHtmlBlockEditorProps) {
  const t = useTranslations('news');
  const tPreview = useTranslations('news.previewBlocks');
  const [embedUrl, setEmbedUrl] = useState('');
  const [embedError, setEmbedError] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<ViewMode>('split');

  const previewHtml = useMemo(() => sanitizeHtmlBlock(html), [html]);
  const hasSanitizeDiff = html.trim().length > 0 && html.trim() !== previewHtml;
  const stats = useMemo(() => sourceStats(html), [html]);
  const showSource = viewMode === 'split' || viewMode === 'source';
  const showPreview = viewMode === 'split' || viewMode === 'preview';

  function insertEmbed() {
    const url = embedUrl.trim();
    if (!url) {
      setEmbedError(t('form.embedUrlRequired'));
      return;
    }

    const embed = embedUrlFromVideoLink(url);
    if (!embed) {
      setEmbedError(t('form.embedUrlInvalid'));
      return;
    }

    const snippet = buildEmbedIframeHtml(embed);
    const nextHtml = html.trim() ? `${html.trim()}\n${snippet}` : snippet;
    onChange(sanitizeHtmlBlock(nextHtml));
    setEmbedUrl('');
    setEmbedError(null);
    setViewMode('split');
  }

  function applySanitized() {
    onChange(previewHtml);
  }

  const rootClass = `${styles.root} ${styles.rootDocument}`;

  return (
    <div className={rootClass}>
      {!readOnly ? (
        <details className={styles.guidancePanel}>
          <summary className={styles.guidanceSummary}>
            <Icon name="alert-triangle" size={14} strokeWidth={2} aria-hidden />
            <span>{t('form.htmlBlockGuidanceTitle')}</span>
          </summary>
          <div className={styles.guidanceBody}>
            <p>{t('form.htmlBlockWarning')}</p>
            <p>{t('form.htmlAllowedEmbedsHint')}</p>
          </div>
        </details>
      ) : (
        <p className={styles.readOnlyNote} role="note">
          {t('form.htmlBlockWarning')}
        </p>
      )}

      {!readOnly ? (
        <section className={styles.embedCard} aria-label={t('form.htmlEmbedSectionAria')}>
          <div className={styles.embedRow}>
            <Input
              type="url"
              className={styles.embedInput}
              value={embedUrl}
              onChange={(event) => {
                setEmbedUrl(event.target.value);
                if (embedError) setEmbedError(null);
              }}
              onKeyDown={(event) => {
                if (event.key === 'Enter') {
                  event.preventDefault();
                  insertEmbed();
                }
              }}
              placeholder={t('form.embedUrlPlaceholder')}
              disabled={busy}
              errorText={embedError ?? undefined}
              leftSlot={<Icon name="code" size={14} strokeWidth={2} aria-hidden />}
            />
            <Button
              type="button"
              variant="outline"
              size="sm"
              className={styles.embedBtn}
              disabled={busy || !embedUrl.trim()}
              onClick={insertEmbed}
            >
              <Icon name="plus" size={14} strokeWidth={2} aria-hidden />
              {t('form.insertEmbed')}
            </Button>
          </div>
        </section>
      ) : null}

      <div className={styles.workspaceHeader}>
        <div className={styles.viewToggle} role="group" aria-label={t('form.htmlViewModeAria')}>
          <Button
            type="button"
            size="sm"
            variant={viewMode === 'split' ? 'solid' : 'outline'}
            disabled={busy}
            aria-pressed={viewMode === 'split'}
            onClick={() => setViewMode('split')}
          >
            {t('form.htmlViewSplit')}
          </Button>
          <Button
            type="button"
            size="sm"
            variant={viewMode === 'source' ? 'solid' : 'outline'}
            disabled={busy}
            aria-pressed={viewMode === 'source'}
            onClick={() => setViewMode('source')}
          >
            {t('form.htmlViewSource')}
          </Button>
          <Button
            type="button"
            size="sm"
            variant={viewMode === 'preview' ? 'solid' : 'outline'}
            disabled={busy}
            aria-pressed={viewMode === 'preview'}
            onClick={() => setViewMode('preview')}
          >
            {t('form.htmlViewPreview')}
          </Button>
        </div>
        {hasSanitizeDiff && !readOnly ? (
          <Badge tone="warning" className={styles.sanitizeBadge}>
            {t('form.htmlSanitizeDiff')}
          </Badge>
        ) : null}
      </div>

      <div
        className={[
          styles.workspace,
          viewMode === 'split' ? styles.workspaceSplit : styles.workspaceSingle,
        ].join(' ')}
      >
        {showSource ? (
          <section className={styles.panel} aria-label={t('form.htmlSource')}>
            <div className={styles.panelHeader}>
              <h4 className={styles.panelTitle}>{t('form.htmlSource')}</h4>
              <span className={styles.panelMeta}>
                {t('form.htmlSourceStats', { lines: stats.lines, chars: stats.chars })}
              </span>
            </div>
            <textarea
              className={styles.textareaDocument}
              value={html}
              onChange={(event) => onChange(event.target.value)}
              disabled={busy || readOnly}
              spellCheck={false}
              aria-label={t('form.htmlSource')}
            />
            {!readOnly ? (
              <div className={styles.sourceActions}>
                {hasSanitizeDiff ? (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    disabled={busy}
                    onClick={applySanitized}
                  >
                    {t('form.htmlApplySanitized')}
                  </Button>
                ) : null}
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  disabled={busy || !html.trim()}
                  onClick={() => onChange('')}
                >
                  {t('form.htmlClearSource')}
                </Button>
              </div>
            ) : null}
          </section>
        ) : null}

        {showPreview ? (
          <section className={styles.panel} aria-label={t('form.htmlPreview')}>
            <div className={styles.panelHeader}>
              <h4 className={styles.panelTitle}>{t('form.htmlPreview')}</h4>
              <Badge tone="info" className={styles.liveBadge}>
                {t('form.htmlPreviewLive')}
              </Badge>
            </div>
            <div className={styles.preview}>
              {previewHtml ? (
                <RenderNewsBlocks
                  blocks={[{ type: 'html', html: previewHtml }]}
                  labels={{
                    imageUnavailable: tPreview('imageUnavailable'),
                    videoUnavailable: tPreview('videoUnavailable'),
                  }}
                />
              ) : (
                <EmptyState
                  className={styles.previewEmpty}
                  icon="document-text"
                  title={t('form.htmlPreviewEmpty')}
                  description={t('form.htmlPreviewEmptyHint')}
                />
              )}
            </div>
          </section>
        ) : null}
      </div>
    </div>
  );
}
