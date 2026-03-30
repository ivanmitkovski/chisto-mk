"use client";

import * as Dialog from "@radix-ui/react-dialog";
import { useTranslations } from "next-intl";
import { useEffect, useId, useState } from "react";
import { Button } from "@/components/atoms/Button";
import { useCookieConsent } from "@/contexts/CookieConsentContext";
import { ConditionalVercelAnalytics } from "./ConditionalVercelAnalytics";

export function CookieConsentChrome() {
  const t = useTranslations("cookieConsent");
  const id = useId();
  const {
    ready,
    decided,
    analytics,
    acceptAll,
    rejectNonEssential,
    savePreferences,
    preferencesOpen,
    setPreferencesOpen,
  } = useCookieConsent();

  const [draftAnalytics, setDraftAnalytics] = useState(false);

  useEffect(() => {
    if (preferencesOpen) setDraftAnalytics(analytics);
  }, [preferencesOpen, analytics]);

  const openCustomize = () => {
    setDraftAnalytics(analytics);
    setPreferencesOpen(true);
  };

  const showBar = ready && !decided;

  return (
    <>
      <ConditionalVercelAnalytics />

      {showBar ? (
        <div
          className="fixed inset-x-0 bottom-0 z-[60] border-t border-gray-200/90 bg-white/95 p-4 shadow-[0_-8px_30px_rgba(0,0,0,0.08)] backdrop-blur-md md:p-5"
          role="region"
          aria-label={t("regionLabel")}
        >
          <div className="mx-auto flex max-w-[var(--container-max,80rem)] flex-col gap-4 px-4 sm:px-6 lg:flex-row lg:items-center lg:justify-between lg:px-8">
            <p className="text-sm leading-relaxed text-gray-700 lg:max-w-2xl">{t("bannerText")}</p>
            <div className="flex flex-shrink-0 flex-wrap gap-2 lg:justify-end">
              <Button type="button" variant="outline" size="sm" onClick={openCustomize}>
                {t("customize")}
              </Button>
              <Button type="button" variant="secondary" size="sm" onClick={rejectNonEssential}>
                {t("rejectNonEssential")}
              </Button>
              <Button type="button" variant="primary" size="sm" onClick={acceptAll}>
                {t("acceptAll")}
              </Button>
            </div>
          </div>
        </div>
      ) : null}

      <Dialog.Root open={preferencesOpen} onOpenChange={setPreferencesOpen}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 z-[70] bg-black/45 backdrop-blur-[2px] data-[state=open]:animate-fade-in" />
          <Dialog.Content
            className="fixed left-1/2 top-1/2 z-[70] w-[min(calc(100vw-2rem),26rem)] -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-gray-200/90 bg-white p-6 shadow-xl focus:outline-none data-[state=open]:animate-fade-in"
            aria-describedby={`${id}-desc`}
          >
            <Dialog.Title className="text-lg font-bold text-gray-900">{t("dialogTitle")}</Dialog.Title>
            <p id={`${id}-desc`} className="mt-2 text-sm text-gray-600">
              {t("dialogIntro")}
            </p>

            <div className="mt-6 rounded-xl border border-gray-100 bg-gray-50/80 p-4">
              <label className="flex cursor-pointer items-start gap-3">
                <input
                  type="checkbox"
                  className="mt-1 h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
                  checked={draftAnalytics}
                  onChange={(e) => setDraftAnalytics(e.target.checked)}
                />
                <span>
                  <span className="block text-sm font-semibold text-gray-900">{t("analyticsLabel")}</span>
                  <span className="mt-1 block text-xs text-gray-600">{t("analyticsDescription")}</span>
                </span>
              </label>
            </div>

            <p className="mt-4 text-xs text-gray-500">{t("necessaryNote")}</p>

            <div className="mt-6 flex flex-wrap justify-end gap-2">
              <Dialog.Close asChild>
                <Button type="button" variant="ghost" size="sm">
                  {t("cancel")}
                </Button>
              </Dialog.Close>
              <Button
                type="button"
                variant="primary"
                size="sm"
                onClick={() => savePreferences(draftAnalytics)}
              >
                {t("save")}
              </Button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </>
  );
}
