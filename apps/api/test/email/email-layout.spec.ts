/// <reference types="jest" />

import { EMAIL_BRAND } from '../../src/email/constants/email.constants';
import {
  accentBorderColor,
  buildDetailCardHtml,
  EMAIL_LAYOUT,
  type EmailAccent,
} from '../../src/email/util/email-layout';

describe('email-layout', () => {
  it('buildDetailCardHtml escapes HTML in labels and values', () => {
    const html = buildDetailCardHtml([
      { label: '<b>x</b>', value: 'a & b' },
      { label: 'Report', value: '<script>' },
    ]);
    expect(html).toContain('&lt;b&gt;x&lt;/b&gt;');
    expect(html).toContain('a &amp; b');
    expect(html).toContain('&lt;script&gt;');
    expect(html).not.toContain('<script>');
    expect(html).toContain(EMAIL_BRAND.detailSurface);
    expect(html).toContain(`border-radius:${EMAIL_LAYOUT.ctaRadiusPx}px`);
  });

  it('buildDetailCardHtml collapses repeated hyphens in copy', () => {
    const html = buildDetailCardHtml([{ label: 'Note', value: 'Spam--duplicate' }]);
    expect(html).not.toContain('--');
    expect(html).toContain('Spam-duplicate');
  });

  it('accentBorderColor maps variants to brand tokens', () => {
    const cases: [EmailAccent, string][] = [
      ['success', EMAIL_BRAND.primaryDark],
      ['danger', EMAIL_BRAND.danger],
      ['info', EMAIL_BRAND.info],
      ['warning', EMAIL_BRAND.warning],
      ['none', 'transparent'],
    ];
    for (const [accent, hex] of cases) {
      expect(accentBorderColor(accent)).toBe(hex);
    }
  });
});
