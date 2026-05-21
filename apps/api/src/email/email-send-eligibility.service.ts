import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationType } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import { EmailSuppressionService } from './email-suppression.service';
import { isValidRecipientEmail } from './email-recipient';

/**
 * Answers whether outbound email is allowed at all and whether a user muted a notification type.
 */
@Injectable()
export class EmailSendEligibilityService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly featureFlags: FeatureFlagsService,
    private readonly suppression: EmailSuppressionService,
  ) {}

  async isGloballyEnabled(): Promise<boolean> {
    const fromEnv = this.config.get<string>('EMAIL_ENABLED', 'false') === 'true';
    await this.featureFlags.ensureDefaults();
    const row = await this.prisma.featureFlag.findUnique({
      where: { key: 'email_enabled' },
      select: { enabled: true },
    });
    return row?.enabled ?? fromEnv;
  }

  /** False when address is invalid or on the global suppression list. */
  async canSendToAddress(email: string): Promise<boolean> {
    const trimmed = email.trim();
    if (!isValidRecipientEmail(trimmed)) {
      return false;
    }
    if (await this.suppression.isSuppressed(trimmed)) {
      return false;
    }
    return true;
  }

  /** True if this user should not receive email for the given notification type. */
  async isMutedForType(userId: string, type: NotificationType): Promise<boolean> {
    const pref = await this.prisma.userNotificationPreference.findUnique({
      where: { userId_type: { userId, type } },
      select: { emailMuted: true, emailMutedUntil: true },
    });
    if (!pref?.emailMuted) return false;
    if (pref.emailMutedUntil == null) return true;
    if (pref.emailMutedUntil.getTime() > Date.now()) return true;
    await this.prisma.userNotificationPreference.update({
      where: { userId_type: { userId, type } },
      data: { emailMuted: false, emailMutedUntil: null },
    });
    return false;
  }
}
