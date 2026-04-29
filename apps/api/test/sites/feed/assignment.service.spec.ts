import { AssignmentService } from '../../../src/sites/feed/experiments/assignment.service';

describe('AssignmentService', () => {
  it('assigns deterministic variant bucket', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      $executeRaw: jest.fn().mockResolvedValue(1),
    } as never;
    const svc = new AssignmentService(prisma);
    const first = await svc.assign('user_1');
    const second = await svc.assign('user_1');
    expect(['v1', 'v2', 'v2-shadow']).toContain(first);
    expect(second).toBe(first);
  });

  it('keeps an existing persisted assignment sticky', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([{ variant: 'v2-shadow' }]),
      $executeRaw: jest.fn(),
    } as never;
    const svc = new AssignmentService(prisma);

    await expect(svc.assign('user_1')).resolves.toBe('v2-shadow');
    expect((prisma as { $executeRaw: jest.Mock }).$executeRaw).not.toHaveBeenCalled();
  });
});
