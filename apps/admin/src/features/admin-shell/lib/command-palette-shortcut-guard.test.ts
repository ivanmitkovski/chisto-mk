/**
 * @vitest-environment jsdom
 */
import { describe, expect, it } from 'vitest';
import {
  isCommandPaletteShortcut,
  shouldBlockCommandPaletteShortcut,
} from './command-palette-shortcut-guard';

describe('command palette shortcut guard', () => {
  it('detects cmd/ctrl+k', () => {
    expect(isCommandPaletteShortcut({ key: 'k', metaKey: true, ctrlKey: false })).toBe(true);
    expect(isCommandPaletteShortcut({ key: 'K', metaKey: false, ctrlKey: true })).toBe(true);
    expect(isCommandPaletteShortcut({ key: 'j', metaKey: true, ctrlKey: false })).toBe(false);
  });

  it('allows shortcut on the palette trigger input', () => {
    document.body.innerHTML =
      '<input data-command-palette-trigger readonly class="search" />';
    const input = document.querySelector('input')!;
    expect(shouldBlockCommandPaletteShortcut(input)).toBe(false);
  });

  it('allows shortcut inside the palette panel', () => {
    document.body.innerHTML =
      '<section data-command-palette-panel><input class="query" /></section>';
    const input = document.querySelector('input')!;
    expect(shouldBlockCommandPaletteShortcut(input)).toBe(false);
  });

  it('blocks shortcut in regular editable fields', () => {
    document.body.innerHTML = '<textarea></textarea>';
    const textarea = document.querySelector('textarea')!;
    expect(shouldBlockCommandPaletteShortcut(textarea)).toBe(true);
  });

  it('allows shortcut on read-only inputs outside the palette', () => {
    document.body.innerHTML = '<input readonly value="locked" />';
    const input = document.querySelector('input')!;
    expect(shouldBlockCommandPaletteShortcut(input)).toBe(false);
  });
});
