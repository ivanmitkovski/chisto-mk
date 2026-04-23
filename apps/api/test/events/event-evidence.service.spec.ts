/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { Role } from '../../src/prisma-client';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';
import { EventEvidenceService } from '../../src/events/event-evidence.service';
import { PrismaService } from '../../src/prisma/prisma.service';
import { ReportsUploadService } from '../../src/reports/reports-upload.service';

function user(): AuthenticatedUser {
  return {
    userId: 'u1',
    email: 'u1@test.chisto.mk',
    phoneNumber: '+38970000000',
    role: Role.USER,
  };
}

describe('EventEvidenceService', () => {
  it('listForEvent throws EVENT_NOT_FOUND when event not visible', async () => {
    const prisma = {
      cleanupEvent: { findFirst: jest.fn().mockResolvedValue(null) },
      eventEvidencePhoto: { findMany: jest.fn() },
    } as unknown as PrismaService;
    const uploads = {} as unknown as ReportsUploadService;
    const svc = new EventEvidenceService(prisma, uploads);

    await expect(svc.listForEvent('evt-1', user())).rejects.toBeInstanceOf(NotFoundException);
  });
});
