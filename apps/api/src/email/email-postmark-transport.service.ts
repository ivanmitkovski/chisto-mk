import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { fetchWithTimeout } from '../common/resilience/fetch-with-timeout';
import type { EmailSendPayload, EmailTransport } from './email-transport.types';

const POSTMARK_TIMEOUT_MS = 15_000;

const POSTMARK_API_URL = 'https://api.postmarkapp.com/email';

/**
 * Postmark HTTP API transport with List-Unsubscribe headers (RFC 8058).
 */
@Injectable()
export class EmailPostmarkTransportService implements EmailTransport {
  private readonly logger = new Logger(EmailPostmarkTransportService.name);

  constructor(private readonly config: ConfigService) {}

  async send(payload: EmailSendPayload): Promise<boolean> {
    const serverToken = this.config.get<string>('POSTMARK_SERVER_TOKEN')?.trim();
    if (!serverToken) {
      this.logger.warn('POSTMARK_SERVER_TOKEN not set; skipping Postmark send');
      return false;
    }

    const body: Record<string, unknown> = {
      From: payload.fromHeader,
      To: payload.to,
      Subject: payload.subject,
      HtmlBody: payload.html,
      TextBody: payload.text,
      MessageStream: 'outbound',
    };
    if (payload.listUnsubscribeUrl) {
      body.Headers = [
        { Name: 'List-Unsubscribe', Value: `<${payload.listUnsubscribeUrl}>` },
        { Name: 'List-Unsubscribe-Post', Value: 'List-Unsubscribe=One-Click' },
      ];
    }

    return this.sendWithRetry(serverToken, body, payload.templateId);
  }

  private static isTransientStatus(status: number): boolean {
    return status === 429 || status === 500 || status === 502 || status === 503;
  }

  private async sendWithRetry(
    serverToken: string,
    body: Record<string, unknown>,
    templateId: EmailSendPayload['templateId'],
  ): Promise<boolean> {
    const pause = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const res = await fetchWithTimeout(POSTMARK_API_URL, {
          timeoutMs: POSTMARK_TIMEOUT_MS,
          method: 'POST',
          headers: {
            'X-Postmark-Server-Token': serverToken,
            Accept: 'application/json',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(body),
        });

        if (res.ok) {
          const data = (await res.json()) as { MessageID?: string };
          this.logger.log(
            `Postmark sent messageId=${data.MessageID ?? 'n/a'} template=${templateId}`,
          );
          return true;
        }

        const detail = await res.text();
        const retry = attempt === 0 && EmailPostmarkTransportService.isTransientStatus(res.status);
        if (retry) {
          this.logger.warn(
            `Postmark transient error status=${res.status} template=${templateId}; retry after 500ms: ${detail}`,
          );
          await pause(500);
          continue;
        }
        this.logger.warn(
          `Postmark send failed status=${res.status} template=${templateId}: ${detail}`,
        );
        return false;
      } catch (err) {
        const detail = err instanceof Error ? err.message : String(err);
        if (attempt === 0) {
          this.logger.warn(
            `Postmark network error template=${templateId}; retry after 500ms: ${detail}`,
          );
          await pause(500);
          continue;
        }
        this.logger.warn(`Postmark send failed template=${templateId}: ${detail}`);
        return false;
      }
    }
    return false;
  }
}
