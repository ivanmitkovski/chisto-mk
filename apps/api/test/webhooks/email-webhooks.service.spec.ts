import { EmailWebhooksService } from '../../src/webhooks/email-webhooks.service';

describe('EmailWebhooksService', () => {
  const suppression = {
    record: jest.fn(),
  };

  let service: EmailWebhooksService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new EmailWebhooksService(suppression as never);
  });

  it('records HardBounce', async () => {
    await service.handlePostmarkEvent({
      RecordType: 'HardBounce',
      Email: 'bounced@example.com',
    });

    expect(suppression.record).toHaveBeenCalledWith(
      expect.objectContaining({
        email: 'bounced@example.com',
        reason: 'HardBounce',
      }),
    );
  });

  it('records SpamComplaint', async () => {
    await service.handlePostmarkEvent({
      RecordType: 'SpamComplaint',
      Email: 'spam@example.com',
    });

    expect(suppression.record).toHaveBeenCalledWith(
      expect.objectContaining({ reason: 'SpamComplaint' }),
    );
  });

  it('handles SubscriptionChange with suppress false', async () => {
    await service.handlePostmarkEvent({
      RecordType: 'SubscriptionChange',
      Email: 'user@example.com',
      SuppressSending: false,
    });

    expect(suppression.record).toHaveBeenCalledWith(
      expect.objectContaining({
        email: 'user@example.com',
        reason: 'SubscriptionChange',
        suppress: false,
      }),
    );
  });
});
