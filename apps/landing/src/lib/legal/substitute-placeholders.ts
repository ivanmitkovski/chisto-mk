import { getPublicLegalValue } from "@/lib/legal/legal-public-config";

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
    process.env.NEXT_PUBLIC_DISPUTE_RESOLUTION_MECHANISM?.trim() ||
    getPublicLegalValue(undefined, "disputeResolutionMechanism");
  set(
    "[DISPUTE_RESOLUTION_MECHANISM - e.g. courts of X / mediation / ODR platform]",
    dispute,
  );

  const sdkPurpose =
    process.env.NEXT_PUBLIC_SDK_PURPOSE_BLOCK?.trim() ||
    (process.env.NEXT_PUBLIC_OTHER_SDK_NAME?.trim() && process.env.NEXT_PUBLIC_OTHER_SDK_PURPOSE?.trim()
      ? `${process.env.NEXT_PUBLIC_OTHER_SDK_NAME!.trim()}: ${process.env.NEXT_PUBLIC_OTHER_SDK_PURPOSE!.trim()}`
      : getPublicLegalValue(undefined, "sdkPurpose"));
  set("[BRIEF_PURPOSE - e.g. crash reporting, analytics if enabled]", sdkPurpose);

  const tracking =
    process.env.NEXT_PUBLIC_TRACKING_STATUS_BLOCK?.trim() ||
    process.env.NEXT_PUBLIC_TRACKING_STATUS?.trim() ||
    getPublicLegalValue(undefined, "trackingStatus");
  set(
    "[CURRENT_STATUS: e.g. We do not use the IDFA / we do not track users across third-party apps for advertising.] Update this sentence to match your build.",
    tracking,
  );

  set("[LEGAL_ENTITY_NAME]", getPublicLegalValue(process.env.NEXT_PUBLIC_LEGAL_ENTITY_NAME, "legalEntityName"));
  set("[REGISTERED_ADDRESS]", getPublicLegalValue(process.env.NEXT_PUBLIC_REGISTERED_ADDRESS, "registeredAddress"));
  set("[REGISTRATION_NUMBER]", getPublicLegalValue(process.env.NEXT_PUBLIC_REGISTRATION_NUMBER, "registrationNumber"));
  set("[LEGAL_CONTACT_EMAIL]", getPublicLegalValue(process.env.NEXT_PUBLIC_LEGAL_CONTACT_EMAIL, "legalContactEmail"));
  set("[DPO_EMAIL_IF_APPLICABLE]", getPublicLegalValue(process.env.NEXT_PUBLIC_DPO_EMAIL, "dpoEmail"));
  set(
    "[EU_REPRESENTATIVE_IF_APPLICABLE]",
    process.env.NEXT_PUBLIC_EU_REPRESENTATIVE_BLOCK?.trim() ||
      process.env.NEXT_PUBLIC_EU_REPRESENTATIVE?.trim() ||
      getPublicLegalValue(undefined, "euRepresentative"),
  );
  set("[SUPERVISORY_AUTHORITY_NAME]", getPublicLegalValue(process.env.NEXT_PUBLIC_SUPERVISORY_AUTHORITY_NAME, "supervisoryAuthorityName"));
  set("[GOVERNING_LAW_JURISDICTION]", getPublicLegalValue(process.env.NEXT_PUBLIC_GOVERNING_LAW_JURISDICTION, "governingLawJurisdiction"));
  set("[RETENTION_CONTACT_MONTHS]", getPublicLegalValue(process.env.NEXT_PUBLIC_RETENTION_CONTACT_MONTHS, "retentionContactMonths"));
  set("[RETENTION_LOGS_MONTHS]", getPublicLegalValue(process.env.NEXT_PUBLIC_RETENTION_LOGS_MONTHS, "retentionLogsMonths"));
  set(
    "[ACCOUNT_DELETION_OR_DATA_REQUEST_EMAIL_OR_URL]",
    getPublicLegalValue(process.env.NEXT_PUBLIC_DATA_REQUEST_URL, "dataRequestUrl"),
  );
  set("[OTHER_SDK_NAME]", getPublicLegalValue(process.env.NEXT_PUBLIC_OTHER_SDK_NAME, "sdkPurpose"));
  set("[US_PRIVACY_REQUEST_URL]", getPublicLegalValue(process.env.NEXT_PUBLIC_US_PRIVACY_REQUEST_URL, "usPrivacyRequestUrl"));

  set(
    "[CONTACT_EMAIL]",
    process.env.NEXT_PUBLIC_CONTACT_EMAIL?.trim() ||
      process.env.NEXT_PUBLIC_LEGAL_CONTACT_EMAIL?.trim() ||
      getPublicLegalValue(undefined, "contactEmail"),
  );
  set("[CONTACT_ADDRESS]", getPublicLegalValue(process.env.NEXT_PUBLIC_CONTACT_ADDRESS, "contactAddress"));
  set("[CONTACT_PHONE]", getPublicLegalValue(process.env.NEXT_PUBLIC_CONTACT_PHONE, "contactPhone"));
  set("[ENTITY_TYPE]", getPublicLegalValue(process.env.NEXT_PUBLIC_ENTITY_TYPE, "entityType"));
  set("[TAX_ID]", getPublicLegalValue(process.env.NEXT_PUBLIC_TAX_ID, "taxId"));
  set("[WEBSITE_URL]", getPublicLegalValue(process.env.NEXT_PUBLIC_SITE_URL, "siteUrl"));
  set("[PRIVACY_POLICY_URL]", getPublicLegalValue(process.env.NEXT_PUBLIC_PRIVACY_POLICY_URL, "privacyPolicyUrl"));
  set("[TERMS_URL]", getPublicLegalValue(process.env.NEXT_PUBLIC_TERMS_URL, "termsUrl"));
  set("[COOKIE_PREFERENCES_URL]", getPublicLegalValue(process.env.NEXT_PUBLIC_COOKIE_PREFERENCES_URL, "cookiePreferencesUrl"));
  set("[AD_PROVIDER]", getPublicLegalValue(process.env.NEXT_PUBLIC_AD_PROVIDER, "adProvider"));
  set("[AD_PURPOSE]", getPublicLegalValue(process.env.NEXT_PUBLIC_AD_PURPOSE, "adPurpose"));
  set("[AD_COOKIE_1]", getPublicLegalValue(process.env.NEXT_PUBLIC_AD_COOKIE_NAME, "adCookieName"));
  set("[AMOUNT]", getPublicLegalValue(process.env.NEXT_PUBLIC_LIABILITY_CAP_EUR, "liabilityCapEur"));
  set("[COURT_LOCATION]", getPublicLegalValue(process.env.NEXT_PUBLIC_COURT_LOCATION, "courtLocation"));
  set("[DPO_EMAIL]", getPublicLegalValue(process.env.NEXT_PUBLIC_DPO_EMAIL, "dpoEmail"));
  set("[EFFECTIVE_DATE]", getPublicLegalValue(process.env.NEXT_PUBLIC_LEGAL_EFFECTIVE_DATE, "legalEffectiveDate"));
  set(
    "[DATE]",
    process.env.NEXT_PUBLIC_LEGAL_LAST_UPDATED_DATE?.trim() ||
      getPublicLegalValue(process.env.NEXT_PUBLIC_LEGAL_EFFECTIVE_DATE, "legalLastUpdatedDate"),
  );

  set(
    "[PRIVACY_EMAIL]",
    process.env.NEXT_PUBLIC_PRIVACY_EMAIL?.trim() ||
      process.env.NEXT_PUBLIC_LEGAL_CONTACT_EMAIL?.trim() ||
      getPublicLegalValue(undefined, "privacyEmail"),
  );
  set("[HOSTING_PROVIDER]", getPublicLegalValue(process.env.NEXT_PUBLIC_HOSTING_PROVIDER, "hostingProvider"));
  set("[SERVER_LOCATION]", getPublicLegalValue(process.env.NEXT_PUBLIC_SERVER_LOCATION, "serverLocation"));
  set("[ANALYTICS_PROVIDER]", getPublicLegalValue(process.env.NEXT_PUBLIC_ANALYTICS_PROVIDER, "analyticsProvider"));
  set("[PAYMENT_PROCESSOR]", getPublicLegalValue(process.env.NEXT_PUBLIC_PAYMENT_PROCESSOR, "paymentProcessor"));
  set("[EMAIL_PROVIDER]", getPublicLegalValue(process.env.NEXT_PUBLIC_EMAIL_PROVIDER, "emailProvider"));
  set("[SUPPORT_PROVIDER]", getPublicLegalValue(process.env.NEXT_PUBLIC_SUPPORT_PROVIDER, "supportProvider"));
  set("[MAP_PROVIDER]", getPublicLegalValue(process.env.NEXT_PUBLIC_MAP_PROVIDER, "mapProvider"));
  set("[SERVER_COUNTRY/REGION]", getPublicLegalValue(process.env.NEXT_PUBLIC_SERVER_COUNTRY_OR_REGION, "serverCountryOrRegion"));
  set("[SUPERVISORY_AUTHORITY_ADDRESS]", getPublicLegalValue(process.env.NEXT_PUBLIC_SUPERVISORY_AUTHORITY_ADDRESS, "supervisoryAuthorityAddress"));
  set("[SUPERVISORY_AUTHORITY_PHONE]", getPublicLegalValue(process.env.NEXT_PUBLIC_SUPERVISORY_AUTHORITY_PHONE, "supervisoryAuthorityPhone"));
  set(
    "[AUTHORITY_ADDRESS]",
    process.env.NEXT_PUBLIC_AUTHORITY_ADDRESS?.trim() ||
      process.env.NEXT_PUBLIC_SUPERVISORY_AUTHORITY_ADDRESS?.trim() ||
      getPublicLegalValue(undefined, "supervisoryAuthorityAddress"),
  );
  set("[COOKIE_POLICY_URL]", getPublicLegalValue(process.env.NEXT_PUBLIC_COOKIE_POLICY_URL, "cookiePolicyUrl"));

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
