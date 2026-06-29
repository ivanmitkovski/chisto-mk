"use server";

import { escapeHtml } from "@/lib/email/escape-html";
import { getResend, getResendMailConfig } from "@/lib/email/resend";
import { checkRateLimit } from "@/lib/utils/rate-limit";

export type HelpFeedbackPayload = {
  slug: string;
  reason: string;
  locale: string;
  companyWebsite?: string;
};

export async function submitHelpFeedback(data: HelpFeedbackPayload): Promise<{ ok: boolean; serverError?: boolean }> {
  if (data.companyWebsite?.trim()) {
    return { ok: true };
  }

  const slug = data.slug.trim().slice(0, 80);
  const reason = data.reason.trim().slice(0, 500);
  const locale = data.locale.trim().slice(0, 8);
  if (!slug || !reason) {
    return { ok: true };
  }

  if (!checkRateLimit(`help-feedback:${slug}:${reason.slice(0, 32)}`)) {
    return { ok: false, serverError: true };
  }

  const resend = getResend();
  const mail = getResendMailConfig();
  if (!resend || !mail) {
    return { ok: false, serverError: true };
  }

  const safeReason = escapeHtml(reason).replace(/\n/g, "<br />");

  const { error } = await resend.emails.send({
    from: mail.from,
    to: mail.to,
    subject: `Chisto.mk help feedback: ${slug}`,
    html: `
      <p><strong>Article:</strong> ${escapeHtml(slug)}</p>
      <p><strong>Locale:</strong> ${escapeHtml(locale)}</p>
      <p><strong>Feedback:</strong></p>
      <p>${safeReason}</p>
    `.trim(),
  });

  if (error) {
    return { ok: false, serverError: true };
  }

  return { ok: true };
}
