import { DEFAULT_EMAIL_APP_BASE_URL, EMAIL_BRAND } from '../constants/email.constants';
import { buildDetailCardHtml, EMAIL_LAYOUT, type EmailAccent } from './email-layout';
import { formatDurationMinutes } from '../../common/i18n/duration-copy';
import { OTP_EXPIRES_SECONDS } from '../../auth/constants/auth.constants';
import type { EmailLocale, EmailTemplateId } from '../types/email.types';
import { formatDateRange, formatDateTime } from './email-datetime';
import {
  formatLocationLabel,
  humanizeEventCategory,
  humanizeEventScale,
  humanizeReportCategory,
  humanizeReportSeverity,
  humanizeUgcReason,
  humanizeUgcSubjectType,
  truncatePreview,
} from './email-labels';

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
  viewReports: { en: 'View your reports', mk: 'Прегледај пријави' },
  viewReport: { en: 'View report', mk: 'Види пријава' },
  openEvent: { en: 'Open event', mk: 'Отвори настан' },
  openApp: { en: 'Open in app', mk: 'Отвори во апликација' },
  acceptInvite: { en: 'Accept invite', mk: 'Прифати покана' },
  reviewInAdmin: { en: 'Review in admin', mk: 'Прегледај во админ' },
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

const BODY_P_STYLE = `margin:0 0 ${EMAIL_LAYOUT.sectionGapPx}px 0;font-size:16px;line-height:1.5;color:${EMAIL_BRAND.textSecondary};`;
const EXTRA_P_STYLE = `margin:0 0 12px 0;font-size:16px;line-height:1.5;color:${EMAIL_BRAND.textSecondary};`;
const FOOTER_NOTE_STYLE = `margin:16px 0 0 0;font-size:14px;line-height:1.45;color:${EMAIL_BRAND.textMuted};`;

export type EmailShellCopy = {
  footerDisclaimer: string;
  footerPrefsLabel: string;
  footerUnsubscribeLabel: string;
  textPrefsPrefix: string;
  textUnsubscribePrefix: string;
};

export function getEmailShellCopy(locale: EmailLocale): EmailShellCopy {
  if (locale === 'en') {
    return {
      footerDisclaimer:
        'Chisto.mk: civic environmental platform. You received this transactional email because of activity on your account.',
      footerPrefsLabel: 'Manage preferences',
      footerUnsubscribeLabel: 'Unsubscribe from this type',
      textPrefsPrefix: 'Manage preferences',
      textUnsubscribePrefix: 'Unsubscribe',
    };
  }
  return {
    footerDisclaimer:
      'Chisto.mk: граѓанска еколошка платформа. Оваа трансакциска порака е испратена поради активност на вашата сметка.',
    footerPrefsLabel: 'Поставки за известувања',
    footerUnsubscribeLabel: 'Отпиши се од вакви пораки',
    textPrefsPrefix: 'Поставки за известувања',
    textUnsubscribePrefix: 'Отпиши се',
  };
}

export function linesToHtml(lines: string[]): string {
  return lines
    .map((l) => `<p class="cm-text" style="${EXTRA_P_STYLE}">${esc(l)}</p>`)
    .join('');
}

export function buildBodyHtml(block: EmailCopyBlock): string {
  const parts: string[] = [];
  parts.push(`<p class="cm-text" style="${BODY_P_STYLE}">${esc(block.lead)}</p>`);
  if (block.detailRows?.length) {
    parts.push(buildDetailCardHtml(block.detailRows));
  }
  if (block.extraLines?.length) {
    parts.push(linesToHtml(block.extraLines));
  }
  if (block.footerNote) {
    parts.push(`<p class="cm-muted" style="${FOOTER_NOTE_STYLE}">${esc(block.footerNote)}</p>`);
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
              lead: 'Вашата сметка е подготвена. Пријавувајте загадувања, следете ги локалитетите и учествувајте во акции за чистење.',
              extraLines: [
                'Оваа порака е испратена бидејќи ја креиравте сметката во апликацијата Chisto.mk.',
              ],
              footerNote:
                'Ако не се регистриравте, игнорирајте ја пораката или контактирајте ја поддршката.',
            },
            url,
            en,
            'openSite',
          );

    case 'password_reset': {
      const code = typeof ctx.code === 'string' ? ctx.code.trim() : '';
      const codeRow =
        code.length > 0
          ? [{ label: en ? 'Code' : 'Код', value: code }]
          : undefined;
      const otpExpiryMinutes = Math.max(1, Math.ceil(OTP_EXPIRES_SECONDS / 60));
      const otpExpiryEn = formatDurationMinutes('en', otpExpiryMinutes);
      const otpExpiryMk = formatDurationMinutes('mk', otpExpiryMinutes);
      return withCta(
        en
          ? {
              subject: 'Reset your Chisto.mk password',
              headline: 'Password reset requested',
              lead: `Use the code below to choose a new password in the app. It expires in ${otpExpiryEn}.`,
              ...(codeRow ? { detailRows: codeRow } : {}),
              extraLines: [
                'If you did not request a reset, you can ignore this email. Your password will stay the same.',
              ],
            }
          : {
              subject: 'Ресетирајте ја лозинката на Chisto.mk',
              headline: 'Барано ресетирање на лозинка',
              lead: `Користете го кодот подолу за нова лозинка во апликацијата. Истекува за ${otpExpiryMk}.`,
              ...(codeRow ? { detailRows: codeRow } : {}),
              extraLines: [
                'Ако не сте побарале ресетирање, игнорирајте ја пораката. Лозинката останува иста.',
              ],
            },
        url,
        en,
        'openApp',
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
                'Ако не сте вие, ресетирајте ја лозинката од апликацијата и веднаш контактирајте ја поддршката.',
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
              ...(reasonNote ? { footerNote: `Забелешка од модератор: ${reasonNote}` } : {}),
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
                  ? `Слични пријави се споија во вашата пријава ${reportNumber}.`
                  : 'Слични пријави се споија во вашата пријава.',
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
              lead: eventTitle
                ? `„${eventTitle}" е одобрен и видлив за доброволците.`
                : 'Настанот е одобрен и видлив за доброволците.',
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
                ? `„${eventTitle}" не ги исполни критериумите. Уредете и поднесете повторно од апликацијата.`
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
              headline: 'Нов настан на локација што ја следите',
              lead: eventTitle
                ? `„${eventTitle}“: отворен е нов настан за чистење на локација што ја следите.`
                : 'Отворен е нов настан за чистење на локација што ја следите.',
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
                ? `Вашиот бонус за пријавување за „${eventTitle}“ е отстранет бидејќи не е евидентирано присуство.`
                : 'Вашиот бонус за пријавување е отстранет бидејќи не е евидентирано присуство.',
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
                ? `Локалитетот што го пријавивте (${siteLabel}) доби ново поддржување.`
                : 'Локалитетот што го пријавивте доби ново поддржување.',
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
                : 'Некој остави коментар на локалитетот што го пријавивте.',
              detailRows: siteDetailRows(en, siteLabel),
            },
            url,
            en,
            'openApp',
          );

    case 'admin_invite': {
      const inviteUrl = typeof ctx.inviteUrl === 'string' ? ctx.inviteUrl.trim() : url;
      const roleLabel = typeof ctx.roleLabel === 'string' ? ctx.roleLabel : '';
      const expiresAt = typeof ctx.expiresAt === 'string' ? ctx.expiresAt : '';
      const expiryText =
        expiresAt.length > 0
          ? new Date(expiresAt).toLocaleString(en ? 'en-GB' : 'mk-MK', {
              dateStyle: 'medium',
              timeStyle: 'short',
            })
          : '';
      const detailRows = [
        ...(roleLabel ? [{ label: en ? 'Role' : 'Улога', value: roleLabel }] : []),
        ...(expiryText ? [{ label: en ? 'Expires' : 'Истекува', value: expiryText }] : []),
      ];
      return {
        subject: en ? 'You are invited to Chisto.mk Admin' : 'Покана за Chisto.mk Admin',
        headline: en
          ? `Welcome${firstName ? `, ${firstName}` : ''}`
          : `Добредојде${firstName ? `, ${firstName}` : ''}`,
        lead: en
          ? 'You have been invited to join the Chisto.mk admin team. Set your password and enable two-factor authentication to get started.'
          : 'Поканети сте да се приклучите на админ тимот на Chisto.mk. Поставете лозинка и овозможете двофакторска автентикација.',
        ...(detailRows.length ? { detailRows } : {}),
        extraLines: en
          ? [
              'This link is single-use and expires automatically.',
              'If you did not expect this invite, you can ignore this email.',
            ]
          : [
              'Линкот е за еднократна употреба и автоматски истекува.',
              'Ако не очекувавте покана, игнорирајте ја пораката.',
            ],
        ctaUrl: inviteUrl,
        ctaLabel: lbl(en, CTA_LABELS.acceptInvite),
      };
    }

    case 'admin_moderation_new_report': {
      const actionUrl = typeof ctx.actionUrl === 'string' ? ctx.actionUrl.trim() : url;
      const reportNumber = typeof ctx.reportNumber === 'string' ? ctx.reportNumber : '';
      const reportTitle = typeof ctx.reportTitle === 'string' ? ctx.reportTitle.trim() : '';
      const isNewSite = ctx.isNewSite === true;
      const categoryRaw = typeof ctx.category === 'string' ? ctx.category : '';
      const severityRaw = typeof ctx.severity === 'number' ? ctx.severity : null;
      const address = typeof ctx.address === 'string' ? ctx.address : null;
      const latitude = typeof ctx.latitude === 'number' ? ctx.latitude : null;
      const longitude = typeof ctx.longitude === 'number' ? ctx.longitude : null;
      const reporterEmail = typeof ctx.reporterEmail === 'string' ? ctx.reporterEmail.trim() : '';
      const submittedAt = ctx.submittedAt;
      const descriptionPreview = truncatePreview(
        typeof ctx.descriptionPreview === 'string' ? ctx.descriptionPreview : '',
      );

      const categoryLabel = humanizeReportCategory(locale, categoryRaw);
      const severityLabel = humanizeReportSeverity(locale, severityRaw);
      const locationLabel = formatLocationLabel(locale, { address, latitude, longitude });
      const submittedLabel = formatDateTime(locale, submittedAt);

      const detailRows: { label: string; value: string }[] = [];
      if (reportNumber) {
        detailRows.push({ label: en ? 'Report' : 'Пријава', value: reportNumber });
      }
      if (reportTitle) {
        detailRows.push({ label: en ? 'Title' : 'Наслов', value: reportTitle });
      }
      detailRows.push({
        label: en ? 'Type' : 'Тип',
        value: isNewSite
          ? en
            ? 'New site'
            : 'Нов локалитет'
          : en
            ? 'Report at existing site'
            : 'Пријава на постоечки локалитет',
      });
      if (categoryLabel) {
        detailRows.push({ label: en ? 'Category' : 'Категорија', value: categoryLabel });
      }
      if (severityLabel) {
        detailRows.push({ label: en ? 'Severity' : 'Тежина', value: severityLabel });
      }
      detailRows.push({ label: en ? 'Location' : 'Локација', value: locationLabel });
      if (reporterEmail) {
        detailRows.push({ label: en ? 'Reported by' : 'Пријавил', value: reporterEmail });
      }
      if (submittedLabel) {
        detailRows.push({ label: en ? 'Submitted' : 'Поднесено', value: submittedLabel });
      }

      const lead = reportNumber
        ? en
          ? `Report ${reportNumber}${reportTitle ? ` (“${reportTitle}”)` : ''} is waiting in the moderation queue.`
          : `Пријавата ${reportNumber}${reportTitle ? ` („${reportTitle}")` : ''} чека во редот за модерација.`
        : en
          ? 'A citizen submitted a report that is waiting in the moderation queue.'
          : 'Граѓанин поднесе пријава која чека во редот за модерација.';

      const extraLines = descriptionPreview
        ? [
            en
              ? `Description: “${descriptionPreview}”`
              : `Опис: „${descriptionPreview}"`,
          ]
        : undefined;

      return {
        subject: en ? 'New report needs review' : 'Нова пријава бара преглед',
        headline: en ? 'New pollution report' : 'Нова пријава за загадување',
        lead,
        detailRows,
        ...(extraLines ? { extraLines } : {}),
        ctaUrl: actionUrl,
        ctaLabel: lbl(en, CTA_LABELS.reviewInAdmin),
        accent: 'info',
      };
    }

    case 'admin_moderation_event_pending': {
      const actionUrl = typeof ctx.actionUrl === 'string' ? ctx.actionUrl.trim() : url;
      const eventTitle = typeof ctx.eventTitle === 'string' ? ctx.eventTitle.trim() : '';
      const organizerName = typeof ctx.organizerName === 'string' ? ctx.organizerName.trim() : '';
      const scheduledAt = ctx.scheduledAt;
      const endAt = ctx.endAt;
      const eventCategory = humanizeEventCategory(
        locale,
        typeof ctx.eventCategory === 'string' ? ctx.eventCategory : '',
      );
      const eventScale = humanizeEventScale(
        locale,
        typeof ctx.eventScale === 'string' ? ctx.eventScale : '',
      );
      const siteAddress = typeof ctx.siteAddress === 'string' ? ctx.siteAddress.trim() : '';
      const whenLabel = formatDateRange(locale, scheduledAt, endAt);

      const detailRows: { label: string; value: string }[] = [];
      if (eventTitle) {
        detailRows.push({ label: en ? 'Event' : 'Настан', value: eventTitle });
      }
      if (organizerName) {
        detailRows.push({ label: en ? 'Organizer' : 'Организатор', value: organizerName });
      }
      if (whenLabel) {
        detailRows.push({ label: en ? 'When' : 'Кога', value: whenLabel });
      }
      if (eventCategory) {
        detailRows.push({ label: en ? 'Category' : 'Категорија', value: eventCategory });
      }
      if (eventScale) {
        detailRows.push({ label: en ? 'Scale' : 'Опфат', value: eventScale });
      }
      if (siteAddress) {
        detailRows.push({ label: en ? 'Location' : 'Локација', value: siteAddress });
      }

      const lead = eventTitle
        ? en
          ? `“${eventTitle}” needs admin approval before volunteers can see it.`
          : `„${eventTitle}" бара админско одобрување пред доброволците да го видат.`
        : en
          ? 'A cleanup event was submitted and needs admin approval before it is visible to users.'
          : 'Поднесен е настан за чистење и треба админско одобрување пред да биде видлив за корисниците.';

      return {
        subject: en ? 'Cleanup event pending approval' : 'Чистење чека одобрување',
        headline: en ? 'Event needs review' : 'Настан бара преглед',
        lead,
        ...(detailRows.length ? { detailRows } : {}),
        ctaUrl: actionUrl,
        ctaLabel: lbl(en, CTA_LABELS.reviewInAdmin),
        accent: 'warning',
      };
    }

    case 'admin_moderation_ugc_report': {
      const actionUrl = typeof ctx.actionUrl === 'string' ? ctx.actionUrl.trim() : url;
      const subjectTypeRaw = typeof ctx.subjectType === 'string' ? ctx.subjectType : '';
      const reasonRaw = typeof ctx.reason === 'string' ? ctx.reason : '';
      const subjectId = typeof ctx.subjectId === 'string' ? ctx.subjectId.trim() : '';
      const reporterEmail = typeof ctx.reporterEmail === 'string' ? ctx.reporterEmail.trim() : '';
      const reportedAt = ctx.reportedAt;
      const detailsPreview = truncatePreview(
        typeof ctx.detailsPreview === 'string' ? ctx.detailsPreview : '',
      );

      const subjectTypeLabel = humanizeUgcSubjectType(locale, subjectTypeRaw);
      const reasonLabel = humanizeUgcReason(locale, reasonRaw);
      const reportedLabel = formatDateTime(locale, reportedAt);

      const detailRows: { label: string; value: string }[] = [];
      if (subjectTypeLabel) {
        detailRows.push({ label: en ? 'Content type' : 'Тип на содржина', value: subjectTypeLabel });
      }
      if (reasonLabel) {
        detailRows.push({ label: en ? 'Reason' : 'Причина', value: reasonLabel });
      }
      if (subjectId) {
        detailRows.push({ label: en ? 'Content ID' : 'ID на содржина', value: subjectId });
      }
      if (reporterEmail) {
        detailRows.push({ label: en ? 'Reported by' : 'Пријавил', value: reporterEmail });
      }
      if (reportedLabel) {
        detailRows.push({ label: en ? 'Reported' : 'Пријавено', value: reportedLabel });
      }

      const lead =
        subjectTypeLabel && reasonLabel
          ? en
            ? `A user flagged ${subjectTypeLabel.toLowerCase()} for ${reasonLabel.toLowerCase()}. Review it in the admin console.`
            : `Корисник пријави ${subjectTypeLabel.toLowerCase()} поради ${reasonLabel.toLowerCase()}. Прегледајте ја во админ конзолата.`
          : en
            ? 'A user reported content that may violate community guidelines.'
            : 'Корисник пријави содржина која може да ги крши правилата на заедницата.';

      const extraLines = detailsPreview
        ? [
            en
              ? `Reporter note: “${detailsPreview}”`
              : `Забелешка: „${detailsPreview}"`,
          ]
        : undefined;

      return {
        subject: en ? 'UGC report needs review' : 'Пријава за содржина бара преглед',
        headline: en ? 'Content flagged' : 'Пријавена содржина',
        lead,
        ...(detailRows.length ? { detailRows } : {}),
        ...(extraLines ? { extraLines } : {}),
        ctaUrl: actionUrl,
        ctaLabel: lbl(en, CTA_LABELS.reviewInAdmin),
        accent: 'danger',
      };
    }

    case 'admin_moderation_checkin_risk': {
      const actionUrl = typeof ctx.actionUrl === 'string' ? ctx.actionUrl.trim() : url;
      const eventTitle = typeof ctx.eventTitle === 'string' ? ctx.eventTitle.trim() : '';
      const distanceMeters =
        typeof ctx.distanceMeters === 'number' ? String(Math.round(ctx.distanceMeters)) : '';
      const occurredLabel = formatDateTime(locale, ctx.occurredAt);

      const detailRows: { label: string; value: string }[] = [];
      if (eventTitle) {
        detailRows.push({ label: en ? 'Event' : 'Настан', value: eventTitle });
      }
      if (distanceMeters) {
        detailRows.push({
          label: en ? 'Distance from site' : 'Растојание од локалитет',
          value: `${distanceMeters} m`,
        });
      }
      if (occurredLabel) {
        detailRows.push({ label: en ? 'When' : 'Кога', value: occurredLabel });
      }

      const lead = eventTitle
        ? en
          ? `A participant checked in far from the site for “${eventTitle}”. Review the risk signal in the admin console.`
          : `Учесник се пријави далеку од локалитетот за „${eventTitle}". Прегледајте го сигналот во админ конзолата.`
        : en
          ? 'A participant checked in far from the event site. Review the risk signal in the admin console.'
          : 'Учесник се пријави далеку од локалитетот на настанот. Прегледајте го сигналот во админ конзолата.';

      return {
        subject: en ? 'Suspicious event check-in' : 'Сомнително пријавување на настан',
        headline: en ? 'Check-in risk signal' : 'Сигнал за ризик при пријава',
        lead,
        ...(detailRows.length ? { detailRows } : {}),
        ctaUrl: actionUrl,
        ctaLabel: lbl(en, CTA_LABELS.reviewInAdmin),
        accent: 'warning',
      };
    }

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
