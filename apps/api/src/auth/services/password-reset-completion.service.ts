import { Inject, Injectable, Logger } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import type { Prisma } from '../../generated/prisma';
import { PrismaService } from '../../prisma/prisma.service';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../constants/auth-env.config';
import type { PrismaWithLoginFailure } from '../util/auth-prisma-extensions';
import { EmailService } from '../../email/services/email.service';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import { AuditService } from '../../audit/services/audit.service';

@Injectable()
export class PasswordResetCompletionService {
  private readonly logger = new Logger(PasswordResetCompletionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
    private readonly audit: AuditService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

  async applyNewPasswordWithOtpConsume(params: {
    userId: string;
    phoneNumber: string;
    newPassword: string;
    consumeOtp: (tx: Prisma.TransactionClient) => Promise<void>;
  }): Promise<void> {
    const passwordHash = await bcrypt.hash(params.newPassword, this.env.saltRounds);
    const now = new Date();

    await this.prisma.$transaction(async (tx) => {
      await params.consumeOtp(tx);
      await tx.user.update({
        where: { id: params.userId },
        data: { passwordHash },
      });
      await tx.userSession.updateMany({
        where: { userId: params.userId, revokedAt: null },
        data: { revokedAt: now },
      });
      const db = tx as PrismaWithLoginFailure;
      await db.loginFailure.deleteMany({ where: { phoneNumber: params.phoneNumber } });
      await this.audit.log({
        actorId: params.userId,
        action: 'PASSWORD_RESET',
        resourceType: 'User',
        resourceId: params.userId,
      });
    });

    void this.sendPasswordChangedEmail(params.userId).catch((err: unknown) => {
      this.logger.warn({
        msg: 'password_changed_email_send_failed',
        userId: params.userId,
        error: String(err),
      });
    });
  }

  private async sendPasswordChangedEmail(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true, firstName: true },
    });
    if (!user) return;
    const localeBy = await notificationLocalesByUserId(this.prisma, [userId]);
    const locale = localeBy.get(userId) === 'en' ? 'en' : 'mk';
    await this.emailService.sendAuthTemplate({
      userId,
      to: user.email,
      firstName: user.firstName,
      templateId: 'password_changed',
      locale,
    });
  }
}
