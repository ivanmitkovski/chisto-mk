export const OTP_SENDER = Symbol('OTP_SENDER');

export interface OtpSender {
  sendOtp(phoneNumber: string, code: string): Promise<void>;
}
