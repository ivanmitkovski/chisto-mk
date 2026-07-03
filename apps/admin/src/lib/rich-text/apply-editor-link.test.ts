/**
 * @vitest-environment jsdom
 */
import Link from '@tiptap/extension-link';
import { Editor } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import { describe, expect, it } from 'vitest';
import {
  applyEditorLink,
  canApplyEditorLink,
  captureLinkDialogState,
  normalizeLinkUrl,
} from './apply-editor-link';

function createEditor(content = '<p>hello world</p>') {
  return new Editor({
    extensions: [
      StarterKit.configure({
        heading: false,
        codeBlock: false,
        code: false,
        blockquote: false,
        horizontalRule: false,
      }),
      Link.configure({ openOnClick: false }),
    ],
    content,
  });
}

describe('normalizeLinkUrl', () => {
  it('prepends https when scheme is missing', () => {
    expect(normalizeLinkUrl('example.com/path')).toBe('https://example.com/path');
  });

  it('keeps https and mailto URLs', () => {
    expect(normalizeLinkUrl('https://chisto.mk/news')).toBe('https://chisto.mk/news');
    expect(normalizeLinkUrl('mailto:info@ekohab.mk')).toBe('mailto:info@ekohab.mk');
  });

  it('rejects javascript and data URLs', () => {
    expect(normalizeLinkUrl('javascript:alert(1)')).toBeNull();
    expect(normalizeLinkUrl('data:text/html,<svg>')).toBeNull();
  });
});

describe('applyEditorLink', () => {
  it('links highlighted text using a captured snapshot after focus loss', () => {
    const editor = createEditor('<p>hello world</p>');
    editor.commands.setTextSelection({ from: 1, to: 6 });
    const snapshot = captureLinkDialogState(editor);

    editor.commands.blur();
    const result = applyEditorLink(editor, snapshot, {
      url: 'chisto.mk',
      newTab: true,
      linkText: 'hello',
    });

    expect(result).toEqual({ ok: true });
    expect(editor.getHTML()).toContain('<a');
    expect(editor.getHTML()).toContain('href="https://chisto.mk"');
    expect(editor.getHTML()).toContain('hello');
    editor.destroy();
  });

  it('inserts linked text when selection was empty', () => {
    const editor = createEditor('<p>hello world</p>');
    editor.commands.setTextSelection(6);
    const snapshot = captureLinkDialogState(editor);

    const result = applyEditorLink(editor, snapshot, {
      url: 'https://chisto.mk',
      newTab: false,
      linkText: 'Chisto.mk',
    });

    expect(result).toEqual({ ok: true });
    expect(editor.getHTML()).toContain('href="https://chisto.mk"');
    expect(editor.getHTML()).toContain('Chisto.mk');
    editor.destroy();
  });

  it('requires link text for empty selection inserts', () => {
    const editor = createEditor('<p>hello</p>');
    editor.commands.setTextSelection(6);
    const snapshot = captureLinkDialogState(editor);

    expect(
      applyEditorLink(editor, snapshot, {
        url: 'https://chisto.mk',
        newTab: true,
        linkText: '',
      }),
    ).toEqual({ ok: false, error: 'no_target' });
    editor.destroy();
  });
});

describe('canApplyEditorLink', () => {
  it('allows apply with valid URL on highlighted text', () => {
    const snapshot = { from: 1, to: 6, empty: false, hadLink: false };
    expect(
      canApplyEditorLink(snapshot, { url: 'https://x.test', newTab: true, linkText: 'hello' }),
    ).toBe(true);
  });

  it('requires link text when inserting at caret', () => {
    const snapshot = { from: 6, to: 6, empty: true, hadLink: false };
    expect(
      canApplyEditorLink(snapshot, { url: 'https://x.test', newTab: true, linkText: '' }),
    ).toBe(false);
    expect(
      canApplyEditorLink(snapshot, { url: 'https://x.test', newTab: true, linkText: 'Read more' }),
    ).toBe(true);
  });
});
