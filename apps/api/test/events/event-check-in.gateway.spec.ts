/// <reference types="jest" />

import { EventCheckInGateway } from '../../src/events/event-check-in.gateway';
import { ConfigService } from '@nestjs/config';
import { CheckInRepository } from '../../src/events/check-in.repository';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('EventCheckInGateway', () => {
  it('constructs with dependencies (smoke)', () => {
    const config = { get: jest.fn().mockReturnValue('test-secret') } as unknown as ConfigService;
    const prisma = {} as unknown as PrismaService;
    const checkInRepository = {
      findUserForCheckInWebsocket: jest.fn(),
      isEventParticipantOrOrganizer: jest.fn(),
    } as unknown as CheckInRepository;
    const liveImpact = { publishFromOrganizerSocket: jest.fn() };
    const roomEmitter = { attachServer: jest.fn(), emitToRoom: jest.fn() };
    const gateway = new EventCheckInGateway(
      config,
      prisma,
      checkInRepository,
      liveImpact as never,
      roomEmitter as never,
    );
    expect(gateway).toBeDefined();
  });

  it('handleConnection emits CHECK_IN_UNAUTHORIZED and disconnects when token is missing', async () => {
    const config = { get: jest.fn().mockReturnValue('test-secret') } as unknown as ConfigService;
    const prisma = {} as unknown as PrismaService;
    const checkInRepository = {
      findUserForCheckInWebsocket: jest.fn(),
      isEventParticipantOrOrganizer: jest.fn(),
    } as unknown as CheckInRepository;
    const liveImpact = { publishFromOrganizerSocket: jest.fn() };
    const roomEmitter = { attachServer: jest.fn(), emitToRoom: jest.fn() };
    const gateway = new EventCheckInGateway(
      config,
      prisma,
      checkInRepository,
      liveImpact as never,
      roomEmitter as never,
    );

    const emit = jest.fn();
    const disconnect = jest.fn();
    const client = {
      id: 'sock-1',
      handshake: { headers: {}, auth: {} },
      data: {},
      emit,
      disconnect,
    };

    await gateway.handleConnection(client as never);

    expect(emit).toHaveBeenCalledWith(
      'error',
      expect.objectContaining({
        code: 'CHECK_IN_UNAUTHORIZED',
        message: 'Authentication failed',
      }),
    );
    expect(disconnect).toHaveBeenCalledWith(true);
  });
});
