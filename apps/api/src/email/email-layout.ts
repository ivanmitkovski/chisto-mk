import { EMAIL_BRAND } from './email.constants';

/** Layout tokens aligned with mobile AppSpacing / AppTypography (inline-safe px). */
export const EMAIL_LAYOUT = {
  cardPaddingPx: 24,
  innerHorizontalPx: 28,
  sectionGapPx: 16,
  ctaRadiusPx: 12,
  cardRadiusPx: 16,
  accentBorderPx: 4,
  /** Header block */
  headerPadTopPx: 24,
  headerPadBottomPx: 16,
  headlinePadTopPx: 0,
  /** brand-logo.png aspect ~271×313 */
  headerLogoWidthPx: 28,
  headerLogoHeightPx: 32,
  headerLogoGapPx: 12,
  headerWordmarkSizePx: 18,
  headerWordmarkLineHeight: 1.25,
  headerWordmarkTrackingPx: -0.3,
} as const;

/** Handlebars-friendly layout strings (colors come from EMAIL_BRAND). */
export function emailTemplateLayoutVars(innerPadX = `${EMAIL_LAYOUT.innerHorizontalPx}px`): Record<string, string> {
  const { headerLogoWidthPx, headerLogoHeightPx, headerLogoGapPx, headerWordmarkSizePx } = EMAIL_LAYOUT;
  return {
    innerPadX,
    headerPadTop: `${EMAIL_LAYOUT.headerPadTopPx}px`,
    headerPadBottom: `${EMAIL_LAYOUT.headerPadBottomPx}px`,
    headlinePadTop: `${EMAIL_LAYOUT.headlinePadTopPx}px`,
    headerLogoWidth: String(headerLogoWidthPx),
    headerLogoHeight: String(headerLogoHeightPx),
    headerLogoGap: `${headerLogoGapPx}px`,
    headerLogoWidthStyle: `${headerLogoWidthPx}px`,
    headerLogoHeightStyle: `${headerLogoHeightPx}px`,
    headerWordmarkSize: `${headerWordmarkSizePx}px`,
    headerWordmarkLineHeight: String(EMAIL_LAYOUT.headerWordmarkLineHeight),
    headerWordmarkTracking: `${EMAIL_LAYOUT.headerWordmarkTrackingPx}px`,
    headerWordmarkRowLineHeight: `${headerLogoHeightPx}px`,
  };
}

export type EmailAccent = 'success' | 'danger' | 'info' | 'warning' | 'none';

function esc(s: string): string {
  const collapsed = s.replace(/-+/g, '-');
  return collapsed
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/** Top accent bar color for outer card (transparent when none). */
export function accentBorderColor(accent: EmailAccent): string {
  switch (accent) {
    case 'success':
      return EMAIL_BRAND.primaryDark;
    case 'danger':
      return EMAIL_BRAND.danger;
    case 'info':
      return EMAIL_BRAND.info;
    case 'warning':
      return EMAIL_BRAND.warning;
    default:
      return 'transparent';
  }
}

/** Muted detail panel for key/value facts (report id, event title, points). */
export function buildDetailCardHtml(rows: { label: string; value: string }[]): string {
  if (!rows.length) return '';
  const bg = EMAIL_BRAND.detailSurface;
  const rowsHtml = rows
    .map(
      (r) =>
        `<tr><td class="cm-muted" style="padding:8px 14px 8px 0;font-size:13px;font-weight:600;color:${EMAIL_BRAND.textMuted};vertical-align:top;white-space:nowrap;">${esc(r.label)}</td>` +
        `<td class="cm-text" style="padding:8px 0;font-size:15px;line-height:1.5;color:${EMAIL_BRAND.textPrimary};">${esc(r.value)}</td></tr>`,
    )
    .join('');
  return (
    `<table role="presentation" class="cm-detail" cellpadding="0" cellspacing="0" border="0" width="100%" style="margin:0 0 20px 0;background-color:${bg};` +
    `border-radius:${EMAIL_LAYOUT.ctaRadiusPx}px;border:1px solid ${EMAIL_BRAND.divider};"><tr><td style="padding:16px 18px;">` +
    `<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">${rowsHtml}</table></td></tr></table>`
  );
}
