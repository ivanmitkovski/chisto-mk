import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';

export type EmailSuppressionReason =
  | 'HardBounce'
  | 'SpamComplaint'
  | 'ManualSuppression'
  | 'SubscriptionChange';

export type PostmarkSuppressionRecordInput = {
  email: string;
  reason: EmailSuppressionReason;
  payload?: Prisma.InputJsonValue;
  /** When false, removes suppression (Postmark SubscriptionChange with SuppressSending=false). */
  suppress?: boolean;
};

@Injectable()
export class EmailSuppressionService {
  private readonly logger = new Logger(EmailSuppressionService.name);

  constructor(private readonly prisma: PrismaService) {}

  normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  async record(input: PostmarkSuppressionRecordInput): Promise<void> {
    const email = this.normalizeEmail(input.email);
    if (email.length === 0) {
      return;
    }

    if (input.suppress === false) {
      await this.prisma.emailSuppression.deleteMany({ where: { email } });
      this.logger.log(`Email suppression cleared email=${email} reason=${input.reason}`);
      return;
    }

    await this.prisma.emailSuppression.upsert({
      where: { email },
      create: {
        email,
        reason: input.reason,
        source: 'postmark',
        payload: input.payload ?? Prisma.JsonNull,
      },
      update: {
        reason: input.reason,
        source: 'postmark',
        payload: input.payload ?? Prisma.JsonNull,
      },
    });
    this.logger.log(`Email suppression recorded email=${email} reason=${input.reason}`);
  }

  async isSuppressed(email: string): Promise<boolean> {
    const normalized = this.normalizeEmail(email);
    if (normalized.length === 0) {
      return true;
    }
    const row = await this.prisma.emailSuppression.findUnique({
      where: { email: normalized },
      select: { email: true },
    });
    return row != null;
  }
}
