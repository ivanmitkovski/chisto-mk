import { describe, expect, it } from 'vitest';
import en from '@/i18n/messages/en/news.json';
import mk from '@/i18n/messages/mk/news.json';
import sq from '@/i18n/messages/sq/news.json';

function flattenKeys(value: unknown, prefix = ''): string[] {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    return prefix ? [prefix] : [];
  }
  return Object.entries(value as Record<string, unknown>).flatMap(([key, child]) => {
    const next = prefix ? `${prefix}.${key}` : key;
    if (child !== null && typeof child === 'object' && !Array.isArray(child)) {
      return flattenKeys(child, next);
    }
    return [next];
  });
}

describe('admin news.json locale parity', () => {
  const enKeys = new Set(flattenKeys(en));
  const mkKeys = new Set(flattenKeys(mk));
  const sqKeys = new Set(flattenKeys(sq));

  const removeBlockDialogKeys = [
    'confirm.removeBlockTitle',
    'confirm.removeBlockBody',
    'confirm.removeBlockBodyWithPreview',
    'confirm.removeBlockCancel',
    'confirm.removeBlockConfirm',
    'confirm.removeBlockPosition',
    'confirm.removeBlockGalleryCount',
    'confirm.removeBlockUndoHint',
  ] as const;

  it('includes remove block dialog keys in en', () => {
    for (const key of removeBlockDialogKeys) {
      expect(enKeys.has(key), key).toBe(true);
    }
  });

  it('mk has the same keys as en', () => {
    const missing = [...enKeys].filter((key) => !mkKeys.has(key));
    const extra = [...mkKeys].filter((key) => !enKeys.has(key));
    expect({ missing, extra }).toEqual({ missing: [], extra: [] });
  });

  it('sq has the same keys as en', () => {
    const missing = [...enKeys].filter((key) => !sqKeys.has(key));
    const extra = [...sqKeys].filter((key) => !enKeys.has(key));
    expect({ missing, extra }).toEqual({ missing: [], extra: [] });
  });
});
