import { Injectable } from '@nestjs/common';
import { OtpSender, SendOtpSmsOptions } from './otp-sender.interface';

@Injectable()
export class NoopOtpSenderService implements OtpSender {
  async sendOtp(_phoneNumber: string, _code: string, _options: SendOtpSmsOptions): Promise<void> {}
}
