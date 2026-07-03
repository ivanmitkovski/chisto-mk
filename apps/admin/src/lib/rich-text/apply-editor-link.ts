import type { Editor } from '@tiptap/react';

export type LinkSelectionSnapshot = {
  from: number;
  to: number;
  empty: boolean;
  hadLink: boolean;
  href?: string;
  target?: string | null;
};

export type ApplyEditorLinkInput = {
  url: string;
  newTab: boolean;
  linkText: string;
};

export type ApplyEditorLinkResult =
  | { ok: true }
  | { ok: false; error: 'invalid_url' | 'no_target' | 'command_failed' };

const BLOCKED_SCHEMES = /^(javascript|data|vbscript):/i;

/** Normalize a user-entered URL for TipTap link marks. */
export function normalizeLinkUrl(raw: string): string | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;
  if (BLOCKED_SCHEMES.test(trimmed)) return null;

  const hasScheme = /^[a-z][a-z0-9+.-]*:/i.test(trimmed);
  const normalized = hasScheme ? trimmed : `https://${trimmed}`;
  if (BLOCKED_SCHEMES.test(normalized)) return null;

  try {
    const parsed = new URL(normalized);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:' && parsed.protocol !== 'mailto:') {
      return null;
    }
    return normalized;
  } catch {
    return null;
  }
}

/** Capture editor selection before the link modal steals focus. */
export function captureLinkDialogState(editor: Editor): LinkSelectionSnapshot {
  const { from, to, empty } = editor.state.selection;
  const linkAttrs = editor.getAttributes('link');
  const href = typeof linkAttrs.href === 'string' ? linkAttrs.href : undefined;
  const target = typeof linkAttrs.target === 'string' ? linkAttrs.target : null;

  return {
    from,
    to,
    empty,
    hadLink: Boolean(href),
    href,
    target,
  };
}

export function canApplyEditorLink(
  snapshot: LinkSelectionSnapshot,
  input: ApplyEditorLinkInput,
): boolean {
  const url = input.url.trim();
  if (!url) {
    return snapshot.hadLink || !snapshot.empty;
  }
  if (!snapshot.empty) {
    return normalizeLinkUrl(url) !== null;
  }
  return input.linkText.trim().length > 0 && normalizeLinkUrl(url) !== null;
}

/** Apply or remove a link using a previously captured selection snapshot. */
export function applyEditorLink(
  editor: Editor,
  snapshot: LinkSelectionSnapshot,
  input: ApplyEditorLinkInput,
): ApplyEditorLinkResult {
  const urlRaw = input.url.trim();
  const linkText = input.linkText.trim();

  if (!urlRaw) {
    if (!snapshot.hadLink && snapshot.empty) {
      return { ok: false, error: 'no_target' };
    }
    const removed = editor
      .chain()
      .focus()
      .setTextSelection({ from: snapshot.from, to: snapshot.to })
      .extendMarkRange('link')
      .unsetLink()
      .run();
    return removed ? { ok: true } : { ok: false, error: 'command_failed' };
  }

  const href = normalizeLinkUrl(urlRaw);
  if (!href) {
    return { ok: false, error: 'invalid_url' };
  }

  const linkAttrs = {
    href,
    target: input.newTab ? '_blank' : null,
    rel: 'noopener noreferrer',
  };

  if (!snapshot.empty) {
    const applied = editor
      .chain()
      .focus()
      .setTextSelection({ from: snapshot.from, to: snapshot.to })
      .extendMarkRange('link')
      .setLink(linkAttrs)
      .run();
    return applied ? { ok: true } : { ok: false, error: 'command_failed' };
  }

  if (!linkText) {
    return { ok: false, error: 'no_target' };
  }

  const inserted = editor
    .chain()
    .focus()
    .setTextSelection({ from: snapshot.from, to: snapshot.to })
    .insertContent({
      type: 'text',
      text: linkText,
      marks: [{ type: 'link', attrs: linkAttrs }],
    })
    .run();

  return inserted ? { ok: true } : { ok: false, error: 'command_failed' };
}
