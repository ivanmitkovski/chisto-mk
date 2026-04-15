"use server";

import type { Locale } from "@/i18n/config";
import { isLocale } from "@/i18n/config";
import { tryAddSubscriber } from "@/lib/notify-subscribers-store";

const EMAIL_RE =
  /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase().slice(0, 254);
}

export type NotifySignupState =
  | { ok: true }
  | { ok: false; code: "invalid" | "consent" | "already" | "save" };

export async function submitNotifySignup(
  _prev: NotifySignupState | null,
  formData: FormData,
): Promise<NotifySignupState> {
  const email = normalizeEmail(String(formData.get("email") ?? ""));
  const localeRaw = String(formData.get("locale") ?? "");
  const locale: Locale = isLocale(localeRaw) ? localeRaw : "mk";
  const consent = formData.get("consent");

  if (!email || !EMAIL_RE.test(email)) {
    return { ok: false, code: "invalid" };
  }

  if (consent !== "yes") {
    return { ok: false, code: "consent" };
  }

  const result = await tryAddSubscriber(email, locale);
  if (result === "duplicate") {
    return { ok: false, code: "already" };
  }
  if (result === "error") {
    return { ok: false, code: "save" };
  }

  return { ok: true };
}
