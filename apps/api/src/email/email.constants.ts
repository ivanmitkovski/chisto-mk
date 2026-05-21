/** Mobile-aligned brand tokens for HTML email (inline-safe). */
export const EMAIL_BRAND = {
  primary: '#2FD788',
  primaryDark: '#14B96A',
  appBackground: '#F4F5F7',
  panel: '#FFFFFF',
  textPrimary: '#121212',
  textSecondary: '#4C4C4C',
  textMuted: '#7A7A7A',
  danger: '#E6513D',
  warning: '#F5A623',
  info: '#3BA3F7',
  divider: '#E5E7ED',
  /** Matches mobile AppColors.inputFill — detail panels in email body */
  detailSurface: '#F0F1F7',
  fontStack: "Roboto, -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif",
} as const;

export const DEFAULT_EMAIL_FROM_ADDRESS = 'no-reply@chisto.mk';
export const DEFAULT_EMAIL_FROM_NAME = 'Chisto.mk';

/** Primary button link target when no entity-specific deep links exist. */
export const DEFAULT_EMAIL_APP_BASE_URL = 'https://chisto.mk';

/** Default logo if EMAIL_LOGO_URL unset (landing site asset over HTTPS). */
export const DEFAULT_EMAIL_LOGO_URL = 'https://chisto.mk/brand/logo.svg';
