"use server";

import { validateContactForm, type ContactFormData, type FieldError } from "@/lib/utils/validators";
import { escapeHtml } from "@/lib/email/escape-html";
import { getResend, getResendMailConfig } from "@/lib/email/resend";

interface ContactResult {
  ok: boolean;
  errors?: FieldError[];
  /** Email delivery or configuration failed after validation passed */
  serverError?: boolean;
}

export async function submitContactForm(data: ContactFormData): Promise<ContactResult> {
  const errors = validateContactForm(data);
  if (errors.length > 0) return { ok: false, errors };

  const resend = getResend();
  const mail = getResendMailConfig();
  if (!resend || !mail) {
    return { ok: false, serverError: true };
  }

  const safe = {
    fullName: escapeHtml(data.fullName.trim()),
    phone: escapeHtml(data.phone.trim()),
    email: escapeHtml(data.email.trim()),
    message: escapeHtml(data.message.trim()).replace(/\n/g, "<br />"),
  };

  const subjectName = data.fullName.trim().slice(0, 80).replace(/[\r\n]+/g, " ");

  const { error } = await resend.emails.send({
    from: mail.from,
    to: mail.to,
    subject: `Chisto.mk contact — ${subjectName}`,
    replyTo: data.email.trim(),
    html: `
      <p><strong>Name:</strong> ${safe.fullName}</p>
      <p><strong>Phone:</strong> ${safe.phone}</p>
      <p><strong>Email:</strong> ${safe.email}</p>
      <p><strong>Message:</strong></p>
      <p>${safe.message}</p>
    `.trim(),
  });

  if (error) {
    return { ok: false, serverError: true };
  }

  return { ok: true };
}
