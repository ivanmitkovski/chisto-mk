/// <reference types="jest" />

import { buildBodyHtml, getCopy } from '../../src/email/email-copy';
import type { EmailTemplateId } from '../../src/email/email.types';

const TEMPLATE_IDS: EmailTemplateId[] = [
  'welcome',
  'password_reset',
  'password_changed',
  'report_received',
  'report_approved',
  'report_declined',
  'report_merged',
  'event_approved',
  'event_declined',
  'event_published',
  'event_completed_award',
  'event_completed_no_show',
  'site_upvote',
  'site_comment',
];

/** Shared fixture: each template reads only fields it needs */
const ctx: Record<string, unknown> = {
  firstName: 'Sam',
  eventTitle: 'Park cleanup',
  reportNumber: '#9',
  siteLabel: 'City park',
  points: 8,
  mergeRole: 'primary',
  commentPreview: 'Looks great',
  reason: 'Spam',
};

describe('email-copy', () => {
  const baseUrl = 'https://example.test/app';

  it.each(TEMPLATE_IDS)('template %s has subject, CTA URL and label (en)', (templateId) => {
    const copy = getCopy(templateId, 'en', ctx, baseUrl);
    expect(copy.subject.trim().length).toBeGreaterThan(0);
    expect(copy.ctaUrl).toBe(baseUrl);
    expect((copy.ctaLabel ?? '').trim().length).toBeGreaterThan(0);
  });

  it.each(TEMPLATE_IDS)('template %s has subject, CTA URL and label (mk)', (templateId) => {
    const copy = getCopy(templateId, 'mk', ctx, baseUrl);
    expect(copy.subject.trim().length).toBeGreaterThan(0);
    expect(copy.ctaUrl).toBe(baseUrl);
    expect((copy.ctaLabel ?? '').trim().length).toBeGreaterThan(0);
  });

  it('strips trailing slash from app base URL for CTAs', () => {
    const copy = getCopy('welcome', 'en', ctx, 'https://example.test/x/');
    expect(copy.ctaUrl).toBe('https://example.test/x');
  });

  it('report_approved includes success accent', () => {
    expect(getCopy('report_approved', 'en', ctx, baseUrl).accent).toBe('success');
  });

  it('report_declined includes danger accent', () => {
    expect(getCopy('report_declined', 'en', ctx, baseUrl).accent).toBe('danger');
  });

  it('event_completed templates use warning accent', () => {
    expect(getCopy('event_completed_award', 'en', ctx, baseUrl).accent).toBe('warning');
    expect(getCopy('event_completed_no_show', 'en', ctx, baseUrl).accent).toBe('warning');
  });

  it('buildBodyHtml collapses repeated hyphens before escaping', () => {
    const html = buildBodyHtml({
      subject: '',
      headline: '',
      lead: 'Status: open--pending review',
      ctaUrl: 'https://x',
      ctaLabel: 'Open',
    });
    expect(html).not.toContain('--');
    expect(html).toContain('open-pending');
  });
});
