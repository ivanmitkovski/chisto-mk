import { DEFAULT_EMAIL_APP_BASE_URL, EMAIL_BRAND } from './email.constants';
import { buildDetailCardHtml, EMAIL_LAYOUT, type EmailAccent } from './email-layout';
import type { EmailLocale, EmailTemplateId } from './email.types';

export type EmailCopyBlock = {
  subject: string;
  headline: string;
  lead: string;
  /** Optional extra paragraphs (plain text, escaped in template) */
  extraLines?: string[] | undefined;
  ctaLabel?: string | undefined;
  ctaUrl?: string | undefined;
  footerNote?: string | undefined;
  detailRows?: { label: string; value: string }[] | undefined;
  accent?: EmailAccent | undefined;
};

function esc(s: string): string {
  const collapsed = s.replace(/-+/g, '-');
  return collapsed
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

const CTA_LABELS = {
  openSite: { en: 'Open Chisto.mk', mk: 'Отвори Chisto.mk' },
  secureAccount: { en: 'Secure your account', mk: 'Заштити ја сметката' },
  viewReports: { en: 'View your reports', mk: 'Вашите пријави' },
  viewReport: { en: 'View report', mk: 'Види пријава' },
  openEvent: { en: 'Open event', mk: 'Отвори настан' },
  openApp: { en: 'Open in app', mk: 'Отвори во апликација' },
} as const;

function lbl(en: boolean, pair: { en: string; mk: string }): string {
  return en ? pair.en : pair.mk;
}

type CopyFields = Pick<EmailCopyBlock, 'subject' | 'headline' | 'lead'> &
  Partial<Pick<EmailCopyBlock, 'extraLines' | 'footerNote' | 'detailRows' | 'accent'>>;

function withCta(
  block: CopyFields,
  appBaseUrl: string,
  en: boolean,
  ctaKey: keyof typeof CTA_LABELS,
): EmailCopyBlock {
  return {
    subject: block.subject,
    headline: block.headline,
    lead: block.lead,
    ...(block.extraLines !== undefined ? { extraLines: block.extraLines } : {}),
    ...(block.footerNote !== undefined ? { footerNote: block.footerNote } : {}),
    ...(block.detailRows !== undefined ? { detailRows: block.detailRows } : {}),
    ...(block.accent !== undefined ? { accent: block.accent } : {}),
    ctaUrl: appBaseUrl,
    ctaLabel: lbl(en, CTA_LABELS[ctaKey]),
  };
}

function reportDetailRow(en: boolean, reportNumber: string): { label: string; value: string }[] | undefined {
  if (!reportNumber) return undefined;
  return [{ label: en ? 'Report' : 'Пријава', value: reportNumber }];
}

function eventDetailRows(en: boolean, eventTitle: string): { label: string; value: string }[] | undefined {
  if (!eventTitle) return undefined;
  return [{ label: en ? 'Event' : 'Настан', value: eventTitle }];
}

function siteDetailRows(en: boolean, siteLabel: string): { label: string; value: string }[] | undefined {
  if (!siteLabel) return undefined;
  return [{ label: en ? 'Site' : 'Локалитет', value: siteLabel }];
}

export function linesToHtml(lines: string[]): string {
  return lines.map((l) => `<p style="margin:0 0 12px 0;">${esc(l)}</p>`).join('');
}

export function buildBodyHtml(block: EmailCopyBlock): string {
  const parts: string[] = [];
  parts.push(
    `<p style="margin:0 0 ${EMAIL_LAYOUT.sectionGapPx}px 0;font-size:16px;line-height:1.45;color:${EMAIL_BRAND.textSecondary};">${esc(block.lead)}</p>`,
  );
  if (block.detailRows?.length) {
    parts.push(buildDetailCardHtml(block.detailRows));
  }
  if (block.extraLines?.length) {
    parts.push(linesToHtml(block.extraLines));
  }
  if (block.footerNote) {
    parts.push(
      `<p style="margin:16px 0 0 0;font-size:14px;line-height:1.4;color:${EMAIL_BRAND.textMuted};">${esc(block.footerNote)}</p>`,
    );
  }
  return parts.join('');
}

export function subjectFor(
  templateId: EmailTemplateId,
  locale: EmailLocale,
  ctx: Record<string, unknown>,
  appBaseUrl: string = DEFAULT_EMAIL_APP_BASE_URL,
): string {
  return getCopy(templateId, locale, ctx, appBaseUrl).subject;
}

export function getCopy(
  templateId: EmailTemplateId,
  locale: EmailLocale,
  ctx: Record<string, unknown>,
  appBaseUrl: string,
): EmailCopyBlock {
  const en = locale === 'en';
  const url = appBaseUrl.replace(/\/+$/, '') || DEFAULT_EMAIL_APP_BASE_URL;
  const firstName = typeof ctx.firstName === 'string' ? ctx.firstName : '';
  const eventTitle = typeof ctx.eventTitle === 'string' ? ctx.eventTitle : '';
  const reportNumber = typeof ctx.reportNumber === 'string' ? ctx.reportNumber : '';
  const siteLabel = typeof ctx.siteLabel === 'string' ? ctx.siteLabel : '';
  const points = typeof ctx.points === 'number' ? ctx.points : 0;
  const mergeRole = typeof ctx.mergeRole === 'string' ? ctx.mergeRole : '';
  const commentPreview = typeof ctx.commentPreview === 'string' ? ctx.commentPreview : '';

  switch (templateId) {
    case 'welcome':
      return en
        ? withCta(
            {
              subject: 'Welcome to Chisto.mk',
              headline: `Welcome${firstName ? `, ${firstName}` : ''}`,
              lead: 'Your account is ready. Report pollution, follow sites, and join cleanup events in your community.',
              extraLines: [
                'This message was sent because you created an account in the Chisto.mk app.',
              ],
              footerNote: 'If you did not sign up, you can ignore this email or contact support.',
            },
            url,
            en,
            'openSite',
          )
        : withCta(
            {
              subject: 'Добредојдовте на Chisto.mk',
              headline: `Добредојдовте${firstName ? `, ${firstName}` : ''}`,
              lead: 'Вашата сметка е подготова. Пријавувајте загадување, следете локалитети и учествувајте во акции за чистење.',
              extraLines: ['Оваа порака е испратена бидејќи креиравте сметка во апликацијата Chisto.mk.'],
              footerNote: 'Ако не се регистриравте, игнорирајте ја пораката или контактирајте поддршка.',
            },
            url,
            en,
            'openSite',
          );

    case 'password_reset': {
      const resetUrl = typeof ctx.resetUrl === 'string' ? ctx.resetUrl : url;
      return en
        ? withCta(
            {
              subject: 'Reset your Chisto.mk password',
              headline: 'Password reset requested',
              lead: 'Use the button below to choose a new password. This link expires in 30 minutes.',
              extraLines: [
                'If you did not request a reset, you can ignore this email. Your password will stay the same.',
              ],
            },
            resetUrl,
            en,
            'secureAccount',
          )
        : withCta(
            {
              subject: 'Ресетирајте ја лозинката на Chisto.mk',
              headline: 'Барано ресетирање на лозинка',
              lead: 'Користете го копчето подолу за нова лозинка. Врската истекува за 30 минути.',
              extraLines: [
                'Ако не сте побарале ресетирање, игнорирајте ја пораката. Лозинката останува иста.',
              ],
            },
            resetUrl,
            en,
            'secureAccount',
          );
    }

    case 'password_changed':
      return en
        ? withCta(
            {
              subject: 'Your Chisto.mk password was changed',
              headline: 'Password updated',
              lead: 'The password for your Chisto.mk account was just changed.',
              extraLines: [
                'If this was you, no action is needed.',
                'If you did not make this change, reset your password from the app and contact support immediately.',
              ],
            },
            url,
            en,
            'secureAccount',
          )
        : withCta(
            {
              subject: 'Лозинката на Chisto.mk е променета',
              headline: 'Лозинката е ажурирана',
              lead: 'Лозинката за вашата сметка на Chisto.mk штотуку е променета.',
              extraLines: [
                'Ако ова сте вие, не е потребна никаква акција.',
                'Ако не сте вие, ресетирајте ја лозинката од апликацијата и веднаш контактирајте поддршка.',
              ],
            },
            url,
            en,
            'secureAccount',
          );

    case 'report_received':
      return en
        ? withCta(
            {
              subject: reportNumber ? `We received your report ${reportNumber}` : 'We received your report',
              headline: 'Thank you for reporting',
              lead: reportNumber
                ? `We received your report ${reportNumber}. Our team will review it soon.`
                : 'We received your report. Our team will review it soon.',
              detailRows: reportDetailRow(en, reportNumber),
            },
            url,
            en,
            'viewReports',
          )
        : withCta(
            {
              subject: reportNumber ? `Ја примивме вашата пријава ${reportNumber}` : 'Ја примивме вашата пријава',
              headline: 'Ви благодариме за пријавата',
              lead: reportNumber
                ? `Ја примивме вашата пријава ${reportNumber}. Нашиот тим наскоро ќе ја разгледа.`
                : 'Ја примивме вашата пријава. Нашиот тим наскоро ќе ја разгледа.',
              detailRows: reportDetailRow(en, reportNumber),
            },
            url,
            en,
            'viewReports',
          );

    case 'report_approved':
      return en
        ? withCta(
            {
              subject: reportNumber ? `Report ${reportNumber} approved` : 'Your report was approved',
              headline: 'Report approved',
              lead: reportNumber
                ? `Good news: report ${reportNumber} was approved.`
                : 'Good news: your report was approved.',
              detailRows: reportDetailRow(en, reportNumber),
              accent: 'success',
            },
            url,
            en,
            'viewReport',
          )
        : withCta(
            {
              subject: reportNumber ? `Пријавата ${reportNumber} е одобрена` : 'Вашата пријава е одобрена',
              headline: 'Пријавата е одобрена',
              lead: reportNumber
                ? `Добри вести: пријавата ${reportNumber} е одобрена.`
                : 'Добри вести: вашата пријава е одобрена.',
              detailRows: reportDetailRow(en, reportNumber),
              accent: 'success',
            },
            url,
            en,
            'viewReport',
          );

    case 'report_declined': {
      const reasonNote =
        typeof ctx.reason === 'string' && ctx.reason.trim()
          ? ctx.reason.trim()
          : '';
      return en
        ? withCta(
            {
              subject: reportNumber ? `Update on report ${reportNumber}` : 'Update on your report',
              headline: 'Report not published',
              lead: reportNumber
                ? `Report ${reportNumber} was not kept in the public feed.`
                : 'Your report was not kept in the public feed.',
              detailRows: reportDetailRow(en, reportNumber),
              ...(reasonNote ? { footerNote: `Moderator note: ${reasonNote}` } : {}),
              accent: 'danger',
            },
            url,
            en,
            'viewReport',
          )
        : withCta(
            {
              subject: reportNumber ? `Ажурирање за пријавата ${reportNumber}` : 'Ажурирање за вашата пријава',
              headline: 'Пријавата не е објавена',
              lead: reportNumber
                ? `Пријавата ${reportNumber} не е задржана во јавниот приказ.`
                : 'Вашата пријава не е задржана во јавниот приказ.',
              detailRows: reportDetailRow(en, reportNumber),
              ...(reasonNote ? { footerNote: `Забелешка: ${reasonNote}` } : {}),
              accent: 'danger',
            },
            url,
            en,
            'viewReport',
          );
    }

    case 'report_merged': {
      if (mergeRole === 'primary') {
        return en
          ? withCta(
              {
                subject: 'Duplicate reports merged',
                headline: 'Reports merged',
                lead: reportNumber
                  ? `Similar submissions were merged into your report ${reportNumber}.`
                  : 'Similar submissions were merged into your report.',
                detailRows: reportDetailRow(en, reportNumber),
              },
              url,
              en,
              'viewReport',
            )
          : withCta(
              {
                subject: 'Спојување на дупликат пријави',
                headline: 'Пријавите се споени',
                lead: reportNumber
                  ? `Слични пријави се спојуваат во вашата пријава ${reportNumber}.`
                  : 'Слични пријави се спојуваат во вашата пријава.',
                detailRows: reportDetailRow(en, reportNumber),
              },
              url,
              en,
              'viewReport',
            );
      }
      if (mergeRole === 'merged_child') {
        return en
          ? withCta(
              {
                subject: 'Your report was merged',
                headline: 'Report merged',
                lead: reportNumber
                  ? `Your submission was merged into ${reportNumber}.`
                  : 'Your submission was merged into another report.',
                detailRows: reportDetailRow(en, reportNumber),
              },
              url,
              en,
              'viewReport',
            )
          : withCta(
              {
                subject: 'Вашата пријава е споена',
                headline: 'Пријавата е споена',
                lead: reportNumber
                  ? `Вашата пријава е споена со ${reportNumber}.`
                  : 'Вашата пријава е споена со друга пријава.',
                detailRows: reportDetailRow(en, reportNumber),
              },
              url,
              en,
              'viewReport',
            );
      }
      return en
        ? withCta(
            {
              subject: 'Co-reporter credit',
              headline: 'You are credited',
              lead: reportNumber
                ? `You are credited as a co-reporter on ${reportNumber}.`
                : 'You are credited as a co-reporter.',
              detailRows: reportDetailRow(en, reportNumber),
            },
            url,
            en,
            'viewReport',
          )
        : withCta(
            {
              subject: 'Ко-пријавувач',
              headline: 'Добивте кредит',
              lead: reportNumber
                ? `Вие сте кредитирани како ко-пријавувач на ${reportNumber}.`
                : 'Вие сте кредитирани како ко-пријавувач.',
              detailRows: reportDetailRow(en, reportNumber),
            },
            url,
            en,
            'viewReport',
          );
    }

    case 'event_approved':
      return en
        ? withCta(
            {
              subject: 'Your cleanup event was approved',
              headline: 'Event approved',
              lead: eventTitle ? `“${eventTitle}” is approved and visible to volunteers.` : 'Your event is approved and visible to volunteers.',
              detailRows: eventDetailRows(en, eventTitle),
            },
            url,
            en,
            'openEvent',
          )
        : withCta(
            {
              subject: 'Вашиот настан за чистење е одобрен',
              headline: 'Настанот е одобрен',
              lead: eventTitle ? `«${eventTitle}» е одобрен и видлив за доброволците.` : 'Настанот е одобрен и видлив за доброволците.',
              detailRows: eventDetailRows(en, eventTitle),
            },
            url,
            en,
            'openEvent',
          );

    case 'event_declined':
      return en
        ? withCta(
            {
              subject: 'Your cleanup event was not approved',
              headline: 'Event not approved',
              lead: eventTitle
                ? `“${eventTitle}” did not meet the criteria. You can edit and submit again from the app.`
                : 'Your event did not meet the criteria. You can edit and submit again from the app.',
              detailRows: eventDetailRows(en, eventTitle),
            },
            url,
            en,
            'openEvent',
          )
        : withCta(
            {
              subject: 'Настанот не е одобрен',
              headline: 'Настанот не е одобрен',
              lead: eventTitle
                ? `«${eventTitle}» не ги исполни критериумите. Уредете и поднесете повторно од апликацијата.`
                : 'Настанот не ги исполни критериумите. Уредете и поднесете повторно од апликацијата.',
              detailRows: eventDetailRows(en, eventTitle),
            },
            url,
            en,
            'openEvent',
          );

    case 'event_published':
      return en
        ? withCta(
            {
              subject: 'New cleanup event',
              headline: 'New event near a site you follow',
              lead: eventTitle
                ? `${eventTitle}: a new cleanup is open at a site you follow.`
                : 'A new cleanup event is open at a site you follow.',
              detailRows: eventDetailRows(en, eventTitle),
            },
            url,
            en,
            'openEvent',
          )
        : withCta(
            {
              subject: 'Нов настан за чистење',
              headline: 'Нов настан кај зачувана локација',
              lead: eventTitle
                ? `${eventTitle}: отворен е нов чистење настан кај зачувана локација.`
                : 'Отворен е нов чистење настан кај зачувана локација.',
              detailRows: eventDetailRows(en, eventTitle),
            },
            url,
            en,
            'openEvent',
          );

    case 'event_completed_award': {
      const rows: { label: string; value: string }[] = [];
      if (eventTitle) rows.push({ label: en ? 'Event' : 'Настан', value: eventTitle });
      rows.push({ label: en ? 'Points' : 'Поени', value: String(points) });
      return en
        ? withCta(
            {
              subject: 'Event completed: points earned',
              headline: 'Thanks for joining',
              lead: eventTitle
                ? `You earned ${points} points for taking part in “${eventTitle}”.`
                : `You earned ${points} points for taking part in the event.`,
              detailRows: rows,
              accent: 'warning',
            },
            url,
            en,
            'openEvent',
          )
        : withCta(
            {
              subject: 'Настанот заврши: освоени поени',
              headline: 'Ви благодариме за учеството',
              lead: eventTitle
                ? `Освоивте ${points} поени за учество во „${eventTitle}“.`
                : `Освоивте ${points} поени за учество во настанот.`,
              detailRows: rows,
              accent: 'warning',
            },
            url,
            en,
            'openEvent',
          );
    }

    case 'event_completed_no_show':
      return en
        ? withCta(
            {
              subject: 'Event completed: check-in update',
              headline: 'Points adjusted',
              lead: eventTitle
                ? `Your join bonus for “${eventTitle}” was removed because no check-in was recorded.`
                : 'Your join bonus was removed because no check-in was recorded.',
              detailRows: eventDetailRows(en, eventTitle),
              accent: 'warning',
            },
            url,
            en,
            'openEvent',
          )
        : withCta(
            {
              subject: 'Настанот заврши: ажурирање на поени',
              headline: 'Поените се прилагодени',
              lead: eventTitle
                ? `Вашиот бонус за пријавување за „${eventTitle}“ е отстранет бидејќи нема зачленување.`
                : 'Вашиот бонус за пријавување е отстранет бидејќи нема зачленување.',
              detailRows: eventDetailRows(en, eventTitle),
              accent: 'warning',
            },
            url,
            en,
            'openEvent',
          );

    case 'site_upvote':
      return en
        ? withCta(
            {
              subject: 'New upvote on your site',
              headline: 'Someone supported your report',
              lead: siteLabel
                ? `Your reported site (${siteLabel}) received a new upvote.`
                : 'A site you reported received a new upvote.',
              detailRows: siteDetailRows(en, siteLabel),
            },
            url,
            en,
            'openApp',
          )
        : withCta(
            {
              subject: 'Ново гласање на локалитет',
              headline: 'Некој го поддржа локалитетот',
              lead: siteLabel
                ? `Локалитетот што го пријавивте (${siteLabel}) доби ново гласање.`
                : 'Локалитетот што го пријавивте доби ново гласање.',
              detailRows: siteDetailRows(en, siteLabel),
            },
            url,
            en,
            'openApp',
          );

    case 'site_comment':
      return en
        ? withCta(
            {
              subject: 'New comment on your site',
              headline: 'New comment',
              lead: commentPreview
                ? `New comment: “${commentPreview}”`
                : 'Someone commented on a site you reported.',
              detailRows: siteDetailRows(en, siteLabel),
            },
            url,
            en,
            'openApp',
          )
        : withCta(
            {
              subject: 'Нов коментар на локалитет',
              headline: 'Нов коментар',
              lead: commentPreview
                ? `Нов коментар: „${commentPreview}"`
                : 'Некој коментираше на локалитет што го пријавивте.',
              detailRows: siteDetailRows(en, siteLabel),
            },
            url,
            en,
            'openApp',
          );

    default:
      return en
        ? withCta(
            { subject: 'Chisto.mk', headline: 'Update', lead: 'You have a new update in Chisto.mk.' },
            url,
            en,
            'openSite',
          )
        : withCta(
            { subject: 'Chisto.mk', headline: 'Ажурирање', lead: 'Имате ново ажурирање на Chisto.mk.' },
            url,
            en,
            'openSite',
          );
  }
}
