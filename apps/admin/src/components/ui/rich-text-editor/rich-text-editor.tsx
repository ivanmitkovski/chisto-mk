'use client';

import Link from '@tiptap/extension-link';
import Placeholder from '@tiptap/extension-placeholder';
import Underline from '@tiptap/extension-underline';
import { EditorContent, useEditor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { useTranslations } from 'next-intl';
import { useCallback, useEffect, useRef, useState } from 'react';
import { sanitizeInlineHtml, stripHtmlToPlainText } from '@chisto/news-content';
import { RichTextLinkDialog } from '@/components/ui/rich-text-editor/rich-text-link-dialog';
import { useOptionalNewsDocumentEditor } from '@/features/news/context/news-document-editor-context';
import {
  captureLinkDialogState,
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

export function RichTextEditor({
  value,
  onChange,
  disabled = false,
  placeholder,
  variant = 'default',
  documentBlockId,
  documentBlockIndex,
}: RichTextEditorProps) {
  const t = useTranslations('news');
  const documentContext = useOptionalNewsDocumentEditor();
  const [linkOpen, setLinkOpen] = useState(false);
  const [linkSnapshot, setLinkSnapshot] = useState<LinkSelectionSnapshot | null>(null);
  const valueRef = useRef(value);
  valueRef.current = value;
  const suppressUpdateRef = useRef(true);

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
        HTMLAttributes: {
          rel: 'noopener noreferrer',
        },
      }),
      Placeholder.configure({
        placeholder: placeholder ?? t('form.paragraphPlaceholder'),
      }),
    ],
    content: initialContent(value),
    editable: !disabled,
    onUpdate: ({ editor: ed }) => {
      if (suppressUpdateRef.current) return;
      emitChange(ed.getHTML());
    },
  });

  useEffect(() => {
    if (!editor) return;
    suppressUpdateRef.current = true;
    const frame = requestAnimationFrame(() => {
      suppressUpdateRef.current = false;
    });
    return () => cancelAnimationFrame(frame);
  }, [editor]);

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

  const closeLinkDialog = useCallback(() => {
    setLinkOpen(false);
    setLinkSnapshot(null);
  }, []);

  if (!editor) return null;

  const plainLength = value.text.length;
  const isDocument = variant === 'document';
  const showCharCount = !isDocument || plainLength > 8_000;
  const showInlineToolbar = !disabled && !usesCentralToolbar;

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
          >
            B
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('italic') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleItalic().run()}
            aria-label={t('form.italic')}
            aria-pressed={editor.isActive('italic')}
          >
            I
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('underline') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleUnderline().run()}
            aria-label={t('form.underline')}
            aria-pressed={editor.isActive('underline')}
          >
            U
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('bulletList') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            aria-label={t('form.bulletList')}
            aria-pressed={editor.isActive('bulletList')}
          >
            •
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('orderedList') ? styles.toolbarButtonActive : ''}`}
            onClick={() => editor.chain().focus().toggleOrderedList().run()}
            aria-label={t('form.numberedList')}
            aria-pressed={editor.isActive('orderedList')}
          >
            1.
          </button>
          <button
            type="button"
            className={`${styles.toolbarButton} ${editor.isActive('link') ? styles.toolbarButtonActive : ''}`}
            onClick={openLinkDialog}
            aria-label={t('form.insertLink')}
          >
            {t('form.link')}
          </button>
        </div>
      ) : null}

      <div className={isDocument ? `${styles.editorSurface} ${styles.editorSurfaceDocument}` : styles.editorSurface}>
        <EditorContent editor={editor} />
      </div>

      {showCharCount ? (
        <div className={styles.footer}>
          <span className={styles.charCount}>
            {plainLength} / {MAX_PLAIN_LENGTH}
          </span>
        </div>
      ) : null}

      {showInlineToolbar ? (
        <RichTextLinkDialog
          editor={editor}
          snapshot={linkSnapshot}
          open={linkOpen}
          onClose={closeLinkDialog}
        />
      ) : null}
    </div>
  );
}
