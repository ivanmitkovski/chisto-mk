"use client";

import { useTranslations } from "next-intl";
import { Button } from "@/components/atoms/Button";
import { OPEN_COOKIE_PREFERENCES_EVENT } from "@/contexts/CookieConsentContext";

export function CookieSettingsPanel() {
  const t = useTranslations("cookiesPage");

  return (
    <section
      id="cookie-settings"
      className="scroll-mt-28 border-t border-gray-200/70 pt-12 md:scroll-mt-32 md:pt-14"
    >
      <h2 className="text-balance text-xl font-bold tracking-tight text-gray-900 md:text-2xl">
        {t("settingsTitle")}
      </h2>
      <p className="mt-5 text-sm leading-relaxed text-gray-600 md:mt-6 md:text-[0.9375rem]">
        {t("settingsBody")}
      </p>
      <div className="mt-6">
        <Button
          type="button"
          variant="secondary"
          size="lg"
          onClick={() => window.dispatchEvent(new Event(OPEN_COOKIE_PREFERENCES_EVENT))}
        >
          {t("settingsButton")}
        </Button>
      </div>
    </section>
  );
}
