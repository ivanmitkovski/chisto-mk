import { Injectable, Logger } from '@nestjs/common';
import {
  EmailSuppressionService,
  type EmailSuppressionReason,
} from '../email/email-suppression.service';
import type { PostmarkWebhookDto } from './dto/postmark-webhook.dto';

@Injectable()
export class EmailWebhooksService {
  private readonly logger = new Logger(EmailWebhooksService.name);

  constructor(private readonly suppression: EmailSuppressionService) {}

  /**
   * Handles Postmark bounce/complaint events. Swallows errors so Postmark receives 2xx.
   */
  async handlePostmarkEvent(dto: PostmarkWebhookDto): Promise<void> {
    try {
      await this.processPostmarkEvent(dto);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(
        `Postmark webhook processing failed recordType=${dto.RecordType}: ${message}`,
      );
    }
  }

  private async processPostmarkEvent(dto: PostmarkWebhookDto): Promise<void> {
    const recordType = dto.RecordType;
    const email = dto.Email;

    if (recordType === 'SubscriptionChange') {
      const suppress = dto.SuppressSending !== false;
      await this.suppression.record({
        email,
        reason: 'SubscriptionChange',
        suppress,
        payload: { recordType, suppressSending: dto.SuppressSending },
      });
      return;
    }

    const reason = mapRecordTypeToReason(recordType);
    if (reason == null) {
      return;
    }

    await this.suppression.record({
      email,
      reason,
      payload: { recordType, type: dto.Type },
    });
  }
}

function mapRecordTypeToReason(
  recordType: string,
): EmailSuppressionReason | null {
  switch (recordType) {
    case 'HardBounce':
    case 'Bounce':
      return 'HardBounce';
    case 'SpamComplaint':
      return 'SpamComplaint';
    case 'ManualSuppression':
      return 'ManualSuppression';
    default:
      return null;
  }
}
