import { EmailWebhooksController } from '../../src/webhooks/controllers/email-webhooks.controller';

describe('EmailWebhooksController', () => {
  it('returns ok after handling event', async () => {
    const service = { handlePostmarkEvent: jest.fn().mockResolvedValue(undefined) };
    const controller = new EmailWebhooksController(service as never);
    const result = await controller.handlePostmark({
      RecordType: 'HardBounce',
      Email: 'a@b.com',
    });
    expect(result).toEqual({ ok: true });
    expect(service.handlePostmarkEvent).toHaveBeenCalled();
  });
});
