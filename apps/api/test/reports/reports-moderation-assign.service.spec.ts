/// <reference types="jest" />
import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ReportsModerationAssignService } from '../../src/reports/services/reports-moderation-assign.service';
import { Role } from '../../src/prisma-client';

describe('ReportsModerationAssignService', () => {
  const actor = { userId: 'mod-1', role: Role.ADMIN };

  it('assigns report to the current moderator and moves NEW to IN_REVIEW', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'NEW',
          moderatedById: null,
        }),
        update: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: 'mod-1',
        }),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'mod-1',
          firstName: 'Ada',
          lastName: 'Lovelace',
          role: Role.ADMIN,
        }),
      },
    };
    const service = new ReportsModerationAssignService(prisma);

    const result = await service.assignReport('r1', {}, actor as never);

    expect(result.assignedModeratorId).toBe('mod-1');
    expect(result.assignedModeratorName).toBe('Ada Lovelace');
    expect(result.status).toBe('IN_REVIEW');
  });

  it('releases assignment when unassign is true', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: 'mod-1',
        }),
        update: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: null,
        }),
      },
    };
    const service = new ReportsModerationAssignService(prisma);

    const result = await service.assignReport('r1', { unassign: true }, actor as never);

    expect(result.assignedModeratorId).toBeNull();
    expect(result.assignedModeratorName).toBeNull();
  });

  it('allows admin to assign report to another moderator', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: 'mod-1',
        }),
        update: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: 'mod-2',
        }),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'mod-2',
          firstName: 'Grace',
          lastName: 'Hopper',
          role: Role.SUPPORT,
        }),
      },
    };
    const service = new ReportsModerationAssignService(prisma);

    const result = await service.assignReport('r1', { moderatorId: 'mod-2' }, actor as never);

    expect(result.assignedModeratorId).toBe('mod-2');
    expect(result.assignedModeratorName).toBe('Grace Hopper');
  });

  it('allows super admin to assign report to another moderator', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'NEW',
          moderatedById: null,
        }),
        update: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: 'mod-2',
        }),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'mod-2',
          firstName: 'Grace',
          lastName: 'Hopper',
          role: Role.ADMIN,
        }),
      },
    };
    const service = new ReportsModerationAssignService(prisma);
    const superAdmin = { userId: 'super-1', role: Role.SUPER_ADMIN };

    const result = await service.assignReport('r1', { moderatorId: 'mod-2' }, superAdmin as never);

    expect(result.assignedModeratorId).toBe('mod-2');
    expect(result.status).toBe('IN_REVIEW');
  });

  it('allows admin to unassign someone else assignment', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: 'mod-2',
        }),
        update: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: null,
        }),
      },
    };
    const service = new ReportsModerationAssignService(prisma);

    const result = await service.assignReport('r1', { unassign: true }, actor as never);

    expect(result.assignedModeratorId).toBeNull();
  });

  it('forbids support staff from unassigning another moderator', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: 'mod-2',
        }),
      },
    };
    const service = new ReportsModerationAssignService(prisma);
    const supportActor = { userId: 'support-1', role: Role.SUPPORT };

    await expect(
      service.assignReport('r1', { unassign: true }, supportActor as never),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects assignment for terminal reports', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'APPROVED',
          moderatedById: 'mod-1',
        }),
      },
    };
    const service = new ReportsModerationAssignService(prisma);

    await expect(service.assignReport('r1', {}, actor as never)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('forbids support staff from assigning to another moderator', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'IN_REVIEW',
          moderatedById: null,
        }),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'mod-2',
          firstName: 'Other',
          lastName: 'Mod',
          role: Role.ADMIN,
        }),
      },
    };
    const service = new ReportsModerationAssignService(prisma);
    const supportActor = { userId: 'support-1', role: Role.SUPPORT };

    await expect(
      service.assignReport('r1', { moderatorId: 'mod-2' }, supportActor as never),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('throws when report is missing', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue(null),
      },
    };
    const service = new ReportsModerationAssignService(prisma);

    await expect(service.assignReport('missing', {}, actor as never)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
