import { MapProjectionDiffService } from '../../src/sites/map/map-projection-diff.service';

describe('MapProjectionDiffService hero thumbnail', () => {
  const diff = new MapProjectionDiffService();

  it('uses heroReport media for thumbnail instead of latest report', () => {
    const row = diff.computeUpsertRow({
      id: 'site-1',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-02-01'),
      latitude: 41.6,
      longitude: 21.7,
      address: null,
      description: null,
      status: 'VERIFIED',
      upvotesCount: 1,
      commentsCount: 0,
      savesCount: 0,
      sharesCount: 0,
      isArchivedByAdmin: false,
      archivedAt: null,
      heroReport: { mediaUrls: ['hero.jpg'] },
      reports: [
        {
          title: 'Latest',
          description: null,
          category: 'illegal',
          reportNumber: 'R-2',
          createdAt: new Date('2026-05-01'),
          mediaUrls: ['latest.jpg'],
        },
      ],
      _count: { reports: 2 },
    });

    expect(row.thumbnailUrl).toBe('hero.jpg');
    expect(row.latestReportTitle).toBe('Latest');
  });

  it('falls back to latest report media for REPORTED sites without hero', () => {
    const row = diff.computeUpsertRow({
      id: 'site-pending',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-02-01'),
      latitude: 41.6,
      longitude: 21.7,
      address: 'Skopje',
      description: null,
      status: 'REPORTED',
      upvotesCount: 0,
      commentsCount: 0,
      savesCount: 0,
      sharesCount: 0,
      isArchivedByAdmin: false,
      archivedAt: null,
      heroReport: null,
      reports: [
        {
          title: 'Pending title',
          description: null,
          category: 'illegal',
          reportNumber: 'R-1',
          createdAt: new Date('2026-05-01'),
          mediaUrls: ['pending.jpg'],
        },
      ],
      _count: { reports: 1 },
    });

    expect(row.thumbnailUrl).toBe('pending.jpg');
    expect(row.latestReportTitle).toBe('Pending title');
  });

  it('does not use latest report media for VERIFIED sites without hero', () => {
    const row = diff.computeUpsertRow({
      id: 'site-verified-no-hero',
      createdAt: new Date('2026-01-01'),
      updatedAt: new Date('2026-02-01'),
      latitude: 41.6,
      longitude: 21.7,
      address: null,
      description: null,
      status: 'VERIFIED',
      upvotesCount: 0,
      commentsCount: 0,
      savesCount: 0,
      sharesCount: 0,
      isArchivedByAdmin: false,
      archivedAt: null,
      heroReport: null,
      reports: [
        {
          title: 'Latest',
          description: null,
          category: 'illegal',
          reportNumber: 'R-1',
          createdAt: new Date('2026-05-01'),
          mediaUrls: ['latest.jpg'],
        },
      ],
      _count: { reports: 1 },
    });

    expect(row.thumbnailUrl).toBeNull();
  });
});
