import { Resend } from "resend";

export function getResend(): Resend | null {
  const key = process.env.RESEND_API_KEY?.trim();
  if (!key) {
    if (process.env.NODE_ENV === "production") {
      console.error("[resend] RESEND_API_KEY is not configured — contact and newsletter forms will fail.");
    }
    return null;
  }
  return new Resend(key);
}

export function getResendMailConfig(): { from: string; to: string } | null {
  const from = process.env.RESEND_FROM_EMAIL?.trim();
  const to = process.env.RESEND_NOTIFY_TO?.trim();
  if (!from || !to) {
    if (process.env.NODE_ENV === "production") {
      console.error("[resend] RESEND_FROM_EMAIL or RESEND_NOTIFY_TO is not configured.");
    }
    return null;
  }
  return { from, to };
}
