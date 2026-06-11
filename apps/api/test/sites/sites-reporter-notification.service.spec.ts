/// <reference types="jest" />
import { EventEmitter2 } from '@nestjs/event-emitter';
import { SitesReporterNotificationService } from '../../src/sites/services/sites-reporter-notification.service';

describe('SitesReporterNotificationService', () => {
  it('includes actorUserId and targetAction in UPVOTE notification data', async () => {
    const eventEmitter = { emit: jest.fn() } as unknown as EventEmitter2;
    const prisma = {
      site: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'site-1',
          reports: [{ reporterId: 'reporter-1' }],
        }),
      },
      user: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      userDeviceToken: {
        findMany: jest.fn().mockResolvedValue([{ userId: 'reporter-1', locale: 'mk' }]),
      },
    } as never;

    const svc = new SitesReporterNotificationService(prisma, eventEmitter);
    svc.emitForSiteActivity('site-1', 'actor-1', 'UPVOTE', 'body');

    await new Promise((r) => setImmediate(r));

    expect(eventEmitter.emit).toHaveBeenCalledWith(
      'notification.send',
      expect.objectContaining({
        type: 'UPVOTE',
        data: expect.objectContaining({
          siteId: 'site-1',
          actorUserId: 'actor-1',
          targetAction: 'show_upvoters',
        }),
      }),
    );
  });

  it('includes commentId in COMMENT notification data', async () => {
    const eventEmitter = { emit: jest.fn() } as unknown as EventEmitter2;
    const prisma = {
      site: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'site-1',
          reports: [{ reporterId: 'reporter-1' }],
        }),
      },
      user: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      userDeviceToken: {
        findMany: jest.fn().mockResolvedValue([{ userId: 'reporter-1', locale: 'mk' }]),
      },
    } as never;

    const svc = new SitesReporterNotificationService(prisma, eventEmitter);
    svc.emitForSiteActivity(
      'site-1',
      'actor-1',
      'COMMENT',
      'body',
      'preview',
      'comment-99',
    );

    await new Promise((r) => setImmediate(r));

    expect(eventEmitter.emit).toHaveBeenCalledWith(
      'notification.send',
      expect.objectContaining({
        type: 'COMMENT',
        data: expect.objectContaining({
          actorUserId: 'actor-1',
          commentId: 'comment-99',
          targetAction: 'show_comments',
          messagePreview: 'preview',
        }),
      }),
    );
  });
});
