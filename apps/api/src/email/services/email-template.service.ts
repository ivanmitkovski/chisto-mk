import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';
import * as Handlebars from 'handlebars';
import { EMAIL_BRAND } from '../constants/email.constants';
import { buildBodyHtml, getCopy, getEmailShellCopy, type EmailCopyBlock } from '../util/email-copy';
import { accentBorderColor, emailTemplateLayoutVars } from '../util/email-layout';
import type { EmailLocale, EmailTemplateId } from '../types/email.types';

export type RenderEmailInput = {
  templateId: EmailTemplateId;
  locale: EmailLocale;
  /** Copy context (report number, titles, …) */
  context: Record<string, unknown>;
  prefsUrl: string;
  unsubscribeUrl: string;
  /** Resolved HTTPS origin for CTAs (no trailing slash). */
  appBaseUrl: string;
  /** Optional logo URL over HTTPS (omit image when empty). */
  logoUrl: string;
};

function computePreheader(copy: EmailCopyBlock): string {
  const lead = copy.lead.trim();
  const subj = copy.subject.trim();
  const head = copy.headline.trim();
  if (lead.length > 0 && lead !== subj && !subj.includes(lead.slice(0, Math.min(lead.length, 24)))) {
    return lead.length > 120 ? `${lead.slice(0, 117)}…` : lead;
  }
  if (head.length > 0 && head !== subj) {
    return head.length > 120 ? `${head.slice(0, 117)}…` : head;
  }
  const suffix = ' · Chisto.mk';
  const room = 120 - suffix.length;
  return subj.length > room ? `${subj.slice(0, Math.max(0, room - 1))}…${suffix}` : `${subj}${suffix}`;
}

@Injectable()
export class EmailTemplateService implements OnModuleInit {
  private readonly logger = new Logger(EmailTemplateService.name);
  private baseTemplate!: HandlebarsTemplateDelegate<Record<string, unknown>>;

  onModuleInit(): void {
    const candidates = [
      join(__dirname, 'templates', 'base.hbs'),
      join(process.cwd(), 'src', 'email', 'templates', 'base.hbs'),
    ];
    let src: string | null = null;
    for (const p of candidates) {
      try {
        src = readFileSync(p, 'utf8');
        break;
      } catch {
        // try next
      }
    }
    if (!src) {
      this.logger.error('base.hbs not found; email HTML rendering disabled');
      return;
    }
    this.baseTemplate = Handlebars.compile(src);
  }

  render(input: RenderEmailInput): { html: string; text: string; preheader: string; subject: string } {
    const copy = getCopy(input.templateId, input.locale, input.context, input.appBaseUrl);
    const bodyHtml = buildBodyHtml(copy);
    const year = new Date().getUTCFullYear();
    const accentHex = accentBorderColor(copy.accent ?? 'none');
    const showAccentBar = accentHex !== 'transparent';
    const preheader = computePreheader(copy);
    const layout = emailTemplateLayoutVars();
    const shell = getEmailShellCopy(input.locale);

    const html =
      this.baseTemplate != null
        ? this.baseTemplate({
            locale: input.locale,
            logoUrl: input.logoUrl.trim(),
            preheader,
            headline: copy.headline,
            bodyHtml,
            ctaUrl: copy.ctaUrl ?? '',
            ctaLabel: copy.ctaLabel ?? 'Open Chisto.mk',
            prefsUrl: input.prefsUrl,
            unsubscribeUrl: input.unsubscribeUrl,
            footerDisclaimer: shell.footerDisclaimer,
            footerPrefsLabel: shell.footerPrefsLabel,
            footerUnsubscribeLabel: shell.footerUnsubscribeLabel,
            year,
            showAccentBar,
            accentHex,
            ...layout,
            brandPrimary: EMAIL_BRAND.primary,
            brandPrimaryDark: EMAIL_BRAND.primaryDark,
            brandAppBackground: EMAIL_BRAND.appBackground,
            brandPanel: EMAIL_BRAND.panel,
            brandTextPrimary: EMAIL_BRAND.textPrimary,
            brandTextSecondary: EMAIL_BRAND.textSecondary,
            brandTextMuted: EMAIL_BRAND.textMuted,
            brandDivider: EMAIL_BRAND.divider,
            brandFontStack: EMAIL_BRAND.fontStack,
            ctaBg: EMAIL_BRAND.primary,
            ctaHoverBg: EMAIL_BRAND.primaryDark,
          })
        : this.fallbackHtml(copy, bodyHtml, input.prefsUrl, input.unsubscribeUrl, year);

    const textLines = [copy.headline, '', copy.lead, ...(copy.extraLines ?? [])];
    if (copy.footerNote) {
      textLines.push('', copy.footerNote);
    }
    if (copy.ctaUrl && copy.ctaLabel) {
      textLines.push('', `${copy.ctaLabel}: ${copy.ctaUrl}`);
    }
    textLines.push(
      '',
      `${shell.textPrefsPrefix}: ${input.prefsUrl}`,
      `${shell.textUnsubscribePrefix}: ${input.unsubscribeUrl}`,
    );
    return { html, text: textLines.join('\n'), preheader, subject: copy.subject };
  }

  private fallbackHtml(
    copy: EmailCopyBlock,
    bodyHtml: string,
    prefsUrl: string,
    unsubscribeUrl: string,
    year: number,
  ): string {
    return `<!DOCTYPE html><html><body style="font-family:${EMAIL_BRAND.fontStack};background:${EMAIL_BRAND.appBackground};"><div style="max-width:600px;margin:0 auto;background:${EMAIL_BRAND.panel};padding:24px;"><h1>${copy.headline}</h1>${bodyHtml}<p><a href="${prefsUrl}">Preferences</a> · <a href="${unsubscribeUrl}">Unsubscribe</a></p><p>© ${year} Chisto.mk</p></div></body></html>`;
  }
}
