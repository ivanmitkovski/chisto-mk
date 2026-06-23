"use server";

import { validateEmail } from "@/lib/utils/validators";
import { escapeHtml } from "@/lib/email/escape-html";
import { getResend, getResendMailConfig } from "@/lib/email/resend";
import { checkRateLimit } from "@/lib/utils/rate-limit";

interface NewsletterResult {
  ok: boolean;
  /** Key under `errors` / `newsletter` for client translation */
  error?: "emailRequired" | "emailInvalid" | "generic";
}

export async function subscribeNewsletter(
  email: string,
  companyWebsite?: string,
): Promise<NewsletterResult> {
  if (companyWebsite?.trim()) {
    return { ok: true };
  }

  const err = validateEmail(email);
  if (err) {
    return {
      ok: false,
      error: err.code === "invalidEmail" ? "emailInvalid" : "emailRequired",
    };
  }

  const trimmed = email.trim();
  if (!checkRateLimit(`newsletter:${trimmed.toLowerCase()}`)) {
    return { ok: false, error: "generic" };
  }

  const resend = getResend();
  const mail = getResendMailConfig();
  if (!resend || !mail) {
    return { ok: false, error: "generic" };
  }

  const { error } = await resend.emails.send({
    from: mail.from,
    to: mail.to,
    subject: "Chisto.mk: newsletter signup",
    html: `<p>New newsletter subscription:</p><p><strong>${escapeHtml(trimmed)}</strong></p>`,
  });

  if (error) {
    return { ok: false, error: "generic" };
  }

  return { ok: true };
}
