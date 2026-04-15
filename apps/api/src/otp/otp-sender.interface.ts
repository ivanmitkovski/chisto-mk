export const OTP_SENDER = Symbol('OTP_SENDER');

/** SMS copy variant; registration does not send OTP today—use phone verification for post-signup flows. */
export const OtpSmsPurpose = {
  PhoneVerification: 'phone_verification',
  PasswordReset: 'password_reset',
} as const;

export type OtpSmsPurpose = (typeof OtpSmsPurpose)[keyof typeof OtpSmsPurpose];

export type SendOtpSmsOptions = {
  purpose: OtpSmsPurpose;
  /** Raw `Accept-Language` header (or similar); used only to pick en/mk/sq templates. */
  localeHint?: string;
  /** Whole minutes until OTP expiry (from server TTL). */
  expiryMinutes: number;
};

export interface OtpSender {
  sendOtp(phoneNumber: string, code: string, options: SendOtpSmsOptions): Promise<void>;
}
