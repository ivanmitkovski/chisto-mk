import { NotFoundException } from '@nestjs/common';
import { MapMvtTilesService } from '../../src/sites/map/map-mvt-tiles.service';

jest.mock('../../src/config/feature-flags', () => ({
  loadFeatureFlags: jest.fn(),
}));

const { loadFeatureFlags } = jest.requireMock('../../src/config/feature-flags') as {
  loadFeatureFlags: jest.Mock;
};

describe('MapMvtTilesService', () => {
  function makeService() {
    const prisma: { $queryRaw: jest.Mock } = {
      $queryRaw: jest.fn(),
    };
    return { service: new MapMvtTilesService(prisma as never), prisma };
  }

  it('throws when vector flag is disabled', async () => {
    loadFeatureFlags.mockReturnValue({
      mapTileFormatVector: false,
      mapPostgisEnabled: false,
    });
    const { service } = makeService();
    await expect(service.getTileOrThrow(12, 2236, 1530)).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns a non-empty mvt buffer with deterministic etag when enabled', async () => {
    loadFeatureFlags.mockReturnValue({
      mapTileFormatVector: true,
      mapPostgisEnabled: true,
    });
    const { service, prisma } = makeService();
    const sample = Buffer.from([0x1a, 0x02, 0x08, 0x01]);
    (prisma.$queryRaw as jest.Mock).mockResolvedValue([
      {
        mvt: sample,
        max_updated: new Date('2026-05-08T16:00:00.000Z'),
        cnt: 1,
      },
    ]);

    const first = await service.getTileOrThrow(13, 4500, 3000);
    const second = await service.getTileOrThrow(13, 4500, 3000);

    expect(first.buffer.length).toBeGreaterThan(0);
    expect(first.etag).toBe(second.etag);
  });
});
