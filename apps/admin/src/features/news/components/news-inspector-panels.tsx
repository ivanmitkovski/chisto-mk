'use client';

import { useTranslations } from 'next-intl';
import { NewsContentLintPanel } from './news-content-lint-panel';
import { NewsEditorMetaPanel } from './news-editor-meta-panel';
import { NewsInspectorCoverPanel } from './news-inspector-cover-panel';
import { NewsInspectorSection } from './news-inspector-section';
import { NewsLocaleCompleteness } from './news-locale-completeness';
import inspectorStyles from './news-inspector.module.css';
import { NewsMediaLibrary } from './news-media-library';
import { NewsPostSettingsPanel } from './news-post-settings-panel';
import { NewsRevisionPanel } from './news-revision-panel';
import { NewsSeoPreview } from './news-seo-preview';
import type { NewsMediaDto, NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';

export type NewsInspectorPanelsProps = {
  postId: string;
  post: NewsPostAdminDto;
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  readOnly: boolean;
  busy: boolean;
  lifecycleBusy: boolean;
  hasCover: boolean;
  coverImageUrl: string | null;
  coverMediaId: string | null;
  contentDirty: boolean;
  altPending: boolean;
  media: NewsMediaDto[];
  bodyBlockCount: number;
  onChange: <K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => void;
  onCopyFromLocale: (source: NewsFormLocale) => void;
  onInsertMediaAt: (mediaId: string, kind: 'inline_image' | 'inline_video', insertIndex: number) => void;
  onDeleteMedia: (mediaId: string) => void;
  onAltTextChange: (mediaId: string, altLocale: NewsFormLocale, value: string) => void;
  onBeforeRestore: () => Promise<void>;
  onRestored: (post: NewsPostAdminDto) => void;
  onLintJump?: ((target: import('./news-content-lint-panel').NewsLintJumpTarget, locale: NewsFormLocale) => void) | undefined;
};

export function NewsInspectorPanels({
  postId,
  post,
  values,
  locale,
  readOnly,
  busy,
  lifecycleBusy,
  hasCover,
  coverImageUrl,
  coverMediaId,
  contentDirty,
  altPending,
  media,
  bodyBlockCount,
  onChange,
  onCopyFromLocale,
  onInsertMediaAt,
  onDeleteMedia,
  onAltTextChange,
  onBeforeRestore,
  onRestored,
  onLintJump,
}: NewsInspectorPanelsProps) {
  const t = useTranslations('news');
  const showMedia = media.length > 0 || !readOnly;

  return (
    <div className={inspectorStyles.shell}>
      <div className={inspectorStyles.readinessBar}>
        <NewsLocaleCompleteness
          values={values}
          hasCover={hasCover}
          media={media}
          activeLocale={locale}
        />
      </div>

      <NewsInspectorSection title={t('lint.label')} defaultOpen>
        <NewsContentLintPanel
          values={values}
          locale={locale}
          hasCover={hasCover}
          media={media}
          onJump={onLintJump}
        />
      </NewsInspectorSection>

      <NewsInspectorSection title={t('inspector.coverTitle')} defaultOpen={!hasCover}>
        <div id="news-inspector-cover">
        <NewsInspectorCoverPanel
          locale={locale}
          hasCover={hasCover}
          coverImageUrl={coverImageUrl}
          coverMediaId={coverMediaId}
          media={media}
          readOnly={readOnly}
          busy={busy}
          onAltTextChange={onAltTextChange}
        />
        </div>
      </NewsInspectorSection>

      <NewsInspectorSection
        title={t('form.settingsLabel')}
        description={t('form.settingsDescription')}
      >
        <NewsPostSettingsPanel
          values={values}
          locale={locale}
          media={media}
          status={post.status}
          busy={lifecycleBusy}
          readOnly={readOnly}
          hasCover={hasCover}
          embedded
          onChange={onChange}
          onCopyFromLocale={onCopyFromLocale}
        />
      </NewsInspectorSection>

      <NewsInspectorSection title={t('meta.label')}>
        <NewsEditorMetaPanel post={post} values={values} locale={locale} status={post.status} />
      </NewsInspectorSection>

      <NewsInspectorSection title={t('seo.label')}>
        <NewsSeoPreview
          postId={postId}
          values={values}
          locale={locale}
          coverImageUrl={coverImageUrl}
          publishedAt={post.publishedAt}
          embedded
        />
      </NewsInspectorSection>

      <NewsInspectorSection title={t('revisions.label')} defaultOpen={false}>
        <NewsRevisionPanel
          postId={postId}
          media={media}
          readOnly={readOnly}
          hasUnsavedChanges={contentDirty || altPending}
          onBeforeRestore={onBeforeRestore}
          onRestored={onRestored}
          activeLocale={locale}
          currentValues={values}
          embedded
        />
      </NewsInspectorSection>

      {showMedia ? (
        <NewsInspectorSection title={t('form.mediaLibrary')} defaultOpen={media.length > 0}>
          <div id="news-inspector-media">
          <NewsMediaLibrary
            media={media}
            bodyBlockCount={bodyBlockCount}
            readOnly={readOnly}
            busy={busy}
            onInsertAt={onInsertMediaAt}
            onDelete={onDeleteMedia}
            onAltTextChange={onAltTextChange}
            embedded
          />
          </div>
        </NewsInspectorSection>
      ) : null}
    </div>
  );
}
