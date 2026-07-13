/// <reference types="jest" />

import { PublicNewsController } from '../../src/news/controllers/public-news.controller';
import type { NewsPostsQueryService } from '../../src/news/services/news-posts-query.service';
import type { Response } from 'express';

describe('PublicNewsController.mediaRedirect', () => {
  it('sets Cross-Origin-Resource-Policy so landing can embed the redirect', async () => {
    const query = {
      getPublishedMediaSignedUrl: jest.fn().mockResolvedValue('https://s3.example/signed'),
      getMediaRedirectMaxAgeSeconds: jest.fn().mockReturnValue(120),
    } as unknown as NewsPostsQueryService;
    const controller = new PublicNewsController(query);

    const headers: Record<string, string> = {};
    const res = {
      setHeader: jest.fn((key: string, value: string) => {
        headers[key] = value;
      }),
      redirect: jest.fn(),
    } as unknown as Response;

    await controller.mediaRedirect('media-1', res);

    expect(query.getPublishedMediaSignedUrl).toHaveBeenCalledWith('media-1');
    expect(headers['Cross-Origin-Resource-Policy']).toBe('cross-origin');
    expect(headers['Cache-Control']).toBe('public, max-age=120, stale-while-revalidate=60');
    expect(res.redirect).toHaveBeenCalledWith(302, 'https://s3.example/signed');
  });
});
