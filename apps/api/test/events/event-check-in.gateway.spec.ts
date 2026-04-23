/// <reference types="jest" />

import { EventCheckInGateway } from '../../src/events/event-check-in.gateway';
import { ConfigService } from '@nestjs/config';
import { CheckInRepository } from '../../src/events/check-in.repository';

describe('EventCheckInGateway', () => {
  it('constructs with dependencies (smoke)', () => {
    const config = { get: jest.fn().mockReturnValue('test-secret') } as unknown as ConfigService;
    const checkInRepository = {
      findUserForCheckInWebsocket: jest.fn(),
      isEventParticipantOrOrganizer: jest.fn(),
    } as unknown as CheckInRepository;
    const liveImpact = { publishFromOrganizerSocket: jest.fn() };
    const gateway = new EventCheckInGateway(config, checkInRepository, liveImpact as never);
    expect(gateway).toBeDefined();
  });
});
