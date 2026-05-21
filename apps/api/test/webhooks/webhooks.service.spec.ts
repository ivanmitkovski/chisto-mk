import { WebhooksService } from '../../src/webhooks/webhooks.service';
import type { TwilioStatusDto } from '../../src/webhooks/dto/twilio-status.dto';

describe('WebhooksService', () => {
  const service = new WebhooksService();

  it('handleTwilioSmsStatus does not throw for delivered', async () => {
    const dto: TwilioStatusDto = {
      MessageSid: 'SM1',
      MessageStatus: 'delivered',
      To: '+15550001111',
      From: '+15550002222',
    };
    await expect(service.handleTwilioSmsStatus(dto)).resolves.toBeUndefined();
  });

  it('handles failed and undelivered without throwing', async () => {
    for (const status of ['failed', 'undelivered'] as const) {
      await expect(
        service.handleTwilioSmsStatus({
          MessageSid: 'SM2',
          MessageStatus: status,
          To: '+15550001111',
          From: '+15550002222',
          ErrorCode: '30003',
          ErrorMessage: 'unreachable',
        }),
      ).resolves.toBeUndefined();
    }
  });

  it('handles queued and sent', async () => {
    for (const status of ['queued', 'sent'] as const) {
      await expect(
        service.handleTwilioSmsStatus({
          MessageSid: 'SM3',
          MessageStatus: status,
          To: '+15550001111',
          From: '+15550002222',
        }),
      ).resolves.toBeUndefined();
    }
  });
});
