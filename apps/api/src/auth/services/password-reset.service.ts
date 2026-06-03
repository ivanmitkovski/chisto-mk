import {
  BadRequestException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { generateOtpCode, hashOtpCode } from '../../otp/util/otp-code.util';
import { EmailSendEligibilityService } from '../../email/services/email-send-eligibility.service';
import { AuthIdentifierThrottleService } from './auth-identifier-throttle.service';
import { PasswordResetSmsFlowService } from './password-reset-sms-flow.service';
import { PasswordResetEmailFlowService } from './password-reset-email-flow.service';

export type PasswordResetRequestResult = {
  message: string;
  devCode?: string;
};

@Injectable()
export class PasswordResetService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly emailEligibility: EmailSendEligibilityService,
    private readonly identifierThrottle: AuthIdentifierThrottleService,
    private readonly smsFlow: PasswordResetSmsFlowService,
    private readonly emailFlow: PasswordResetEmailFlowService,
  ) {}

  async request(params: {
    phoneNumber?: string;
    email?: string;
    acceptLanguage?: string;
  }): Promise<PasswordResetRequestResult> {
    const phone = params.phoneNumber?.trim();
    const email = params.email?.toLowerCase().trim();

    if ((!phone && !email) || (phone && email)) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: 'Provide exactly one of phoneNumber or email',
      });
    }

    const generic: PasswordResetRequestResult = {
      message: 'If an account exists, instructions were sent.',
    };

    const dummyCode = generateOtpCode();
    await hashOtpCode(dummyCode);

    if (phone) {
      await this.identifierThrottle.assertAllowed('password_reset', phone, 5, 3600);
      const user = await this.prisma.user.findUnique({
        where: { phoneNumber: phone },
        select: { id: true },
      });
      if (!user) {
        return generic;
      }
      const devCode = await this.smsFlow.sendOtp(phone, params.acceptLanguage);
      return {
        ...generic,
        ...(devCode != null ? { devCode } : {}),
      };
    }

    await this.identifierThrottle.assertAllowed('password_reset', email!, 5, 3600);
    const user = await this.prisma.user.findUnique({
      where: { email: email! },
      select: { id: true, email: true, firstName: true },
    });
    if (!user) {
      return generic;
    }

    if (!(await this.emailEligibility.isGloballyEnabled())) {
      return generic;
    }

    const devCode = await this.emailFlow.sendCode(user.id, user.email, user.firstName);
    return {
      ...generic,
      ...(devCode != null ? { devCode } : {}),
    };
  }

  verifyPasswordResetCode(phoneNumber: string, code: string): Promise<void> {
    return this.smsFlow.verifyCode(phoneNumber, code);
  }

  verifyPasswordResetCodeByEmail(email: string, code: string): Promise<void> {
    return this.emailFlow.verifyCode(email, code);
  }

  confirmSmsReset(dto: import('../dto/reset-password-confirm.dto').ResetPasswordConfirmDto) {
    return this.smsFlow.confirmReset(dto);
  }

  confirmEmailReset(email: string, code: string, newPassword: string) {
    return this.emailFlow.confirmReset(email, code, newPassword);
  }
}
