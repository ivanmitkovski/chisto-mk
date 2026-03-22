import { ServiceUnavailableException } from '@nestjs/common';
import Twilio from 'twilio';
import { OtpSender } from '../otp-sender.interface';

export class TwilioOtpSender implements OtpSender {
  private readonly client: Twilio.Twilio;
  private readonly messagingServiceSid: string | undefined;
  private readonly fromNumber: string | undefined;

  constructor(
    accountSid: string,
    authToken: string,
    messagingServiceSid: string | undefined,
    fromNumber: string | undefined,
  ) {
    this.client = Twilio(accountSid, authToken);
    this.messagingServiceSid = messagingServiceSid;
    this.fromNumber = fromNumber;
  }

  async sendOtp(phoneNumber: string, code: string): Promise<void> {
    const body = `Your Chisto code is: ${code}`;
    try {
      const params: { body: string; to: string; messagingServiceSid?: string; from?: string } = {
        body,
        to: phoneNumber,
      };
      if (this.messagingServiceSid) {
        params.messagingServiceSid = this.messagingServiceSid;
      } else if (this.fromNumber) {
        params.from = this.fromNumber;
      } else {
        throw new ServiceUnavailableException('SMS sender not configured');
      }
      await this.client.messages.create(params);
    } catch {
      throw new ServiceUnavailableException('Unable to send verification code');
    }
  }
}
