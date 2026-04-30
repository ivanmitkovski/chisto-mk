export const LEGAL_PUBLIC_DEFAULTS = {
  siteUrl: "https://chisto.mk",
  dataRequestUrl: "info@ekohab.mk",
  legalEntityName: "Здружение за животна средина ЕКОХАБ Скопје",
  entityType: "citizens' environmental association",
  registeredAddress: "ул. Сава Михајлов 2 бр.15, Скопје - Гази Баба, Република Северна Македонија",
  registrationNumber: "7939248",
  taxId: "4043026544136",
  contactEmail: "info@ekohab.mk",
  legalContactEmail: "info@ekohab.mk",
  privacyEmail: "info@ekohab.mk",
  contactAddress: "Скопје, Република Северна Македонија",
  contactPhone: "+389 75 770 803",
  privacyPolicyUrl: "https://chisto.mk/privacy",
  termsUrl: "https://chisto.mk/terms",
  cookiePolicyUrl: "https://chisto.mk/cookies",
  cookiePreferencesUrl: "https://chisto.mk/cookies#settings",
  hostingProvider: "Amazon Web Services (AWS)",
  serverLocation: "AWS eu-central-1 (Frankfurt, Germany)",
  serverCountryOrRegion: "European Union / EEA",
  emailProvider: "Resend for website contact and update notifications; Mailchimp only if newsletters are enabled later",
  analyticsProvider: "Firebase Analytics and Firebase Crashlytics in the mobile apps; optional Vercel Web Analytics on the website",
  supportProvider: "Email support at info@ekohab.mk",
  mapProvider: "CARTO basemaps using OpenStreetMap data, with Esri World Imagery where satellite maps are offered",
  paymentProcessor: "Not used in the current product",
  supervisoryAuthorityName: "Agency for Personal Data Protection of the Republic of North Macedonia",
  supervisoryAuthorityAddress: "Boulevard Goce Delchev 18, Skopje, Republic of North Macedonia",
  supervisoryAuthorityPhone: "+389 2 3230 635",
  liabilityCapEur: "100",
  courtLocation: "Skopje",
  legalEffectiveDate: "29 April 2026",
  legalLastUpdatedDate: "30 April 2026",
  dpoEmail: "Not appointed",
  euRepresentative: "Not applicable",
  governingLawJurisdiction: "Republic of North Macedonia",
  retentionContactMonths: "90 days",
  retentionLogsMonths: "90 days",
  disputeResolutionMechanism: "amicable resolution first, then the competent courts in Skopje, Republic of North Macedonia",
  sdkPurpose:
    "AWS hosts the service infrastructure; Twilio delivers SMS verification messages; Firebase Cloud Messaging delivers push notifications; Firebase Analytics and Crashlytics provide app analytics and crash diagnostics; Resend delivers website contact and update notification emails; Mailchimp may send newsletters only if enabled later.",
  trackingStatus:
    "We do not use IDFA and do not track users across third-party apps or websites for advertising.",
  usPrivacyRequestUrl: "mailto:info@ekohab.mk",
  adCookieName: "Not used",
  adProvider: "Not used",
  adPurpose: "Not used",
  appStoreUrl: "",
  googlePlayUrl: "",
  facebookUrl: "",
  instagramUrl: "",
} as const;

type LegalPublicDefaultKey = keyof typeof LEGAL_PUBLIC_DEFAULTS;

export function getPublicLegalValue(
  envValue: string | undefined,
  fallbackKey: LegalPublicDefaultKey,
): string {
  const trimmed = envValue?.trim();
  return trimmed && trimmed.length > 0 ? trimmed : LEGAL_PUBLIC_DEFAULTS[fallbackKey];
}

export function getPublicOptionalUrl(envValue: string | undefined): string | null {
  const trimmed = envValue?.trim();
  if (!trimmed) return null;
  return /^https:\/\//i.test(trimmed) ? trimmed : null;
}
