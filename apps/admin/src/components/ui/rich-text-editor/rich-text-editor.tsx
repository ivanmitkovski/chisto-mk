'use client';

import { Extension } from '@tiptap/core';
import Link from '@tiptap/extension-link';
import '@chisto/news-content/render/external-link-indicator.css';
import Placeholder from '@tiptap/extension-placeholder';
import Underline from '@tiptap/extension-underline';
import { BubbleMenu, EditorContent, useEditor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { useTranslations } from 'next-intl';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  sanitizeInlineHtml,
  sanitizePastedInlineHtml,
  stripHtmlToPlainText,
} from '@chisto/news-content';
import { RichTextLinkDialog } from '@/components/ui/rich-text-editor/rich-text-link-dialog';
import { useOptionalNewsDocumentEditor } from '@/features/news/context/news-document-editor-context';
import {
  captureLinkDialogState,
  normalizeLinkUrl,
  type LinkSelectionSnapshot,
} from '@/lib/rich-text/apply-editor-link';
import styles from './rich-text-editor.module.css';

const MAX_PLAIN_LENGTH = 10_000;

export type RichTextEditorValue = {
  text: string;
  html?: string | undefined;
};

type RichTextEditorProps = {
  value: RichTextEditorValue;
  onChange: (value: RichTextEditorValue) => void;
  disabled?: boolean | undefined;
  placeholder?: string | undefined;
  variant?: 'default' | 'document' | undefined;
  documentBlockId?: string | undefined;
  documentBlockIndex?: number | undefined;
  /** Focus the editor after mount (used when a block is created via keyboard). */
  autoFocus?: boolean | undefined;
  onAutoFocused?: (() => void) | undefined;
  /** Typing "/" in an empty paragraph opens the block insert palette. */
  onSlashMenu?: (() => void) | undefined;
  /** Enter at end or Mod+Enter — insert a fresh paragraph block below. */
  onCreateBlockAfter?: (() => void) | undefined;
  /** Backspace at block start — merge into the previous paragraph. */
  onMergeWithPrevious?: (() => void) | undefined;
  /** Multi-paragraph paste into an empty block (returns true when handled). */
  onMultiParagraphPaste?: ((raw: { html: string; plain: string }) => boolean) | undefined;
  /** Image paste — insert an image block (returns true when handled). */
  onPasteImageFile?: ((file: File) => boolean) | undefined;
};

function initialContent(value: RichTextEditorValue): string {
  if (value.html?.trim()) return value.html;
  if (value.text.trim()) return `<p>${value.text.replace(/\n/g, '<br>')}</p>`;
  return '';
}

function normalizeRichTextValue(value: RichTextEditorValue): RichTextEditorValue {
  const sanitized = value.html?.trim() ? sanitizeInlineHtml(value.html) : '';
  const plain = sanitized ? stripHtmlToPlainText(sanitized) : value.text.trim();
  return {
    text: plain.slice(0, MAX_PLAIN_LENGTH),
    ...(sanitized ? { html: sanitized } : {}),
  };
}

function richTextValuesEqual(a: RichTextEditorValue, b: RichTextEditorValue): boolean {
  const left = normalizeRichTextValue(a);
  const right = normalizeRichTextValue(b);
  return left.text === right.text && (left.html ?? '') === (right.html ?? '');
}

/** Platform-aware modifier label for shortcut hints in tooltips. */
export function modKeyLabel(): string {
  if (typeof navigator !== 'undefined' && /Mac|iPhone|iPad/.test(navigator.platform)) {
    return '⌘';
  }
  return 'Ctrl+';
}

export function RichTextEditor({
  value,
  onChange,
  disabled = false,
  placeholder,
  variant = 'default',
  documentBlockId,
  documentBlockIndex,
  autoFocus = false,
  onAutoFocused,
  onSlashMenu,
  onCreateBlockAfter,
  onMergeWithPrevious,
  onMultiParagraphPaste,
  onPasteImageFile,
}: RichTextEditorProps) {
  const t = useTranslations('news');
  const documentContext = useOptionalNewsDocumentEditor();
  const [linkOpen, setLinkOpen] = useState(false);
  const [linkSnapshot, setLinkSnapshot] = useState<LinkSelectionSnapshot | null>(null);
  const valueRef = useRef(value);
  valueRef.current = value;
  const suppressUpdateRef = useRef(true);
  const openLinkDialogRef = useRef<() => void>(() => {});
  const slashMenuRef = useRef(onSlashMenu);
  slashMenuRef.current = onSlashMenu;
  const createBlockAfterRef = useRef(onCreateBlockAfter);
  createBlockAfterRef.current = onCreateBlockAfter;
  const mergeWithPreviousRef = useRef(onMergeWithPrevious);
  mergeWithPreviousRef.current = onMergeWithPrevious;
  const multiParagraphPasteRef = useRef(onMultiParagraphPaste);
  multiParagraphPasteRef.current = onMultiParagraphPaste;
  const pasteImageFileRef = useRef(onPasteImageFile);
  pasteImageFileRef.current = onPasteImageFile;
  const autoFocusedRef = useRef(false);
  const mod = useMemo(() => modKeyLabel(), []);

  const emitChange = useCallback(
    (html: string) => {
      const sanitized = sanitizeInlineHtml(html);
      const plain = stripHtmlToPlainText(sanitized);
      const next: RichTextEditorValue = {
        text: plain.slice(0, MAX_PLAIN_LENGTH),
        ...(sanitized ? { html: sanitized } : {}),
      };
      if (richTextValuesEqual(next, valueRef.current)) return;
      onChange(next);
    },
    [onChange],
  );

  const shortcuts = useMemo(
    () =>
      Extension.create({
        name: 'newsRichTextShortcuts',
        addKeyboardShortcuts() {
          return {
            'Mod-k': () => {
              openLinkDialogRef.current();
              return true;
            },
            'Mod-/': () => {
              slashMenuRef.current?.();
              return Boolean(slashMenuRef.current);
            },
          };
        },
      }),
    [],
  );

  const editor = useEditor({
    immediatelyRender: false,
    extensions: [
      StarterKit.configure({
        heading: false,
        codeBlock: false,
        code: false,
        blockquote: false,
        horizontalRule: false,
      }),
      Underline,
      Link.configure({
        openOnClick: false,
        autolink: true,
        linkOnPaste: true,
        shouldAutoLink: (url) => /^https?:\/\//i.test(url) || /^mailto:/i.test(url),
        isAllowedUri: (url) => {
          if (/^https?:\/\/chisto\.mk\/?$/i.test(url)) return false;
          return normalizeLinkUrl(url) !== null;
        },
        HTMLAttributes: {
          rel: 'noopener noreferrer',
        },
      }),
      Placeholder.configure({
        placeholder: placeholder ?? t('form.paragraphPlaceholder'),
      }),
      shortcuts,
    ],
    editorProps: {
      // Strip Word/Google Docs markup down to the shared inline allowlist.
      transformPastedHTML: (html) => sanitizePastedInlineHtml(html),
      handleKeyDown: (_view, event) => {
        const ed = editorRef.current;
        if (!ed || disabled) return false;

        if (
          event.key === '/' &&
          !event.metaKey &&
          !event.ctrlKey &&
          slashMenuRef.current &&
          ed.isEmpty
        ) {
          event.preventDefault();
          slashMenuRef.current();
          return true;
        }

        const { $from, empty } = ed.state.selection;
        const atStart = empty && $from.parentOffset === 0;
        const atEnd = empty && $from.parentOffset === $from.parent.content.size;

        if (event.key === 'Enter' && !event.shiftKey) {
          const modEnter = event.metaKey || event.ctrlKey;
          if ((atEnd || modEnter) && createBlockAfterRef.current) {
            event.preventDefault();
            createBlockAfterRef.current();
            return true;
          }
        }

        if (event.key === 'Backspace' && atStart && mergeWithPreviousRef.current) {
          event.preventDefault();
          mergeWithPreviousRef.current();
          return true;
        }

        return false;
      },
      handlePaste: (_view, event) => {
        const ed = editorRef.current;
        if (!ed) return false;

        const clipboard = event.clipboardData;
        if (!clipboard) return false;

        const items = clipboard.items;
        if (items && pasteImageFileRef.current) {
          for (const item of Array.from(items)) {
            if (!item.type.startsWith('image/')) continue;
            const file = item.getAsFile();
            if (file && pasteImageFileRef.current(file)) {
              event.preventDefault();
              return true;
            }
          }
        }

        if (ed.isEmpty && multiParagraphPasteRef.current) {
          const html = clipboard.getData('text/html');
          const plain = clipboard.getData('text/plain');
          if (multiParagraphPasteRef.current({ html, plain })) {
            event.preventDefault();
            return true;
          }
        }

        return false;
      },
    },
    content: initialContent(value),
    editable: !disabled,
    onUpdate: ({ editor: ed }) => {
      if (suppressUpdateRef.current) return;
      emitChange(ed.getHTML());
    },
  });

  const editorRef = useRef(editor);
  editorRef.current = editor;

  useEffect(() => {
    if (!editor) return;
    suppressUpdateRef.current = true;
    const frame = requestAnimationFrame(() => {
      suppressUpdateRef.current = false;
    });
    return () => cancelAnimationFrame(frame);
  }, [editor]);

  useEffect(() => {
    if (!autoFocus) {
      autoFocusedRef.current = false;
      return;
    }
    if (!editor || autoFocusedRef.current) return;
    autoFocusedRef.current = true;
    editor.commands.focus('end');
    onAutoFocused?.();
  }, [autoFocus, editor, onAutoFocused]);

  useEffect(() => {
    if (!editor) return;
    suppressUpdateRef.current = true;
    const nextContent = initialContent(value);
    if (editor.getHTML() === nextContent) {
      suppressUpdateRef.current = false;
      return;
    }
    editor.commands.setContent(nextContent, false);
    requestAnimationFrame(() => {
      suppressUpdateRef.current = false;
    });
  }, [editor, value.html, value.text]);

  useEffect(() => {
    if (!editor || disabled) return;
    editor.setEditable(!disabled);
  }, [disabled, editor]);

  const usesCentralToolbar =
    variant === 'document' &&
    Boolean(documentContext) &&
    documentBlockId !== undefined &&
    documentBlockIndex !== undefined;

  const documentActionsRef = useRef({
    setActiveParagraphEditor: documentContext?.setActiveParagraphEditor,
    registerParagraphEditor: documentContext?.registerParagraphEditor,
    unregisterParagraphEditor: documentContext?.unregisterParagraphEditor,
    notifyToolbarChange: documentContext?.notifyToolbarChange,
    isRetainingEditorFocus: documentContext?.isRetainingEditorFocus,
  });

  documentActionsRef.current = {
    setActiveParagraphEditor: documentContext?.setActiveParagraphEditor,
    registerParagraphEditor: documentContext?.registerParagraphEditor,
    unregisterParagraphEditor: documentContext?.unregisterParagraphEditor,
    notifyToolbarChange: documentContext?.notifyToolbarChange,
    isRetainingEditorFocus: documentContext?.isRetainingEditorFocus,
  };

  useEffect(() => {
    if (!editor || !usesCentralToolbar || !documentBlockId || documentBlockIndex === undefined) {
      return;
    }

    const {
      setActiveParagraphEditor,
      registerParagraphEditor,
      unregisterParagraphEditor,
      notifyToolbarChange,
      isRetainingEditorFocus,
    } = documentActionsRef.current;

    if (
      !setActiveParagraphEditor ||
      !registerParagraphEditor ||
      !unregisterParagraphEditor ||
      !notifyToolbarChange
    ) {
      return;
    }

    const activate = () => {
      setActiveParagraphEditor(documentBlockId, documentBlockIndex, editor);
    };

    const handleSelectionUpdate = () => {
      if (!editor.isFocused) return;
      registerParagraphEditor(documentBlockId, documentBlockIndex, editor);
      notifyToolbarChange();
    };

    const handleBlur = () => {
      window.setTimeout(() => {
        if (isRetainingEditorFocus?.()) return;
        if (editor.isFocused) return;
        notifyToolbarChange();
      }, 0);
    };

    editor.on('focus', activate);
    editor.on('selectionUpdate', handleSelectionUpdate);
    editor.on('blur', handleBlur);

    if (editor.isFocused) activate();

    return () => {
      editor.off('focus', activate);
      editor.off('selectionUpdate', handleSelectionUpdate);
      editor.off('blur', handleBlur);
      unregisterParagraphEditor(documentBlockId);
    };
  }, [documentBlockId, documentBlockIndex, editor, usesCentralToolbar]);

  const openLinkDialog = useCallback(() => {
    if (!editor) return;
    setLinkSnapshot(captureLinkDialogState(editor));
    setLinkOpen(true);
  }, [editor]);

  openLinkDialogRef.current = openLinkDialog;

  const closeLinkDialog = useCallback(() => {
    setLinkOpen(false);
    setLinkSnapshot(null);
  }, []);

  if (!editor) return null;

  const plainLength = value.text.length;
  const isDocument = variant === 'document';
  const showCharCount = !isDocument || plainLength > 8_000;
  const showInlineToolbar = !disabled && !usesCentralToolbar;

  const bubbleButtons = (
    <>
      <button
        type="button"
        className={`${styles.bubbleButton} ${editor.isActive('bold') ? styles.bubbleButtonActive : ''}`}
        onMouseDown={(e) => e.preventDefault()}
        onClick={() => editor.chain().focus().toggleBold().run()}
        aria-label={t('form.bold')}
        aria-pressed={editor.isActive('bold')}
        title={`${t('form.bold')} · ${mod}B`}
      >
        B
      </button>
      <button
        type="button"
        className={`${styles.bubbleButton} ${editor.isActive('italic') ? styles.bubbleButtonActive : ''}`}
        onMouseDown={(e) => e.preventDefault()}
        onClick={() => editor.chain().focus().toggleItalic().run()}
        aria-label={t('form.italic')}
        aria-pressed={editor.isActive('italic')}
        title={`${t('form.italic')} · ${mod}I`}
      >
        <span className={styles.bubbleItalic}>I</span>
      </button>
      <button
        type="button"
        className={`${styles.bubbleButton} ${editor.isActive('underline') ? styles.bubbleButtonActive : ''}`}
        onMouseDown={(e) => e.preventDefault()}
        onClick={() => editor.chain().focus().toggleUnderline().run()}
        aria-label={t('form.underline')}
        aria-pressed={editor.isActive('underline')}
        title={`${t('form.underline')} · ${mod}U`}
      >
        <span className={styles.bubbleUnderline}>U</span>
      </button>
      <span className={styles.bubbleDivider} aria-hidden />
      <button
        type="button"
        className={`${styles.bubbleButton} ${editor.isActive('link') ? styles.bubbleButtonActive : ''}`}
        onMouseDown={(e) => e.preventDefault()}
        onClick={openLinkDialog}
        aria-label={t('form.insertLink')}
        title={`${t('form.insertLink')} · ${mod}K`}
      >
        {t('form.link')}
      </button>
    </>
  );

  return (
    <div className={isDocument ? `${styles.richTextEditor} ${styles.richTextEditorDocument}` : styles.richTextEditor}>
      {showInlineToolbar ? (
        <div className={styles.toolbar} role="toolbar" aria-label={t('form.richTextToolbar')}>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('bold') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleBold().run()}
            aria-label={t('form.bold')}
            aria-pressed={editor.isActive('bold')}
            title={`${t('form.bold')} · ${mod}B`}
          >
            B
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('italic') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleItalic().run()}
            aria-label={t('form.italic')}
            aria-pressed={editor.isActive('italic')}
            title={`${t('form.italic')} · ${mod}I`}
          >
            I
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('underline') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleUnderline().run()}
            aria-label={t('form.underline')}
            aria-pressed={editor.isActive('underline')}
            title={`${t('form.underline')} · ${mod}U`}
          >
            U
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('bulletList') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            aria-label={t('form.bulletList')}
            aria-pressed={editor.isActive('bulletList')}
            title={t('form.bulletList')}
          >
            •
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('orderedList') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleOrderedList().run()}
            aria-label={t('form.numberedList')}
            aria-pressed={editor.isActive('orderedList')}
            title={t('form.numberedList')}
          >
            1.
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('link') ? styles.toolbarButtonActive : ''}`}
            onClick={openLinkDialog}
            aria-label={t('form.insertLink')}
            title={`${t('form.insertLink')} · ${mod}K`}
          >
            {t('form.link')}
          </button>
        </div>
      ) : null}

      {!disabled ? (
        <BubbleMenu
          editor={editor}
          tippyOptions={{ duration: 120, placement: 'top' }}
          className={styles.bubbleMenu}
        >
          {bubbleButtons}
        </BubbleMenu>
      ) : null}

      <div
        className={
          isDocument
            ? `${styles.editorSurface} ${styles.editorSurfaceDocument} news-prose`
            : styles.editorSurface
        }
      >
        <EditorContent editor={editor} />
      </div>

      {showCharCount ? (
        <div className={styles.footer}>
          <span className={styles.charCount}>
            {plainLength} / {MAX_PLAIN_LENGTH}
          </span>
        </div>
      ) : null}

      <RichTextLinkDialog
        editor={editor}
        snapshot={linkSnapshot}
        open={linkOpen}
        onClose={closeLinkDialog}
      />
    </div>
  );
}
