/// <reference types="jest" />
import { AdminBroadcastsDispatchService } from '../../src/admin-control/services/admin-broadcasts-dispatch.service';

describe('AdminBroadcastsDispatchService', () => {
  it('dispatches only to active users for specific audience', async () => {
    const campaign = {
      id: 'campaign-1',
      title: 'Hello',
      body: 'World',
      audience: 'users' as const,
      audienceUserIds: ['active-1', 'inactive-1'],
      deeplink: null,
    };

    const broadcasts = {
      claimForSend: jest.fn().mockResolvedValue(campaign),
      updateSentCount: jest.fn().mockResolvedValue(campaign),
    };
    const audienceResolver = {
      resolveAudienceUserIds: jest.fn().mockResolvedValue(['active-1']),
    };
    const dispatcher = {
      dispatchToUser: jest.fn().mockResolvedValue(undefined),
    };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };

    const service = new AdminBroadcastsDispatchService(
      broadcasts as never,
      audienceResolver as never,
      dispatcher as never,
      audit as never,
    );

    const result = await service.send('campaign-1', {
      userId: 'admin-1',
      email: 'admin@example.com',
      phoneNumber: '+38970000001',
      role: 'ADMIN',
    });

    expect(audienceResolver.resolveAudienceUserIds).toHaveBeenCalledWith(campaign);
    expect(dispatcher.dispatchToUser).toHaveBeenCalledTimes(1);
    expect(dispatcher.dispatchToUser).toHaveBeenCalledWith(
      'active-1',
      expect.objectContaining({ title: 'Hello', body: 'World' }),
    );
    expect(result).toEqual({ sentCount: 1, failedCount: 0 });
    expect(broadcasts.updateSentCount).toHaveBeenCalledWith('campaign-1', 1);
  });
});
