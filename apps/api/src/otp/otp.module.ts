import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { OTP_SENDER, OtpSender } from './otp-sender.interface';
import { NoopOtpSenderService } from './noop-otp-sender.service';
import { TwilioOtpSender } from './senders/twilio.sender';
import { OtpService } from './otp.service';

@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: OTP_SENDER,
      inject: [ConfigService],
      useFactory: (configService: ConfigService): OtpSender => {
        const provider = configService.get<string>('SMS_PROVIDER')?.toLowerCase() ?? 'none';
        if (provider === 'twilio') {
          const accountSid = configService.get<string>('TWILIO_ACCOUNT_SID');
          const authToken = configService.get<string>('TWILIO_AUTH_TOKEN');
          const messagingServiceSid = configService.get<string>('TWILIO_MESSAGING_SERVICE_SID');
          const fromNumber = configService.get<string>('TWILIO_PHONE_NUMBER');
          if (!accountSid || !authToken) {
            throw new Error('TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN are required when SMS_PROVIDER=twilio');
          }
          if (!messagingServiceSid && !fromNumber) {
            throw new Error('TWILIO_MESSAGING_SERVICE_SID or TWILIO_PHONE_NUMBER is required when SMS_PROVIDER=twilio');
          }
          return new TwilioOtpSender(
            accountSid,
            authToken,
            messagingServiceSid?.trim() || undefined,
            fromNumber?.trim() || undefined,
          );
        }
        return new NoopOtpSenderService();
      },
    },
    OtpService,
  ],
  exports: [OTP_SENDER, OtpService],
})
export class OtpModule {}
