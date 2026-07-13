/// <reference types="jest" />

import { SitesDetailController } from '../../src/sites/controllers/sites-detail.controller';
import type { SitesShareCardQueryService } from '../../src/sites/services/sites-share-card-query.service';
import type { Response } from 'express';

describe('SitesDetailController share media redirects', () => {
  it('sets Cross-Origin-Resource-Policy on share-media redirect', async () => {
    const shareCard = {
      getShareMediaSignedUrl: jest.fn().mockResolvedValue('https://s3.example/signed'),
      getMediaRedirectMaxAgeSeconds: jest.fn().mockReturnValue(120),
    } as unknown as SitesShareCardQueryService;
    const controller = new SitesDetailController(
      {} as never,
      {} as never,
      {} as never,
      {} as never,
      {} as never,
      shareCard,
    );

    const headers: Record<string, string> = {};
    const res = {
      setHeader: jest.fn((key: string, value: string) => {
        headers[key] = value;
      }),
      redirect: jest.fn(),
    } as unknown as Response;

    await controller.redirectShareMedia('site1', 0, res);

    expect(shareCard.getShareMediaSignedUrl).toHaveBeenCalledWith('site1', 0);
    expect(headers['Cross-Origin-Resource-Policy']).toBe('cross-origin');
    expect(headers['Cache-Control']).toBe('public, max-age=120, stale-while-revalidate=60');
    expect(res.redirect).toHaveBeenCalledWith(302, 'https://s3.example/signed');
  });
});
