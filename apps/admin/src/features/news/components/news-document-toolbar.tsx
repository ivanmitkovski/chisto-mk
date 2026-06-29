'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon, Modal } from '@/components/ui';
import type { NewsBodyBlock } from '../news-api-types';
import { useNewsDocumentEditor } from '../context/news-document-editor-context';
import { insertBlockAt } from '../lib/news-block-factory';
import {
  MEDIA_INSERT_OPTIONS,
  TOOLBAR_BLOCK_INSERT_OPTIONS,
  createBlockFromType,
  type BlockInsertType,
} from '../lib/news-block-insert-config';
import { MAX_BODY_BLOCKS } from '../lib/news-post-policy';
import { NEWS_MEDIA_ACCEPT } from '../lib/news-media-validation';
import { useNewsMediaGuidanceText } from '../hooks/use-news-media-guidance';
import { getLinkSelectionText } from '@/lib/rich-text/get-link-selection-text';
import {
  NewsBlockInsertMenuPanel,
  type NewsBlockInsertMenuSection,
} from './news-block-insert-menu';
import styles from './news-document-toolbar.module.css';

type NewsDocumentToolbarProps = {
  readOnly: boolean;
  busy: boolean;
  bodyLength: number;
  onInsertBlocks: (blocks: NewsBodyBlock[], insertIndex: number) => void;
  onUploadCover: (file: File) => void;
  onUploadInlineAt: (file: File, kind: 'inline_image' | 'inline_video', insertIndex: number) => void;
  onBlockLimit: () => void;
};

export function NewsDocumentToolbar({
  readOnly,
  busy,
  bodyLength,
  onInsertBlocks,
  onUploadCover,
  onUploadInlineAt,
  onBlockLimit,
}: NewsDocumentToolbarProps) {
  const t = useTranslations('news');
  const guidance = useNewsMediaGuidanceText();
  const {
    activeEditor,
    toolbarRevision,
    notifyToolbarChange,
    resolveInsertIndex,
    retainEditorFocus,
  } = useNewsDocumentEditor();

  const [insertOpen, setInsertOpen] = useState(false);
  const [linkOpen, setLinkOpen] = useState(false);
  const [linkUrl, setLinkUrl] = useState('https://');
  const [linkText, setLinkText] = useState('');
  const [linkNewTab, setLinkNewTab] = useState(true);
  const menuRef = useRef<HTMLDivElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const coverInputRef = useRef<HTMLInputElement>(null);
  const imageInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);

  const atBlockLimit = bodyLength >= MAX_BODY_BLOCKS;
  const insertIndex = resolveInsertIndex(bodyLength);
  const editorFocused = activeEditor?.isFocused ?? false;
  const canFormat = Boolean(activeEditor) && editorFocused && !readOnly && !busy;

  void toolbarRevision;

  useEffect(() => {
    if (!activeEditor) return;
    const bump = () => notifyToolbarChange();
    activeEditor.on('selectionUpdate', bump);
    activeEditor.on('transaction', bump);
    return () => {
      activeEditor.off('selectionUpdate', bump);
      activeEditor.off('transaction', bump);
    };
  }, [activeEditor, notifyToolbarChange]);

  useEffect(() => {
    if (!insertOpen) return;
    function onDocClick(event: MouseEvent) {
      if (!menuRef.current?.contains(event.target as Node)) setInsertOpen(false);
    }
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') setInsertOpen(false);
    }
    document.addEventListener('mousedown', onDocClick);
    window.addEventListener('keydown', onKeyDown);
    return () => {
      document.removeEventListener('mousedown', onDocClick);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [insertOpen]);

  const guardInsert = useCallback(() => {
    if (atBlockLimit) {
      onBlockLimit();
      return false;
    }
    return true;
  }, [atBlockLimit, onBlockLimit]);

  const insertBlock = useCallback(
    (type: BlockInsertType) => {
      if (!guardInsert()) return;
      const block = createBlockFromType(type);
      onInsertBlocks([block], insertIndex);
      setInsertOpen(false);
    },
    [guardInsert, insertIndex, onInsertBlocks],
  );

  const insertSections = useMemo<NewsBlockInsertMenuSection[]>(
    () => [
      {
        id: 'blocks',
        label: t('toolbar.insertBlocks'),
        items: TOOLBAR_BLOCK_INSERT_OPTIONS.map((option) => ({
          id: option.type,
          icon: option.icon,
          tone: option.tone,
          label: t(option.labelKey),
          description: t(option.descriptionKey),
          disabled: busy,
          onSelect: () => insertBlock(option.type),
        })),
      },
      {
        id: 'media',
        label: t('toolbar.insertMedia'),
        items: MEDIA_INSERT_OPTIONS.map((option) => ({
          id: option.action,
          icon: option.icon,
          tone: option.tone,
          label: t(option.labelKey),
          description: t(option.descriptionKey),
          hint: option.guidanceKind ? guidance(option.guidanceKind) : undefined,
          disabled: busy,
          onSelect: () => {
            setInsertOpen(false);
            if (option.action === 'cover') coverInputRef.current?.click();
            else if (option.action === 'inline_image') imageInputRef.current?.click();
            else videoInputRef.current?.click();
          },
        })),
      },
    ],
    [busy, guidance, insertBlock, t],
  );

  const runCommand = useCallback(
    (command: () => void) => {
      retainEditorFocus();
      command();
      notifyToolbarChange();
    },
    [notifyToolbarChange, retainEditorFocus],
  );

  const openLinkDialog = useCallback(() => {
    if (!activeEditor) return;
    retainEditorFocus();
    const previous = activeEditor.getAttributes('link').href as string | undefined;
    setLinkUrl(previous ?? 'https://');
    setLinkText(getLinkSelectionText(activeEditor));
    setLinkNewTab(activeEditor.getAttributes('link').target === '_blank' || !previous);
    setLinkOpen(true);
  }, [activeEditor, retainEditorFocus]);

  const applyLink = useCallback(() => {
    if (!activeEditor || !linkText.trim()) return;
    const url = linkUrl.trim();
    if (!url) {
      activeEditor.chain().focus().extendMarkRange('link').unsetLink().run();
      setLinkOpen(false);
      return;
    }
    activeEditor
      .chain()
      .focus()
      .extendMarkRange('link')
      .setLink({
        href: url,
        target: linkNewTab ? '_blank' : null,
        rel: 'noopener noreferrer',
      })
      .run();
    setLinkOpen(false);
    notifyToolbarChange();
  }, [activeEditor, linkNewTab, linkText, linkUrl, notifyToolbarChange]);

  const removeLink = useCallback(() => {
    activeEditor?.chain().focus().extendMarkRange('link').unsetLink().run();
    setLinkOpen(false);
    notifyToolbarChange();
  }, [activeEditor, notifyToolbarChange]);

  const handleToolbarMouseDown = useCallback(
    (event: React.MouseEvent) => {
      if (event.button !== 0) return;
      event.preventDefault();
      retainEditorFocus();
    },
    [retainEditorFocus],
  );

  const handleInlineFile = useCallback(
    (file: File | undefined, kind: 'inline_image' | 'inline_video') => {
      if (!file || !guardInsert()) return;
      onUploadInlineAt(file, kind, insertIndex);
      setInsertOpen(false);
    },
    [guardInsert, insertIndex, onUploadInlineAt],
  );

  if (readOnly) return null;

  return (
    <div
      className={styles.root}
      role="toolbar"
      aria-label={t('toolbar.label')}
      data-document-toolbar=""
      onMouseDown={handleToolbarMouseDown}
    >
      <div className={styles.group} aria-label={t('form.richTextToolbar')}>
        <button
          type="button"
          className={activeEditor?.isActive('bold') ? `${styles.button} ${styles.buttonActive}` : styles.button}
          disabled={!canFormat}
          aria-label={t('form.bold')}
          aria-pressed={activeEditor?.isActive('bold') ?? false}
          onClick={() => runCommand(() => activeEditor?.chain().focus().toggleBold().run())}
        >
          B
        </button>
        <button
          type="button"
          className={activeEditor?.isActive('italic') ? `${styles.button} ${styles.buttonActive}` : styles.button}
          disabled={!canFormat}
          aria-label={t('form.italic')}
          aria-pressed={activeEditor?.isActive('italic') ?? false}
          onClick={() => runCommand(() => activeEditor?.chain().focus().toggleItalic().run())}
        >
          I
        </button>
        <button
          type="button"
          className={activeEditor?.isActive('underline') ? `${styles.button} ${styles.buttonActive}` : styles.button}
          disabled={!canFormat}
          aria-label={t('form.underline')}
          aria-pressed={activeEditor?.isActive('underline') ?? false}
          onClick={() => runCommand(() => activeEditor?.chain().focus().toggleUnderline().run())}
        >
          U
        </button>
        <button
          type="button"
          className={activeEditor?.isActive('bulletList') ? `${styles.button} ${styles.buttonActive}` : styles.button}
          disabled={!canFormat}
          aria-label={t('form.bulletList')}
          aria-pressed={activeEditor?.isActive('bulletList') ?? false}
          onClick={() => runCommand(() => activeEditor?.chain().focus().toggleBulletList().run())}
        >
          •
        </button>
        <button
          type="button"
          className={activeEditor?.isActive('orderedList') ? `${styles.button} ${styles.buttonActive}` : styles.button}
          disabled={!canFormat}
          aria-label={t('form.numberedList')}
          aria-pressed={activeEditor?.isActive('orderedList') ?? false}
          onClick={() => runCommand(() => activeEditor?.chain().focus().toggleOrderedList().run())}
        >
          1.
        </button>
        <button
          type="button"
          className={activeEditor?.isActive('link') ? `${styles.button} ${styles.buttonActive}` : styles.button}
          disabled={!canFormat}
          aria-label={t('form.insertLink')}
          onClick={openLinkDialog}
        >
          {t('form.link')}
        </button>
      </div>

      <div className={styles.divider} aria-hidden />

      <div ref={menuRef} className={styles.insertWrap}>
        <button
          type="button"
          className={`${styles.insertButton} ${insertOpen ? styles.insertButtonOpen : ''}`}
          disabled={busy}
          aria-expanded={insertOpen}
          aria-haspopup="menu"
          onClick={() => setInsertOpen((open) => !open)}
        >
          <Icon name="plus" size={14} strokeWidth={2.25} aria-hidden />
          {t('toolbar.insert')}
          <Icon
            name="chevron-down"
            size={14}
            className={`${styles.insertChevron} ${insertOpen ? styles.insertChevronOpen : ''}`}
            aria-hidden
          />
        </button>
        <NewsBlockInsertMenuPanel
          open={insertOpen}
          sections={insertSections}
          ariaLabel={t('toolbar.insert')}
          panelRef={panelRef}
          onClose={() => setInsertOpen(false)}
        />
      </div>

      <span className={styles.status}>
        {canFormat ? t('toolbar.formattingActive') : t('toolbar.formattingHint')}
      </span>

      <input
        ref={coverInputRef}
        type="file"
        accept={NEWS_MEDIA_ACCEPT.cover}
        className={styles.hiddenInput}
        tabIndex={-1}
        aria-hidden
        onChange={(event) => {
          const file = event.target.files?.[0];
          event.target.value = '';
          if (file) onUploadCover(file);
          setInsertOpen(false);
        }}
      />
      <input
        ref={imageInputRef}
        type="file"
        accept={NEWS_MEDIA_ACCEPT.inline_image}
        className={styles.hiddenInput}
        tabIndex={-1}
        aria-hidden
        onChange={(event) => {
          handleInlineFile(event.target.files?.[0], 'inline_image');
          event.target.value = '';
        }}
      />
      <input
        ref={videoInputRef}
        type="file"
        accept={NEWS_MEDIA_ACCEPT.inline_video}
        className={styles.hiddenInput}
        tabIndex={-1}
        aria-hidden
        onChange={(event) => {
          handleInlineFile(event.target.files?.[0], 'inline_video');
          event.target.value = '';
        }}
      />

      <Modal
        open={linkOpen}
        title={t('form.linkDialogTitle')}
        description={
          linkText.trim()
            ? t('form.linkDialogDescriptionWithText', { text: linkText.trim() })
            : t('form.linkDialogDescription')
        }
        onClose={() => setLinkOpen(false)}
      >
        <div className={styles.linkDialog}>
          <div className={styles.linkTextPreview} aria-live="polite">
            <span className={styles.linkTextLabel}>{t('form.linkText')}</span>
            {linkText.trim() ? (
              <p className={styles.linkTextValue}>{linkText.trim()}</p>
            ) : (
              <p className={styles.linkTextEmpty}>{t('form.linkTextEmpty')}</p>
            )}
          </div>
          <label className={styles.linkField}>
            <span>{t('form.linkUrl')}</span>
            <input
              type="url"
              value={linkUrl}
              onChange={(event) => setLinkUrl(event.target.value)}
              placeholder="https://"
              autoFocus
            />
          </label>
          <label className={styles.checkboxRow}>
            <input type="checkbox" checked={linkNewTab} onChange={(event) => setLinkNewTab(event.target.checked)} />
            {t('form.linkOpenNewTab')}
          </label>
          <div className={styles.linkActions}>
            <Button type="button" variant="ghost" onClick={removeLink}>
              {t('form.removeLink')}
            </Button>
            <Button type="button" onClick={applyLink} disabled={!linkText.trim()}>
              {t('form.applyLink')}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}

export function mergeBlocksAtIndex(
  current: NewsBodyBlock[],
  insertIndex: number,
  blocks: NewsBodyBlock[],
): NewsBodyBlock[] {
  let next = [...current];
  blocks.forEach((block, offset) => {
    next = insertBlockAt(next, insertIndex + offset, block);
  });
  return next;
}
