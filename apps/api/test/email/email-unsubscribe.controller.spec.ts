/// <reference types="jest" />

import type { Response } from 'express';
import { HttpStatus } from '@nestjs/common';
import { EmailUnsubscribeController } from '../../src/email/controllers/email-unsubscribe.controller';

describe('EmailUnsubscribeController', () => {
  it('GET unsubscribe without token responds with invalid message HTML', async () => {
    const prisma = { userNotificationPreference: { upsert: jest.fn() } };
    const unsubscribeTokens = { verify: jest.fn() };
    const controller = new EmailUnsubscribeController(prisma as never, unsubscribeTokens as never);

    const res = {
      status: jest.fn().mockReturnThis(),
      type: jest.fn().mockReturnThis(),
      send: jest.fn(),
    } as unknown as Response;

    await controller.unsubscribeGet(undefined, res);

    expect(res.status).toHaveBeenCalledWith(HttpStatus.OK);
    expect(res.type).toHaveBeenCalledWith('html');
    expect(res.send).toHaveBeenCalledWith(expect.stringMatching(/invalid/i));
    expect(prisma.userNotificationPreference.upsert).not.toHaveBeenCalled();
  });
});
