"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";
import { Link, usePathname } from "@/i18n/routing";
import { OPEN_COOKIE_PREFERENCES_EVENT } from "@/contexts/CookieConsentContext";
import { Container } from "@/components/layout/Container";
import { Logo } from "@/components/atoms/Logo";
import { Button } from "@/components/atoms/Button";
import { SocialIcon } from "@/components/molecules/SocialIcon";
import { subscribeNewsletter } from "@/app/actions/newsletter";
import { Mail, Phone } from "lucide-react";
import { handleHomeNavigationClick } from "@/lib/utils/smooth-scroll";
import { getPublicOptionalUrl, LEGAL_PUBLIC_DEFAULTS } from "@/lib/legal/legal-public-config";

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
  const facebookUrl = getPublicOptionalUrl(process.env.NEXT_PUBLIC_FACEBOOK_URL);
  const instagramUrl = getPublicOptionalUrl(process.env.NEXT_PUBLIC_INSTAGRAM_URL);
  const hasSocialLinks = Boolean(facebookUrl || instagramUrl);

  async function handleSubscribe(e: React.FormEvent) {
    e.preventDefault();
    setStatus("loading");
    setNewsletterError(null);
    const result = await subscribeNewsletter(email);
    if (result.ok) {
      setStatus("success");
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
          <div className="md:col-span-12 lg:col-span-3 lg:max-w-xs">
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
            {hasSocialLinks && (
              <div className="mt-5 flex gap-2">
                {facebookUrl && <SocialIcon platform="facebook" href={facebookUrl} />}
                {instagramUrl && <SocialIcon platform="instagram" href={instagramUrl} />}
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
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-gray-900"
                >
                  {t("linkHome")}
                </Link>
              </li>
              <li>
                <Link
                  href="/about"
                  onClick={(e) => handleHomeNavigationClick(e, pathname, "/about")}
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-gray-900"
                >
                  {t("linkPlatform")}
                </Link>
              </li>
              <li>
                <Link
                  href="/news"
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-gray-900"
                >
                  {t("linkNews")}
                </Link>
              </li>
              <li>
                <Link
                  href="/press"
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-gray-900"
                >
                  {t("linkPress")}
                </Link>
              </li>
              <li>
                <Link
                  href="/help"
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-gray-900"
                >
                  {t("linkHelp")}
                </Link>
              </li>
              <li>
                <Link
                  href="/contact"
                  className="text-sm text-gray-600 transition-colors duration-300 ease-out hover:text-gray-900"
                >
                  {t("linkContact")}
                </Link>
              </li>
            </ul>
          </div>

          <div className="md:col-span-6 lg:col-span-2">
            <h4 className="mb-4 text-xs font-bold uppercase tracking-[0.14em] text-gray-900">{t("legal")}</h4>
            <ul className="space-y-3">
              <li>
                <Link href="/terms" className="text-sm text-gray-600 transition-colors hover:text-gray-900">
                  {t("terms")}
                </Link>
              </li>
              <li>
                <Link href="/privacy" className="text-sm text-gray-600 transition-colors hover:text-gray-900">
                  {t("privacy")}
                </Link>
              </li>
              <li>
                <Link href="/cookies" className="text-sm text-gray-600 transition-colors hover:text-gray-900">
                  {t("cookies")}
                </Link>
              </li>
              <li>
                <Link href="/data" className="text-sm text-gray-600 transition-colors hover:text-gray-900">
                  {t("linkData")}
                </Link>
              </li>
              <li>
                <button
                  type="button"
                  onClick={() => window.dispatchEvent(new Event(OPEN_COOKIE_PREFERENCES_EVENT))}
                  className="text-left text-sm text-gray-600 transition-colors hover:text-gray-900"
                >
                  {t("cookieSettings")}
                </button>
              </li>
            </ul>
          </div>

          <div className="md:col-span-12 lg:col-span-5">
            <h4 className="mb-4 text-xs font-bold uppercase tracking-[0.14em] text-gray-900">{t("newsletter")}</h4>
            <p className="mb-4 text-sm text-gray-500">{t("stayUpToDate")}</p>
            <form onSubmit={handleSubscribe} className="w-full max-w-[20.4rem] space-y-2">
              <div className="rounded-full bg-gradient-to-r from-primary/55 via-emerald-400/45 to-sky-400/50 p-px shadow-[0_10px_36px_rgba(0,217,142,0.18)] transition-shadow focus-within:shadow-[0_12px_44px_rgba(0,217,142,0.28)]">
                <div className="flex min-w-0 items-center gap-2 rounded-full bg-white py-1 pl-4 pr-1.5 shadow-inner ring-1 ring-black/[0.04] transition-shadow focus-within:ring-2 focus-within:ring-primary/30">
                  <input
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
                    {tCommon("subscribe")}
                  </Button>
                </div>
              </div>
              {status === "success" && (
                <p className="text-xs font-medium text-primary">{t("subscribedSuccess")}</p>
              )}
              {status === "error" && newsletterError && (
                <p className="text-xs text-red-500">
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
