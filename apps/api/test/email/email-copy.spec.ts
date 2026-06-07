/// <reference types="jest" />

import { buildBodyHtml, getCopy } from '../../src/email/util/email-copy';
import type { EmailTemplateId } from '../../src/email/types/email.types';

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
  'admin_invite',
  'admin_moderation_new_report',
  'admin_moderation_event_pending',
  'admin_moderation_ugc_report',
  'admin_moderation_checkin_risk',
];

/** Shared fixture: each template reads only fields it needs */
const ctx: Record<string, unknown> = {
  firstName: 'Sam',
  eventTitle: 'Park cleanup',
  reportNumber: 'CH-000068',
  reportTitle: 'River bank litter',
  siteLabel: 'City park',
  points: 8,
  mergeRole: 'primary',
  commentPreview: 'Looks great',
  reason: 'spam',
  inviteUrl: 'https://example.test/invite',
  roleLabel: 'Moderator',
  expiresAt: new Date().toISOString(),
  actionUrl: 'https://admin.chisto.mk/dashboard/reports?reportId=r1',
  isNewSite: true,
  subjectType: 'safety_issue',
  subjectId: 'subj-1',
  distanceMeters: 420,
  category: 'ILLEGAL_LANDFILL',
  severity: 4,
  address: 'Skopje, MK',
  latitude: 41.9981,
  longitude: 21.4254,
  reporterEmail: 'citizen@example.test',
  submittedAt: '2026-06-05T10:00:00.000Z',
  organizerName: 'Ivan M.',
  scheduledAt: '2026-06-10T09:00:00.000Z',
  endAt: '2026-06-10T12:00:00.000Z',
  eventCategory: 'GENERAL_CLEANUP',
  eventScale: 'MEDIUM',
  siteAddress: 'City Park entrance',
  detailsPreview: 'Repeated spam links in comments',
  reportedAt: '2026-06-05T11:00:00.000Z',
  occurredAt: '2026-06-05T12:00:00.000Z',
};

describe('email-copy', () => {
  const baseUrl = 'https://example.test/app';

  it.each(TEMPLATE_IDS)('template %s has subject, CTA URL and label (en)', (templateId) => {
    const copy = getCopy(templateId, 'en', ctx, baseUrl);
    expect(copy.subject.trim().length).toBeGreaterThan(0);
    expect((copy.ctaUrl ?? '').trim().length).toBeGreaterThan(0);
    expect((copy.ctaLabel ?? '').trim().length).toBeGreaterThan(0);
  });

  it.each(TEMPLATE_IDS)('template %s has subject, CTA URL and label (mk)', (templateId) => {
    const copy = getCopy(templateId, 'mk', ctx, baseUrl);
    expect(copy.subject.trim().length).toBeGreaterThan(0);
    expect((copy.ctaUrl ?? '').trim().length).toBeGreaterThan(0);
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

  it('welcome mk uses correct Macedonian grammar', () => {
    const copy = getCopy('welcome', 'mk', { firstName: 'Иван' }, baseUrl);
    expect(copy.lead).toContain('подготвена');
    expect(copy.lead).not.toContain('подготова');
    expect(copy.lead).toContain('загадувања');
    expect(copy.extraLines?.[0]).toContain('ја креиравте сметката');
    expect(copy.footerNote).toContain('поддршката');
    expect(copy.ctaLabel).toBe('Отвори Chisto.mk');
  });

  it('viewReports mk CTA uses action label', () => {
    const copy = getCopy('report_received', 'mk', ctx, baseUrl);
    expect(copy.ctaLabel).toBe('Прегледај пријави');
  });

  it('report_merged primary mk uses past tense', () => {
    const copy = getCopy('report_merged', 'mk', { ...ctx, mergeRole: 'primary' }, baseUrl);
    expect(copy.lead).toContain('се споија');
    expect(copy.lead).not.toContain('се спојуваат');
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

  it('admin_moderation_ugc_report humanizes enums and uses actionUrl', () => {
    const copy = getCopy('admin_moderation_ugc_report', 'en', ctx, 'https://chisto.mk');
    expect(copy.ctaUrl).toBe(ctx.actionUrl);
    const values = (copy.detailRows ?? []).map((r) => r.value).join(' ');
    expect(values).toContain('Safety issue');
    expect(values).toContain('Spam');
    expect(values).not.toContain('safety_issue');
    expect(copy.extraLines?.[0]).toContain('Repeated spam');
  });

  it('admin_moderation_new_report includes rich detail rows', () => {
    const copy = getCopy('admin_moderation_new_report', 'en', ctx, 'https://chisto.mk');
    const labels = (copy.detailRows ?? []).map((r) => r.label);
    expect(labels).toEqual(
      expect.arrayContaining(['Report', 'Title', 'Category', 'Severity', 'Location', 'Reported by']),
    );
    expect(copy.lead).toContain('CH-000068');
  });

  it('admin_moderation_event_pending includes organizer and schedule', () => {
    const copy = getCopy('admin_moderation_event_pending', 'en', ctx, 'https://chisto.mk');
    const rows = copy.detailRows ?? [];
    expect(rows.some((r) => r.label === 'Organizer' && r.value === 'Ivan M.')).toBe(true);
    expect(rows.some((r) => r.label === 'When')).toBe(true);
    expect(copy.ctaUrl).toBe(ctx.actionUrl);
  });

  it('admin_moderation_checkin_risk includes when row', () => {
    const copy = getCopy('admin_moderation_checkin_risk', 'en', ctx, 'https://chisto.mk');
    expect((copy.detailRows ?? []).some((r) => r.label === 'When')).toBe(true);
  });
});
