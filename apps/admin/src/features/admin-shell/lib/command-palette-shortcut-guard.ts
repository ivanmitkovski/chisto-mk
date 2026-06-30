/**
 * Returns true when Cmd/Ctrl+K should not toggle the command palette
 * (e.g. user is typing in a real form field).
 */
export function shouldBlockCommandPaletteShortcut(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) return false;

  if (target.closest('[data-command-palette-trigger], [data-command-palette-panel]')) {
    return false;
  }

  const field = target.closest('input, textarea, select, [contenteditable="true"]');
  if (!field) return false;

  if (field instanceof HTMLInputElement || field instanceof HTMLTextAreaElement) {
    if (field.readOnly || field.disabled) return false;
  }

  if (field instanceof HTMLElement && field.getAttribute('contenteditable') === 'false') {
    return false;
  }

  return true;
}

export function isCommandPaletteShortcut(event: Pick<KeyboardEvent, 'key' | 'metaKey' | 'ctrlKey'>): boolean {
  return (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k';
}
