import { ServiceUnavailableException } from '@nestjs/common';
import Twilio from 'twilio';
import { CircuitBreaker, CircuitBreakerOpenError } from '../../common/resilience/circuit-breaker';
import { buildOtpSmsBody, otpSmsLocaleFromHint } from '../otp-sms-body';
import { OtpSender, SendOtpSmsOptions } from '../otp-sender.interface';

/** Twilio REST API only accepts `MessagingServiceSid` for values matching this pattern. */
const TWILIO_MESSAGING_SERVICE_SID_PATTERN = /^MG[0-9a-fA-F]{32}$/i;

export class TwilioOtpSender implements OtpSender {
  private readonly client: Twilio.Twilio;
  private readonly circuitBreaker = new CircuitBreaker({
    name: 'twilio_sms',
    failureThreshold: 6,
    resetTimeoutMs: 60_000,
  });
  /**
   * If it matches `MG` + 32 hex, sent as `messagingServiceSid`.
   * Otherwise treated as API `From` (e.g. alphanumeric sender label or non-MG sender SID).
   */
  private readonly messagingServiceSidOrFrom: string | undefined;
  /** E.164 long code (e.g. +38970123456). Used when no Messaging Service / no `from` from env above. */
  private readonly fromNumber: string | undefined;
  /** Alphanumeric sender ID (e.g. ChistoMK). Used as `from` when nothing else applies. Not all countries support it. */
  private readonly alphanumericSender: string | undefined;

  constructor(
    accountSid: string,
    authToken: string,
    messagingServiceSid: string | undefined,
    fromNumber: string | undefined,
    alphanumericSender: string | undefined,
  ) {
    this.client = Twilio(accountSid, authToken);
    this.messagingServiceSidOrFrom = messagingServiceSid;
    this.fromNumber = fromNumber;
    this.alphanumericSender = alphanumericSender;
  }

  async sendOtp(phoneNumber: string, code: string, options: SendOtpSmsOptions): Promise<void> {
    const locale = otpSmsLocaleFromHint(options.localeHint);
    const body = buildOtpSmsBody({
      code,
      purpose: options.purpose,
      locale,
      expiryMinutes: options.expiryMinutes,
    });
    try {
      const params: { body: string; to: string; messagingServiceSid?: string; from?: string } = {
        body,
        to: phoneNumber,
      };
      const msOrFrom = this.messagingServiceSidOrFrom?.trim();
      if (msOrFrom) {
        if (TWILIO_MESSAGING_SERVICE_SID_PATTERN.test(msOrFrom)) {
          params.messagingServiceSid = msOrFrom;
        } else {
          params.from = msOrFrom;
        }
      } else if (this.alphanumericSender?.trim()) {
        params.from = this.alphanumericSender.trim();
      } else if (this.fromNumber?.trim()) {
        params.from = this.fromNumber.trim();
      } else {
        throw new ServiceUnavailableException('SMS sender not configured');
      }
      await this.circuitBreaker.execute(async () => this.client.messages.create(params));
    } catch (err) {
      if (err instanceof CircuitBreakerOpenError) {
        throw new ServiceUnavailableException('SMS gateway is temporarily unavailable');
      }
      throw new ServiceUnavailableException('Unable to send verification code');
    }
  }
}
