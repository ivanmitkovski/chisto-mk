"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Link, usePathname } from "@/i18n/routing";
import { OPEN_COOKIE_PREFERENCES_EVENT } from "@/contexts/CookieConsentContext";
import { Container } from "@/components/layout/Container";
import { Logo } from "@/components/atoms/Logo";
import { Button } from "@/components/atoms/Button";
import { SocialLinks } from "@/components/molecules/SocialLinks";
import { StoreDownloadButtons } from "@/components/molecules/StoreDownloadButtons";
import { subscribeNewsletter } from "@/app/actions/newsletter";
import { trackMarketingEvent } from "@/lib/analytics/track-marketing";
import { Mail, Phone } from "lucide-react";
import { handleHomeNavigationClick } from "@/lib/utils/smooth-scroll";
import { LEGAL_PUBLIC_DEFAULTS } from "@/lib/legal/legal-public-config";
import { hasStoreDownloadLinks } from "@/lib/store-links";
import { hasSocialLinks } from "@/lib/social-links";
import { isLaunchPageVisible } from "@/config/launch";

export function Footer() {
  const pathname = usePathname();
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [newsletterError, setNewsletterError] = useState<
    "emailRequired" | "emailInvalid" | "generic" | null
  >(null);
  const t = useTranslations("footer");
  const tNews = useTranslations("newsletter");
  const tCommon = useTranslations("common");
  const tErrors = useTranslations("errors");
  const contactEmail = process.env.NEXT_PUBLIC_CONTACT_EMAIL?.trim() || LEGAL_PUBLIC_DEFAULTS.contactEmail;
  const contactPhone = process.env.NEXT_PUBLIC_CONTACT_PHONE?.trim() || LEGAL_PUBLIC_DEFAULTS.contactPhone;
  const legalEntityName =
    process.env.NEXT_PUBLIC_LEGAL_ENTITY_NAME?.trim() || LEGAL_PUBLIC_DEFAULTS.legalEntityName;
  const registrationNumber =
    process.env.NEXT_PUBLIC_REGISTRATION_NUMBER?.trim() || LEGAL_PUBLIC_DEFAULTS.registrationNumber;

  async function handleSubscribe(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setStatus("loading");
    setNewsletterError(null);
    const fd = new FormData(e.currentTarget);
    const result = await subscribeNewsletter(
      email,
      (fd.get("companyWebsite") as string) ?? "",
    );
    if (result.ok) {
      setStatus("success");
      trackMarketingEvent("newsletter_submit_success");
      setEmail("");
    } else {
      setStatus("error");
      if (result.error === "emailRequired" || result.error === "emailInvalid") {
        setNewsletterError(result.error);
      } else {
        setNewsletterError("generic");
      }
    }
  }

  const year = new Date().getFullYear();

  return (
    <footer className="hairline-t mesh-footer relative overflow-hidden">
      <Container className="py-12 md:py-16">
        <div className="grid gap-12 md:grid-cols-12 md:gap-10 lg:gap-12">
          <div className="md:col-span-12 lg:col-span-4">
            <Logo />
            <div className="mt-5 space-y-1 text-sm leading-relaxed text-gray-600">
              <p className="font-medium text-gray-900">{legalEntityName}</p>
              <p>{t("registrationNumber", { registrationNumber })}</p>
            </div>
            <a
              href={`mailto:${contactEmail}`}
              className="mt-4 flex items-center gap-2 text-sm text-gray-600 transition-colors hover:text-primary"
            >
              <Mail className="h-4 w-4 shrink-0 text-primary" strokeWidth={2} />
              {contactEmail}
            </a>
            <a
              href={`tel:${contactPhone.replace(/\s+/g, "")}`}
              className="mt-3 flex items-center gap-2 text-sm text-gray-600 transition-colors hover:text-primary"
            >
              <Phone className="h-4 w-4 shrink-0 text-primary" strokeWidth={2} />
              {contactPhone}
            </a>
            {hasSocialLinks() && <SocialLinks className="mt-5" />}
            {hasStoreDownloadLinks() && (
              <div className="mt-6">
                <p className="mb-3 text-xs font-bold uppercase tracking-[0.14em] text-gray-900">{t("downloadApp")}</p>
                <StoreDownloadButtons align="start" analyticsSource="footer" />
              </div>
            )}
          </div>

          <div className="md:col-span-6 lg:col-span-2">
            <h4 className="mb-4 text-xs font-bold uppercase tracking-[0.14em] text-gray-900">{t("links")}</h4>
            <ul className="space-y-3">
              <li>
                <Link
                  href="/"
                  onClick={(e) => handleHomeNavigationClick(e, pathname, "/")}
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-primary"
                >
                  {t("linkHome")}
                </Link>
              </li>
              {isLaunchPageVisible("about") && (
                <li>
                  <Link
                    href="/about"
                    onClick={(e) => handleHomeNavigationClick(e, pathname, "/about")}
                    className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-primary"
                  >
                    {t("linkPlatform")}
                  </Link>
                </li>
              )}
              {isLaunchPageVisible("news") && (
                <li>
                  <Link
                    href="/news"
                    className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-primary"
                  >
                    {t("linkNews")}
                  </Link>
                </li>
              )}
              {isLaunchPageVisible("news") && (
                <li>
                  <Link
                    href="/news/rss.xml"
                    className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-primary"
                  >
                    {t("linkRss")}
                  </Link>
                </li>
              )}
              <li>
                <Link
                  href="/help"
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-primary"
                >
                  {t("linkHelp")}
                </Link>
              </li>
              <li>
                <Link
                  href="/faq"
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-primary"
                >
                  {t("linkFaq")}
                </Link>
              </li>
              <li>
                <Link
                  href="/contact"
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-primary"
                >
                  {t("linkContact")}
                </Link>
              </li>
              {isLaunchPageVisible("press") && (
                <li>
                  <Link
                    href="/press"
                    className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-primary"
                  >
                    {t("linkPress")}
                  </Link>
                </li>
              )}
            </ul>
          </div>

          <div className="md:col-span-6 lg:col-span-2">
            <h4 className="mb-4 text-xs font-bold uppercase tracking-[0.14em] text-gray-900">{t("legal")}</h4>
            <ul className="space-y-3">
              <li>
                <Link href="/terms" className="text-sm text-gray-600 transition-colors hover:text-primary">
                  {t("terms")}
                </Link>
              </li>
              <li>
                <Link href="/privacy" className="text-sm text-gray-600 transition-colors hover:text-primary">
                  {t("privacy")}
                </Link>
              </li>
              <li>
                <Link href="/cookies" className="text-sm text-gray-600 transition-colors hover:text-primary">
                  {t("cookies")}
                </Link>
              </li>
              <li>
                <Link href="/data" className="text-sm text-gray-600 transition-colors hover:text-primary">
                  {t("linkData")}
                </Link>
              </li>
              <li>
                <button
                  type="button"
                  onClick={() => window.dispatchEvent(new Event(OPEN_COOKIE_PREFERENCES_EVENT))}
                  className="text-left text-sm text-gray-600 transition-colors hover:text-primary"
                >
                  {t("cookieSettings")}
                </button>
              </li>
            </ul>
          </div>

          <div className="md:col-span-12 lg:col-span-4">
            <h4 className="mb-4 text-xs font-bold uppercase tracking-[0.14em] text-gray-900">{t("newsletter")}</h4>
            <p className="mb-4 text-sm text-gray-500">{t("stayUpToDate")}</p>
            <form onSubmit={handleSubscribe} className="w-full max-w-[20.4rem] space-y-2" aria-busy={status === "loading"}>
              <label htmlFor="footer-newsletter-email" className="sr-only">
                {t("emailPlaceholder")}
              </label>
              <input
                type="text"
                name="companyWebsite"
                tabIndex={-1}
                autoComplete="off"
                aria-hidden
                className="absolute left-[-9999px] h-px w-px opacity-0"
              />
              <div className="rounded-full bg-gradient-to-r from-primary/55 via-emerald-400/45 to-sky-400/50 p-px shadow-[var(--shadow-lift)] transition-shadow focus-within:shadow-[0_12px_44px_rgba(47,215,136,0.28)]">
                <div className="flex min-w-0 items-center gap-2 rounded-full bg-white py-1 pl-4 pr-1.5 shadow-inner ring-1 ring-black/[0.04] transition-shadow focus-within:ring-2 focus-within:ring-primary/30">
                  <input
                    id="footer-newsletter-email"
                    type="email"
                    name="newsletter-email"
                    placeholder={t("emailPlaceholder")}
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    autoComplete="email"
                    className="min-w-0 flex-1 border-0 bg-transparent py-2 pr-2 text-sm leading-normal text-gray-900 outline-none placeholder:text-gray-400"
                  />
                  <Button
                    type="submit"
                    size="sm"
                    disabled={status === "loading"}
                    className="shrink-0 whitespace-nowrap rounded-full px-4 shadow-md shadow-primary/25 sm:px-5"
                  >
                    {status === "loading" ? tNews("subscribing") : tCommon("subscribe")}
                  </Button>
                </div>
              </div>
              {status === "success" && (
                <p className="text-xs font-medium text-primary" role="status" aria-live="polite">
                  {t("subscribedSuccess")}
                </p>
              )}
              {status === "error" && newsletterError && (
                <p className="text-xs text-red-500" role="alert">
                  {newsletterError === "generic" ? tNews("genericError") : tErrors(newsletterError)}
                </p>
              )}
              <p className="max-w-[20.4rem] text-xs leading-relaxed text-gray-500">
                {t("privacyNoticePrefix")}
                <Link href="/privacy" className="font-medium text-primary underline-offset-4 hover:underline">
                  {t("privacyNoticeLink")}
                </Link>
                {t("privacyNoticeSuffix")}
              </p>
            </form>
          </div>
        </div>
      </Container>

      <div className="hairline-t py-6 text-center text-xs text-gray-500 md:text-sm">
        {t("copyright", { year })}
      </div>
    </footer>
  );
}
