/// <reference types="jest" />

import { BadRequestException } from '@nestjs/common';
import { Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { FieldBatchDto } from '../../src/events/dto/field-batch.dto';
import { EventsFieldBatchService } from '../../src/events/events-field-batch.service';
import { EventLiveImpactService } from '../../src/events/event-live-impact.service';

function user(): AuthenticatedUser {
  return {
    userId: 'u1',
    email: 'u1@test.chisto.mk',
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventsFieldBatchService', () => {
  it('applyBatch rejects empty operations', async () => {
    const liveImpact = { patch: jest.fn() } as unknown as EventLiveImpactService;
    const svc = new EventsFieldBatchService(liveImpact);
    const dto = new FieldBatchDto();
    dto.operations = [];

    await expect(svc.applyBatch(user(), dto)).rejects.toBeInstanceOf(BadRequestException);
  });
});
