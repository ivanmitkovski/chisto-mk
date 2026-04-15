import { SitesMapQueryService } from '../../src/sites/sites-map-query.service';

function makeMapService(
  prisma: any,
  reportsUpload?: { signUrls: jest.Mock },
): SitesMapQueryService {
  const upload =
    reportsUpload ?? ({ signUrls: jest.fn(async (v: string[]) => v) } as any);
  return new SitesMapQueryService(prisma, upload);
}

describe('SitesMapQueryService', () => {
  it('rejects partial viewport bounds for map queries', async () => {
    const service = makeMapService({} as any);
    await expect(
      service.findAllForMap({
        lat: 41.6,
        lng: 21.7,
        radiusKm: 20,
        limit: 120,
        minLat: 41.55,
      } as any),
    ).rejects.toMatchObject({
      response: { code: 'INVALID_MAP_VIEWPORT' },
    });
  });

  it('uses dedicated viewport-aware map query without feed ranking', async () => {
    const createdAt = new Date('2026-03-27T10:00:00.000Z');
    const siteRow = {
      id: 'site_map_1',
      latitude: 41.61,
      longitude: 21.75,
      address: null,
      description: 'Map only',
      status: 'REPORTED',
      createdAt,
      updatedAt: createdAt,
      upvotesCount: 3,
      commentsCount: 1,
      savesCount: 0,
      sharesCount: 0,
      _count: { reports: 1 },
      reports: [
        {
          title: 'Map title',
          description: 'Map desc',
          mediaUrls: ['media-1'],
          category: 'illegal_waste',
          createdAt,
          reportNumber: 'R-44',
        },
      ],
    };
    const prismaMock = {
      $queryRaw: jest
        .fn()
        .mockResolvedValueOnce([{ ok: 1 }])
        .mockResolvedValueOnce([{ id: 'site_map_1' }]),
      site: {
        findMany: jest.fn(async () => [siteRow]),
      },
    } as any;
    const service = makeMapService(prismaMock, {
      signUrls: jest.fn(async () => ['signed-media']),
    } as any);

    const result = await service.findAllForMap({
      lat: 41.6086,
      lng: 21.7453,
      radiusKm: 20,
      limit: 120,
      minLat: 41.55,
      maxLat: 41.7,
      minLng: 21.6,
      maxLng: 21.85,
    } as any);

    expect(prismaMock.$queryRaw).toHaveBeenCalled();
    expect(prismaMock.site.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: { in: ['site_map_1'] } },
        select: expect.any(Object),
      }),
    );
    expect(result.data[0]).toEqual(
      expect.objectContaining({
        id: 'site_map_1',
        latestReportMediaUrls: ['signed-media'],
      }),
    );
    expect(result.meta?.signedMediaExpiresAt).toEqual(expect.any(String));
    expect(Date.parse(result.meta!.signedMediaExpiresAt)).not.toBeNaN();
  });

  it('falls back to Prisma bbox map query when PostGIS extension is missing', async () => {
    const createdAt = new Date('2026-03-27T10:00:00.000Z');
    const prismaMock = {
      $queryRaw: jest.fn().mockResolvedValueOnce([]),
      site: {
        findMany: jest.fn(async () => [
          {
            id: 'site_legacy_1',
            latitude: 41.61,
            longitude: 21.75,
            address: null,
            description: null,
            status: 'REPORTED',
            createdAt,
            updatedAt: createdAt,
            upvotesCount: 0,
            commentsCount: 0,
            savesCount: 0,
            sharesCount: 0,
            _count: { reports: 0 },
            reports: [],
          },
        ]),
      },
    } as any;
    const service = makeMapService(prismaMock, {
      signUrls: jest.fn(async () => []),
    } as any);

    await service.findAllForMap({
      lat: 41.6086,
      lng: 21.7453,
      radiusKm: 20,
      limit: 120,
      minLat: 41.55,
      maxLat: 41.7,
      minLng: 21.6,
      maxLng: 21.85,
    } as any);

    expect(prismaMock.site.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        take: 120,
        where: expect.objectContaining({
          latitude: expect.objectContaining({ gte: 41.55, lte: 41.7 }),
          longitude: expect.objectContaining({ gte: 21.6, lte: 21.85 }),
        }),
      }),
    );
  });
});
