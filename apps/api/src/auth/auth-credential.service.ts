import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { AuditService } from '../audit/audit.service';
import type { PrismaWithLoginFailure } from './auth-prisma-extensions';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from './auth-env.config';
import { EmailService } from '../email/email.service';
import { notificationLocalesByUserId } from '../common/i18n/notification-locale.resolver';
import { AuthSessionRevocationService } from './auth-session-revocation.service';

@Injectable()
export class AuthCredentialService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly emailService: EmailService,
    private readonly sessionRevocation: AuthSessionRevocationService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { passwordHash: true, phoneNumber: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    const currentValid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!currentValid) {
      throw new UnauthorizedException({
        code: 'CURRENT_PASSWORD_INVALID',
        message: 'Current password is incorrect',
      });
    }
    const passwordHash = await bcrypt.hash(dto.newPassword, this.env.saltRounds);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
    const db = this.prisma as PrismaWithLoginFailure;
    await db.loginFailure.deleteMany({ where: { phoneNumber: user.phoneNumber } }).catch(() => {});
    await this.sessionRevocation.revokeAllForUser(userId, 'password_changed');

    await this.audit.log({
      actorId: userId,
      action: 'PASSWORD_CHANGED',
      resourceType: 'User',
      resourceId: userId,
    });

    void this.sendPasswordEmail(userId).catch(() => {});
  }

  private async sendPasswordEmail(userId: string): Promise<void> {
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
