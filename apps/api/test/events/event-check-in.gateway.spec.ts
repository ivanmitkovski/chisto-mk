/// <reference types="jest" />

import { EventCheckInGateway } from '../../src/events/event-check-in.gateway';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('EventCheckInGateway', () => {
  it('constructs with dependencies (smoke)', () => {
    const config = { get: jest.fn().mockReturnValue('test-secret') } as unknown as ConfigService;
    const prisma = { user: { findUnique: jest.fn() } } as unknown as PrismaService;
    const gateway = new EventCheckInGateway(config, prisma);
    expect(gateway).toBeDefined();
  });
});
