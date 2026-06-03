/// <reference types="jest" />

import { EMAIL_BRAND } from '../../src/email/constants/email.constants';
import { EmailTemplateService } from '../../src/email/services/email-template.service';

describe('EmailTemplateService', () => {
  let svc: EmailTemplateService;

  const baseInput = {
    prefsUrl: 'https://chisto.mk/prefs',
    unsubscribeUrl: 'https://api.chisto.mk/notifications/email/unsubscribe?token=x',
    appBaseUrl: 'https://app.example.test',
    logoUrl: '',
  };

  beforeEach(() => {
    svc = new EmailTemplateService();
    svc.onModuleInit();
  });

  it('renders welcome email for mk and en', () => {
    const mk = svc.render({
      templateId: 'welcome',
      locale: 'mk',
      context: { firstName: 'Ана' },
      ...baseInput,
    });
    expect(mk.subject).toBeTruthy();
    expect(mk.html).toContain('Ана');
    expect(mk.html).toContain('https://chisto.mk/prefs');
    expect(mk.text).toContain('Отпиши се:');
    expect(mk.html).toContain('Поставки за известувања');
    expect(mk.html).toContain('Отпиши се од вакви пораки');
    expect(mk.html).toContain('lang="mk"');
    expect(mk.html).toContain(baseInput.appBaseUrl);

    const en = svc.render({
      templateId: 'welcome',
      locale: 'en',
      context: { firstName: 'Ana' },
      ...baseInput,
    });
    expect(en.subject.toLowerCase()).toContain('welcome');
    expect(en.html).toContain('Ana');
    expect(en.html).toContain('lang="en"');
  });

  it('includes CTA href to appBaseUrl and default CTA label', () => {
    const r = svc.render({
      templateId: 'welcome',
      locale: 'en',
      context: { firstName: 'Pat' },
      ...baseInput,
    });
    expect(r.html).toContain(`href="${baseInput.appBaseUrl}"`);
  });

  it('embeds logo when logoUrl is set', () => {
    const logo = 'https://cdn.example.test/brand/logo.png';
    const r = svc.render({
      templateId: 'welcome',
      locale: 'en',
      context: { firstName: 'Pat' },
      ...baseInput,
      logoUrl: logo,
    });
    expect(r.html).toContain(`src="${logo}"`);
    expect(r.html).toContain('width="28"');
    expect(r.html).toContain('height="32"');
    expect(r.html).toContain('Chisto<span');
  });

  it('renders report_approved detail card and success accent bar', () => {
    const r = svc.render({
      templateId: 'report_approved',
      locale: 'en',
      context: { reportNumber: '#99' },
      ...baseInput,
    });
    expect(r.html).toContain('#99');
    expect(r.html).toContain('Report');
    expect(r.html).toContain(EMAIL_BRAND.primaryDark);
  });

  it('renders report_declined with moderator note in footer', () => {
    const r = svc.render({
      templateId: 'report_declined',
      locale: 'en',
      context: { reportNumber: '#99', reason: 'Duplicate submission' },
      ...baseInput,
    });
    expect(r.html).toContain('Duplicate submission');
    expect(r.text).toContain('Moderator note:');
    expect(r.html).toContain(EMAIL_BRAND.danger);
  });
});
