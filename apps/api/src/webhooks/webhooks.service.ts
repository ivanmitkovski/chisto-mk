import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { TwilioStatusDto } from './dto/twilio-status.dto';

@Injectable()
export class WebhooksService {
  private readonly logger = new Logger(WebhooksService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Handles Twilio SMS status callbacks. Swallows errors so Twilio always receives 2xx
   * (avoids retry storms and duplicate handling).
   */
  async handleTwilioSmsStatus(dto: TwilioStatusDto): Promise<void> {
    try {
      await this.processTwilioSmsStatus(dto);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(
        `Twilio status callback processing failed sid=${dto.MessageSid} status=${dto.MessageStatus}: ${message}`,
      );
    }
  }

  private async processTwilioSmsStatus(dto: TwilioStatusDto): Promise<void> {
    const { MessageSid, MessageStatus, To, From, ErrorCode, ErrorMessage } = dto;

    switch (MessageStatus) {
      case 'delivered':
        this.logger.log(
          `Twilio SMS delivered sid=${MessageSid} to=${To} from=${From}`,
        );
        break;
      case 'failed':
      case 'undelivered':
        this.logger.warn(
          `Twilio SMS ${MessageStatus} sid=${MessageSid} to=${To} from=${From} errorCode=${ErrorCode ?? 'n/a'} errorMessage=${ErrorMessage ?? 'n/a'}`,
        );
        break;
      case 'queued':
      case 'sent':
        this.logger.log(
          `Twilio SMS ${MessageStatus} sid=${MessageSid} to=${To} from=${From}`,
        );
        break;
    }

    // Keep PrismaService injected for future delivery-log persistence without extra round-trips today.
    void this.prisma;
  }
}
