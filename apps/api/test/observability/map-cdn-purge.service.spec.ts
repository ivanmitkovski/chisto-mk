import { MapCdnPurgeService } from '../../src/observability/map-cdn-purge.service';

describe('MapCdnPurgeService', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  function makeService() {
    const prisma = {
      $executeRaw: jest.fn().mockResolvedValue(1),
    } as never;
    return new MapCdnPurgeService(prisma);
  }

  it('short-circuits for empty keys', () => {
    process.env.CDN_PROVIDER = 'none';
    const service = makeService();
    expect(() => service.enqueueSurrogateKeys([])).not.toThrow();
  });

  it('does not throw when provider is none', () => {
    process.env.CDN_PROVIDER = 'none';
    const service = makeService();
    expect(() => service.enqueueSurrogateKeys(['map-tile'])).not.toThrow();
  });
});
