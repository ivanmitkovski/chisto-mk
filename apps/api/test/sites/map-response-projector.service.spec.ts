import { MapResponseProjectorService } from '../../src/sites/map/map-response-projector.service';
import { MapQueryValidatorService } from '../../src/sites/map/map-query-validator.service';
import type { MapProjectionRow } from '../../src/sites/map/map-types';

describe('MapResponseProjectorService lite pending preview', () => {
  const projector = new MapResponseProjectorService(new MapQueryValidatorService());

  const baseRow = (): MapProjectionRow => ({
    siteId: 'site-1',
    latitude: 41.6,
    longitude: 21.7,
    address: 'Skopje',
    description: null,
    status: 'REPORTED',
    thumbnailUrl: 'pending.jpg',
    pollutionCategory: 'illegal',
    latestReportTitle: 'Pending title',
    latestReportDescription: 'Body',
    latestReportNumber: 'R-1',
    reportCount: 1,
    upvotesCount: 0,
    commentsCount: 0,
    savesCount: 0,
    sharesCount: 0,
    latestReportAt: new Date('2026-05-01'),
    siteCreatedAt: new Date('2026-01-01'),
    siteUpdatedAt: new Date('2026-02-01'),
  });

  it('includes pending title and thumbnail in lite mode for REPORTED sites', async () => {
    const response = await projector.buildResponse({
      query: { lat: 41.6, lng: 21.7, detail: 'lite' } as never,
      rows: [baseRow()],
      usedViewportBbox: true,
    });

    expect(response.data[0]).toMatchObject({
      latestReportTitle: 'Pending title',
      latestReportDescription: null,
      latestReportMediaUrls: ['pending.jpg'],
    });
  });

  it('strips report text in lite mode for VERIFIED sites', async () => {
    const row = baseRow();
    row.status = 'VERIFIED';
    const response = await projector.buildResponse({
      query: { lat: 41.6, lng: 21.7, detail: 'lite' } as never,
      rows: [row],
      usedViewportBbox: true,
    });

    expect(response.data[0]).toMatchObject({
      latestReportTitle: null,
      latestReportDescription: null,
      latestReportMediaUrls: ['pending.jpg'],
    });
  });
});
