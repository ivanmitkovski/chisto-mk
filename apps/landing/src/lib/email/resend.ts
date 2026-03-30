import { Resend } from "resend";

export function getResend(): Resend | null {
  const key = process.env.RESEND_API_KEY?.trim();
  if (!key) return null;
  return new Resend(key);
}

export function getResendMailConfig(): { from: string; to: string } | null {
  const from = process.env.RESEND_FROM_EMAIL?.trim();
  const to = process.env.RESEND_NOTIFY_TO?.trim();
  if (!from || !to) return null;
  return { from, to };
}
