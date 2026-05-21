/**
 * Local HTML preview for transactional emails (no HTTP route).
 * Usage from apps/api: pnpm email:preview [templateId]
 * Output: tmp/email-preview-<templateId>.html
 */
import { mkdirSync, writeFileSync } from 'fs';
import { join } from 'path';
import { resolveEmailLogoSrc } from '../src/email/email-logo';
import { EmailTemplateService } from '../src/email/email-template.service';
import type { EmailTemplateId } from '../src/email/email.types';

const TEMPLATE_IDS: EmailTemplateId[] = [
  'welcome',
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

const sampleContext: Record<string, unknown> = {
  firstName: 'Alex',
  eventTitle: 'River cleanup · Saturday',
  reportNumber: '#CM-2042',
  siteLabel: 'Vardar riverbank',
  points: 25,
  mergeRole: 'primary',
  commentPreview: 'Thanks for organizing this!',
  reason: 'Duplicate submission: merged with an existing report.',
};

function main(): void {
  const arg = process.argv[2]?.trim();
  const ids = arg && TEMPLATE_IDS.includes(arg as EmailTemplateId) ? [arg as EmailTemplateId] : TEMPLATE_IDS;

  const svc = new EmailTemplateService();
  svc.onModuleInit();

  const outDir = join(process.cwd(), 'tmp');
  mkdirSync(outDir, { recursive: true });

  const prefsUrl = 'https://chisto.mk/account/notifications';
  const unsubscribeUrl = 'https://api.chisto.mk/notifications/email/unsubscribe?token=preview';
  const appBaseUrl = 'https://chisto.mk';
  const logoUrl = resolveEmailLogoSrc({});

  for (const templateId of ids) {
    for (const locale of ['en', 'mk'] as const) {
      const { html, subject } = svc.render({
        templateId,
        locale,
        context: sampleContext,
        prefsUrl,
        unsubscribeUrl,
        appBaseUrl,
        logoUrl,
      });
      const suffix = `${templateId}-${locale}`;
      const file = join(outDir, `email-preview-${suffix}.html`);
      writeFileSync(file, `<!-- Subject: ${subject} -->\n${html}`, 'utf8');
      process.stdout.write(`Wrote ${file}\n`);
    }
  }
}

main();
