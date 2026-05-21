/// <reference types="jest" />
import { UserDsarExportService } from '../../src/auth/user-dsar-export.service';

describe('UserDsarExportService', () => {
  it('buildExport includes profile and sections', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          email: 'a@b.c',
          firstName: 'A',
          lastName: 'B',
        }),
      },
      report: { findMany: jest.fn().mockResolvedValue([]) },
      siteComment: { findMany: jest.fn().mockResolvedValue([]) },
      userNotification: { findMany: jest.fn().mockResolvedValue([]) },
      userNotificationPreference: { findMany: jest.fn().mockResolvedValue([]) },
      userSession: { findMany: jest.fn().mockResolvedValue([]) },
      pointTransaction: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const svc = new UserDsarExportService(prisma as never);
    const out = await svc.buildExport('u1');
    expect(out.format).toBe('chisto-dsar-v1');
    expect(out.profile).toMatchObject({ id: 'u1' });
  });

  it('streamSections yields NDJSON lines', async () => {
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1' }) },
      report: { findMany: jest.fn().mockResolvedValue([]) },
      siteComment: { findMany: jest.fn().mockResolvedValue([]) },
      userNotification: { findMany: jest.fn().mockResolvedValue([]) },
      userNotificationPreference: { findMany: jest.fn().mockResolvedValue([]) },
      userSession: { findMany: jest.fn().mockResolvedValue([]) },
      pointTransaction: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const svc = new UserDsarExportService(prisma as never);
    const lines: string[] = [];
    for await (const line of svc.streamSections('u1')) {
      lines.push(line);
    }
    expect(lines.length).toBeGreaterThan(0);
    expect(JSON.parse(lines[0])).toHaveProperty('section');
  });
});
