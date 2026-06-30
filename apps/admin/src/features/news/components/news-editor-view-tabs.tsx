'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import { newsPreviewPagePath } from '../lib/news-preview-session';
import type { NewsFormLocale } from '../types';
import styles from './news-editor-view-tabs.module.css';

export type NewsEditorView = 'write' | 'preview';

type NewsEditorViewTabsProps = {
  view: NewsEditorView;
  postId: string;
  locale: NewsFormLocale;
  onViewChange: (view: NewsEditorView) => void;
  writePanel: React.ReactNode;
  previewPanel: React.ReactNode;
};

export function NewsEditorViewTabs({
  view,
  postId,
  locale,
  onViewChange,
  writePanel,
  previewPanel,
}: NewsEditorViewTabsProps) {
  const t = useTranslations('news');

  function openPreviewTab() {
    const url = newsPreviewPagePath(postId, locale);
    window.open(url, '_blank', 'noopener,noreferrer');
  }

  return (
    <div className={styles.root}>
      <div className={styles.tabBar}>
        <div className={styles.tabList} role="tablist" aria-label={t('editor.viewTabs')}>
          <button
            type="button"
            role="tab"
            aria-selected={view === 'write'}
            className={view === 'write' ? styles.tabActive : styles.tab}
            onClick={() => onViewChange('write')}
          >
            {t('editor.writeTab')}
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={view === 'preview'}
            className={view === 'preview' ? styles.tabActive : styles.tab}
            onClick={() => onViewChange('preview')}
          >
            {t('editor.previewTab')}
          </button>
        </div>
        <div className={styles.tabActions}>
          <Button type="button" variant="outline" size="sm" onClick={openPreviewTab}>
            {t('preview.openInTab')}
          </Button>
        </div>
      </div>
      <div role="tabpanel" className={view === 'preview' ? styles.previewPanelFull : styles.panel}>
        {view === 'write' ? writePanel : previewPanel}
      </div>
    </div>
  );
}
