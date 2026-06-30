import { getMarkRange } from '@tiptap/core';
import type { Editor } from '@tiptap/react';

/** Plain-text label for the current link selection (highlighted text or link under cursor). */
export function getLinkSelectionText(editor: Editor): string {
  const { from, to, empty } = editor.state.selection;
  if (!empty) {
    return editor.state.doc.textBetween(from, to, ' ').trim();
  }

  const linkType = editor.schema.marks.link;
  if (!linkType) return '';

  const range = getMarkRange(editor.state.selection.$from, linkType);
  if (!range) return '';

  return editor.state.doc.textBetween(range.from, range.to, ' ').trim();
}
