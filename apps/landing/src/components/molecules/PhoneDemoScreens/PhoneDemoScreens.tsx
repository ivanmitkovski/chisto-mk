"use client";

import { useTranslations } from "next-intl";

export const HERO_PHONE_VARIANTS = ["login", "welcome", "map"] as const;
export type HeroPhoneVariant = (typeof HERO_PHONE_VARIANTS)[number];

function StatusBar() {
  return (
    <div className="flex items-center justify-between px-4 pb-2 pt-1">
      <span className="text-[10px] font-semibold tabular-nums text-gray-400">9:41</span>
      <div className="flex gap-1">
        <div className="h-2 w-3 rounded-sm bg-gray-300" />
        <div className="h-2 w-1 rounded-sm bg-gray-300" />
      </div>
    </div>
  );
}

export function PhoneScreen({ variant }: { variant: HeroPhoneVariant }) {
  const t = useTranslations("phoneMockup");

  if (variant === "login") {
    return (
      <div className="flex aspect-[9/19.5] flex-col rounded-3xl bg-gradient-to-b from-white to-slate-50/90">
        <StatusBar />
        <div className="flex flex-1 flex-col px-5 pb-6 pt-4">
          <div className="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/15 ring-2 ring-primary/20">
            <div className="h-8 w-8 rounded-full bg-primary/40" />
          </div>
          <p className="text-center text-xs font-semibold text-gray-800">{t("loginWelcomeBack")}</p>
          <p className="mb-5 text-center text-[10px] text-gray-500">{t("loginSubtitle")}</p>
          <div className="space-y-2.5">
            <div className="h-9 rounded-xl border border-gray-200/80 bg-white px-3 shadow-sm">
              <div className="mt-2.5 h-2 w-24 rounded bg-gray-200" />
            </div>
            <div className="h-9 rounded-xl border border-gray-200/80 bg-white px-3 shadow-sm">
              <div className="mt-2.5 h-2 w-20 rounded bg-gray-200" />
            </div>
          </div>
          <div className="mt-4 h-9 rounded-full bg-primary text-center text-[11px] font-semibold leading-9 text-white shadow-md shadow-primary/30">
            {t("loginButton")}
          </div>
          <div className="mt-4 flex justify-center gap-3">
            <div className="h-8 w-8 rounded-full bg-gray-100 ring-1 ring-gray-200" />
            <div className="h-8 w-8 rounded-full bg-gray-100 ring-1 ring-gray-200" />
          </div>
        </div>
      </div>
    );
  }

  if (variant === "welcome") {
    return (
      <div className="flex aspect-[9/19.5] flex-col rounded-3xl bg-white">
        <StatusBar />
        <div className="relative mx-3 mt-1 aspect-[4/3] overflow-hidden rounded-2xl bg-gradient-to-br from-emerald-100/80 to-sky-100/60 ring-1 ring-black/5">
          <div className="absolute inset-0 bg-[linear-gradient(to_top,rgba(0,0,0,0.35),transparent_50%)]" />
          <div className="absolute bottom-2 left-2 right-2 flex gap-2">
            <div className="h-1 flex-1 rounded-full bg-white/40" />
            <div className="h-1 w-1 rounded-full bg-white/60" />
            <div className="h-1 w-1 rounded-full bg-white/40" />
          </div>
        </div>
        <div className="flex flex-1 flex-col px-5 pb-6 pt-4">
          <h3 className="text-center text-sm font-bold text-gray-900">{t("welcomeTitle")}</h3>
          <p className="mt-1 text-center text-[10px] leading-relaxed text-gray-500">
            {t("welcomeSubtitle")}
          </p>
          <div className="mt-auto h-10 rounded-full bg-primary text-center text-xs font-semibold leading-10 text-white shadow-lg shadow-primary/25">
            {t("welcomeButton")}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex aspect-[9/19.5] flex-col rounded-3xl bg-gradient-to-b from-sky-50/50 to-white">
      <StatusBar />
      <div className="px-3 pb-1 pt-1">
        <div className="flex h-8 items-center gap-2 rounded-xl bg-white px-3 shadow-sm ring-1 ring-gray-100">
          <div className="h-2.5 w-2.5 rounded-full bg-gray-300" />
          <div className="h-2 flex-1 rounded bg-gray-100" />
        </div>
      </div>
      <div className="relative mx-3 flex-1 overflow-hidden rounded-2xl bg-[#E8F2E8] ring-1 ring-emerald-900/10">
        <div className="absolute left-[18%] top-[22%] h-3 w-3 rounded-full bg-red-400 shadow-md ring-2 ring-white" />
        <div className="absolute left-[52%] top-[38%] h-3 w-3 rounded-full bg-amber-400 shadow-md ring-2 ring-white" />
        <div className="absolute right-[22%] top-[48%] h-3 w-3 rounded-full bg-primary shadow-md ring-2 ring-white" />
        <div className="absolute inset-x-0 bottom-0 top-1/2 bg-gradient-to-t from-white/90 to-transparent" />
      </div>
      <div className="mt-auto flex items-center justify-around border-t border-gray-100 bg-white px-2 py-2">
        <div className="h-5 w-5 rounded-md bg-gray-100" />
        <div className="flex h-11 w-11 items-center justify-center rounded-full bg-primary shadow-lg shadow-primary/35 ring-4 ring-primary/20">
          <span className="text-lg font-light leading-none text-white">+</span>
        </div>
        <div className="h-5 w-5 rounded-md bg-gray-100" />
      </div>
    </div>
  );
}
