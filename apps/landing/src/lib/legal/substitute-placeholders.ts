/**
 * Replace [PLACEHOLDER] tokens in legal copy with values from public env vars.
 * Longer tokens are applied first so composite placeholders match before short keys.
 */
export function getLegalPlaceholderMap(): Record<string, string> {
  const m: Record<string, string> = {};

  const set = (key: string, value: string | undefined) => {
    if (value && value.trim()) m[key] = value.trim();
  };

  const dispute =
    process.env.NEXT_PUBLIC_DISPUTE_RESOLUTION_BLOCK?.trim() ||
    process.env.NEXT_PUBLIC_DISPUTE_RESOLUTION_MECHANISM?.trim();
  set(
    "[DISPUTE_RESOLUTION_MECHANISM - e.g. courts of X / mediation / ODR platform]",
    dispute,
  );

  const sdkPurpose =
    process.env.NEXT_PUBLIC_SDK_PURPOSE_BLOCK?.trim() ||
    (process.env.NEXT_PUBLIC_OTHER_SDK_NAME?.trim() && process.env.NEXT_PUBLIC_OTHER_SDK_PURPOSE?.trim()
      ? `${process.env.NEXT_PUBLIC_OTHER_SDK_NAME!.trim()}: ${process.env.NEXT_PUBLIC_OTHER_SDK_PURPOSE!.trim()}`
      : undefined);
  set("[BRIEF_PURPOSE - e.g. crash reporting, analytics if enabled]", sdkPurpose);

  const tracking =
    process.env.NEXT_PUBLIC_TRACKING_STATUS_BLOCK?.trim() ||
    process.env.NEXT_PUBLIC_TRACKING_STATUS?.trim();
  set(
    "[CURRENT_STATUS: e.g. We do not use the IDFA / we do not track users across third-party apps for advertising.] Update this sentence to match your build.",
    tracking,
  );

  set("[LEGAL_ENTITY_NAME]", process.env.NEXT_PUBLIC_LEGAL_ENTITY_NAME);
  set("[REGISTERED_ADDRESS]", process.env.NEXT_PUBLIC_REGISTERED_ADDRESS);
  set("[REGISTRATION_NUMBER]", process.env.NEXT_PUBLIC_REGISTRATION_NUMBER);
  set("[LEGAL_CONTACT_EMAIL]", process.env.NEXT_PUBLIC_LEGAL_CONTACT_EMAIL);
  set("[DPO_EMAIL_IF_APPLICABLE]", process.env.NEXT_PUBLIC_DPO_EMAIL);
  set(
    "[EU_REPRESENTATIVE_IF_APPLICABLE]",
    process.env.NEXT_PUBLIC_EU_REPRESENTATIVE_BLOCK?.trim() ||
      process.env.NEXT_PUBLIC_EU_REPRESENTATIVE?.trim(),
  );
  set("[SUPERVISORY_AUTHORITY_NAME]", process.env.NEXT_PUBLIC_SUPERVISORY_AUTHORITY_NAME);
  set("[GOVERNING_LAW_JURISDICTION]", process.env.NEXT_PUBLIC_GOVERNING_LAW_JURISDICTION);
  set("[RETENTION_CONTACT_MONTHS]", process.env.NEXT_PUBLIC_RETENTION_CONTACT_MONTHS);
  set("[RETENTION_LOGS_MONTHS]", process.env.NEXT_PUBLIC_RETENTION_LOGS_MONTHS);
  set(
    "[ACCOUNT_DELETION_OR_DATA_REQUEST_EMAIL_OR_URL]",
    process.env.NEXT_PUBLIC_DATA_REQUEST_URL,
  );
  set("[OTHER_SDK_NAME]", process.env.NEXT_PUBLIC_OTHER_SDK_NAME);
  set("[US_PRIVACY_REQUEST_URL]", process.env.NEXT_PUBLIC_US_PRIVACY_REQUEST_URL);

  set(
    "[CONTACT_EMAIL]",
    process.env.NEXT_PUBLIC_CONTACT_EMAIL?.trim() || process.env.NEXT_PUBLIC_LEGAL_CONTACT_EMAIL,
  );
  set("[CONTACT_ADDRESS]", process.env.NEXT_PUBLIC_CONTACT_ADDRESS);
  set("[CONTACT_PHONE]", process.env.NEXT_PUBLIC_CONTACT_PHONE);
  set("[ENTITY_TYPE]", process.env.NEXT_PUBLIC_ENTITY_TYPE);
  set("[TAX_ID]", process.env.NEXT_PUBLIC_TAX_ID);
  set("[WEBSITE_URL]", process.env.NEXT_PUBLIC_SITE_URL);
  set("[PRIVACY_POLICY_URL]", process.env.NEXT_PUBLIC_PRIVACY_POLICY_URL);
  set("[TERMS_URL]", process.env.NEXT_PUBLIC_TERMS_URL);
  set("[COOKIE_PREFERENCES_URL]", process.env.NEXT_PUBLIC_COOKIE_PREFERENCES_URL);
  set("[AD_PROVIDER]", process.env.NEXT_PUBLIC_AD_PROVIDER);
  set("[AD_PURPOSE]", process.env.NEXT_PUBLIC_AD_PURPOSE);
  set("[AD_COOKIE_1]", process.env.NEXT_PUBLIC_AD_COOKIE_NAME);
  set("[AMOUNT]", process.env.NEXT_PUBLIC_LIABILITY_CAP_EUR);
  set("[COURT_LOCATION]", process.env.NEXT_PUBLIC_COURT_LOCATION);
  set("[DPO_EMAIL]", process.env.NEXT_PUBLIC_DPO_EMAIL);
  set("[EFFECTIVE_DATE]", process.env.NEXT_PUBLIC_LEGAL_EFFECTIVE_DATE);
  set(
    "[DATE]",
    process.env.NEXT_PUBLIC_LEGAL_LAST_UPDATED_DATE?.trim() ||
      process.env.NEXT_PUBLIC_LEGAL_EFFECTIVE_DATE,
  );

  set(
    "[PRIVACY_EMAIL]",
    process.env.NEXT_PUBLIC_PRIVACY_EMAIL?.trim() || process.env.NEXT_PUBLIC_LEGAL_CONTACT_EMAIL,
  );
  set("[HOSTING_PROVIDER]", process.env.NEXT_PUBLIC_HOSTING_PROVIDER);
  set("[SERVER_LOCATION]", process.env.NEXT_PUBLIC_SERVER_LOCATION);
  set("[ANALYTICS_PROVIDER]", process.env.NEXT_PUBLIC_ANALYTICS_PROVIDER);
  set("[PAYMENT_PROCESSOR]", process.env.NEXT_PUBLIC_PAYMENT_PROCESSOR);
  set("[EMAIL_PROVIDER]", process.env.NEXT_PUBLIC_EMAIL_PROVIDER);
  set("[SUPPORT_PROVIDER]", process.env.NEXT_PUBLIC_SUPPORT_PROVIDER);
  set("[MAP_PROVIDER]", process.env.NEXT_PUBLIC_MAP_PROVIDER);
  set("[SERVER_COUNTRY/REGION]", process.env.NEXT_PUBLIC_SERVER_COUNTRY_OR_REGION);
  set("[SUPERVISORY_AUTHORITY_ADDRESS]", process.env.NEXT_PUBLIC_SUPERVISORY_AUTHORITY_ADDRESS);
  set("[SUPERVISORY_AUTHORITY_PHONE]", process.env.NEXT_PUBLIC_SUPERVISORY_AUTHORITY_PHONE);
  set(
    "[AUTHORITY_ADDRESS]",
    process.env.NEXT_PUBLIC_AUTHORITY_ADDRESS?.trim() ||
      process.env.NEXT_PUBLIC_SUPERVISORY_AUTHORITY_ADDRESS,
  );
  set("[COOKIE_POLICY_URL]", process.env.NEXT_PUBLIC_COOKIE_POLICY_URL);

  return m;
}

export function substituteLegalText(text: string, map = getLegalPlaceholderMap()): string {
  const entries = Object.entries(map).sort((a, b) => b[0].length - a[0].length);
  let out = text;
  for (const [token, value] of entries) {
    out = out.split(token).join(value);
  }
  return out;
}

export function substituteLegalSections(
  sections: { title: string; body: string }[],
  map = getLegalPlaceholderMap(),
): { title: string; body: string }[] {
  return sections.map((s) => ({
    ...s,
    title: substituteLegalText(s.title, map),
    body: substituteLegalText(s.body, map),
  }));
}

export function substituteCookieRows(
  rows: {
    name: string;
    provider: string;
    purpose: string;
    duration: string;
    type: string;
  }[],
  map = getLegalPlaceholderMap(),
): {
  name: string;
  provider: string;
  purpose: string;
  duration: string;
  type: string;
}[] {
  return rows.map((r) => ({
    ...r,
    name: substituteLegalText(r.name, map),
    provider: substituteLegalText(r.provider, map),
    purpose: substituteLegalText(r.purpose, map),
    duration: substituteLegalText(r.duration, map),
    type: substituteLegalText(r.type, map),
  }));
}
