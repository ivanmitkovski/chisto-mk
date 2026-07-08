'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { modKeyLabel } from '@/components/ui/rich-text-editor';
import { Icon } from '@/components/ui';
import { RichTextLinkDialog } from '@/components/ui/rich-text-editor/rich-text-link-dialog';
import type { LinkSelectionSnapshot } from '@/lib/rich-text/apply-editor-link';
import { captureLinkDialogState } from '@/lib/rich-text/apply-editor-link';
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
  onOpenShortcuts?: (() => void) | undefined;
  onPasteBody?: (() => void) | undefined;
};

export function NewsDocumentToolbar({
  readOnly,
  busy,
  bodyLength,
  onInsertBlocks,
  onUploadCover,
  onUploadInlineAt,
  onBlockLimit,
  onOpenShortcuts,
  onPasteBody,
}: NewsDocumentToolbarProps) {
  const t = useTranslations('news');
  const guidance = useNewsMediaGuidanceText();
  const mod = useMemo(() => modKeyLabel(), []);
  const {
    activeEditor,
    toolbarRevision,
    notifyToolbarChange,
    resolveInsertIndex,
    retainEditorFocus,
  } = useNewsDocumentEditor();

  const [insertOpen, setInsertOpen] = useState(false);
  const [linkOpen, setLinkOpen] = useState(false);
  const [linkSnapshot, setLinkSnapshot] = useState<LinkSelectionSnapshot | null>(null);
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
    setLinkSnapshot(captureLinkDialogState(activeEditor));
    activeEditor.commands.blur();
    setLinkOpen(true);
  }, [activeEditor]);

  const closeLinkDialog = useCallback(() => {
    setLinkOpen(false);
    setLinkSnapshot(null);
  }, []);

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
    <>
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
          title={`${t('form.bold')} · ${mod}B`}
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
          title={`${t('form.italic')} · ${mod}I`}
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
          title={`${t('form.underline')} · ${mod}U`}
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
          title={`${t('form.insertLink')} · ${mod}K`}
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

      {onPasteBody ? (
        <button
          type="button"
          className={styles.button}
          disabled={busy || readOnly}
          title={`${t('paste.toolbarAction')} · ${mod}⇧B`}
          onClick={onPasteBody}
        >
          {t('paste.toolbarLabel')}
        </button>
      ) : null}

      {onOpenShortcuts ? (
        <button
          type="button"
          className={styles.button}
          disabled={busy}
          aria-label={t('shortcuts.openHelp')}
          title={t('shortcuts.openHelp')}
          onClick={onOpenShortcuts}
        >
          ?
        </button>
      ) : null}

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

    </div>

      <RichTextLinkDialog
        editor={activeEditor}
        snapshot={linkSnapshot}
        open={linkOpen}
        onClose={closeLinkDialog}
        onApplied={() => notifyToolbarChange()}
        dialogClassName={styles.linkDialog}
      />
    </>
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
