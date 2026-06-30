/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { createE2eAdminAccessToken } from './helpers/admin-access-token';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import type { PrismaService } from '../../src/prisma/prisma.service';

describe('Admin news create (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await prisma.newsPost.deleteMany({
      where: { slug: { startsWith: 'e2e-news-create-' } },
    });
    await deleteUsersByEmailPrefix(prisma, 'e2e_news_create_');
    await deleteUsersByEmailPrefix(prisma, 'e2e_admin');
    await app.close();
  });

  it('POST /admin/news/posts creates a draft from a minimal payload', async () => {
    const admin = await createE2eAdminAccessToken(prisma, { emailPrefix: 'e2e_news_create_admin' });

    const res = await request(app.getHttpServer())
      .post('/v1/admin/news/posts')
      .set('Authorization', `Bearer ${admin.token}`)
      .set('X-Idempotency-Key', `e2e-news-create-${Date.now()}`)
      .send({
        category: 'release',
        translations: {
          en: {
            title: 'E2E create',
            excerpt: 'E2E create',
            body: [{ type: 'paragraph', text: 'E2E create' }],
          },
          mk: {
            title: 'E2E create',
            excerpt: 'E2E create',
            body: [{ type: 'paragraph', text: 'E2E create' }],
          },
          sq: {
            title: 'E2E create',
            excerpt: 'E2E create',
            body: [{ type: 'paragraph', text: 'E2E create' }],
          },
        },
      })
      .expect(201);

    expect(res.body.slug).toBe('e2e-create');
    expect(res.body.status).toBe('draft');
    expect(res.body.translations.en.title).toBe('E2E create');
  });

  it('rejects admin form fields that are not part of CreateNewsPostDto', async () => {
    const admin = await createE2eAdminAccessToken(prisma, { emailPrefix: 'e2e_news_create_admin' });

    const res = await request(app.getHttpServer())
      .post('/v1/admin/news/posts')
      .set('Authorization', `Bearer ${admin.token}`)
      .set('X-Idempotency-Key', `e2e-news-create-invalid-${Date.now()}`)
      .send({
        slug: '',
        category: 'release',
        scheduledAt: '',
        featured: false,
        translations: {
          en: { title: 'test', excerpt: 'test', body: [{ type: 'paragraph', text: 'test' }] },
          mk: { title: 'test', excerpt: 'test', body: [{ type: 'paragraph', text: 'test' }] },
          sq: { title: 'test', excerpt: 'test', body: [{ type: 'paragraph', text: 'test' }] },
        },
      })
      .expect(400);

    expect(res.body.code).toBe('VALIDATION_ERROR');
  });
});
