/// <reference types="jest" />

import { EventEmitter2 } from '@nestjs/event-emitter';
import { SiteStatus } from '../../src/prisma-client';
import {
  SITE_NOTIFICATION_SYSTEM_ACTOR_ID,
  SitesReporterNotificationService,
} from '../../src/sites/services/sites-reporter-notification.service';

describe('SitesReporterNotificationService SITE_UPDATE', () => {
  it('emits SITE_UPDATE to site reporters on meaningful status change', async () => {
    const eventEmitter = { emit: jest.fn() } as unknown as EventEmitter2;
    const prisma = {
      site: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'site-1',
          reports: [{ reporterId: 'reporter-1' }, { reporterId: 'reporter-2' }],
        }),
      },
      user: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      userDeviceToken: {
        findMany: jest.fn().mockResolvedValue([
          { userId: 'reporter-1', locale: 'mk' },
          { userId: 'reporter-2', locale: 'en' },
        ]),
      },
    } as never;

    const svc = new SitesReporterNotificationService(prisma, eventEmitter);
    svc.emitSiteStatusUpdate('site-1', SITE_NOTIFICATION_SYSTEM_ACTOR_ID, SiteStatus.CLEANED);
    await new Promise((r) => setImmediate(r));

    expect(eventEmitter.emit).toHaveBeenCalledTimes(2);
    expect(eventEmitter.emit).toHaveBeenCalledWith(
      'notification.send',
      expect.objectContaining({
        type: 'SITE_UPDATE',
        groupKey: 'SITE_UPDATE:site:site-1',
        data: expect.objectContaining({
          siteId: 'site-1',
          actorUserId: SITE_NOTIFICATION_SYSTEM_ACTOR_ID,
          status: SiteStatus.CLEANED,
        }),
      }),
    );
  });

  it('does not emit SITE_UPDATE for non-meaningful statuses', async () => {
    const eventEmitter = { emit: jest.fn() } as unknown as EventEmitter2;
    const findUnique = jest.fn();
    const prisma = { site: { findUnique } } as never;
    const svc = new SitesReporterNotificationService(prisma, eventEmitter);
    svc.emitSiteStatusUpdate('site-1', SITE_NOTIFICATION_SYSTEM_ACTOR_ID, SiteStatus.DISPUTED);
    await new Promise((r) => setImmediate(r));
    expect(findUnique).not.toHaveBeenCalled();
    expect(eventEmitter.emit).not.toHaveBeenCalled();
  });
});
