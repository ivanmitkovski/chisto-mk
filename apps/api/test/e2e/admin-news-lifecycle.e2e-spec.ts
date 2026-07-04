/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { createE2eAdminAccessToken } from './helpers/admin-access-token';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import type { PrismaService } from '../../src/prisma/prisma.service';

const localeContent = (title: string) => ({
  title,
  excerpt: `${title} excerpt`,
  body: [{ type: 'paragraph', text: `${title} body` }],
});

const translations = (title: string) => ({
  en: localeContent(title),
  mk: localeContent(title),
  sq: localeContent(title),
});

describe('Admin news lifecycle (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const slugPrefix = 'e2e-news-lifecycle-';

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await prisma.newsPost.deleteMany({
      where: { slug: { startsWith: slugPrefix } },
    });
    await deleteUsersByEmailPrefix(prisma, 'e2e_news_lifecycle_');
    await deleteUsersByEmailPrefix(prisma, 'e2e_admin');
    await app.close();
  });

  it('create → publish → update-publish → unpublish', async () => {
    const admin = await createE2eAdminAccessToken(prisma, {
      emailPrefix: 'e2e_news_lifecycle_admin',
    });
    const slug = `${slugPrefix}${Date.now()}`;

    const createRes = await request(app.getHttpServer())
      .post('/v1/admin/news/posts')
      .set('Authorization', `Bearer ${admin.token}`)
      .set('X-Idempotency-Key', `e2e-news-lifecycle-create-${Date.now()}`)
      .send({
        slug,
        category: 'release',
        translations: translations('Lifecycle'),
      })
      .expect(201);

    const postId = createRes.body.id as string;
    expect(createRes.body.status).toBe('draft');

    const media = await prisma.newsMedia.create({
      data: {
        postId,
        kind: 'COVER',
        objectKey: `news/${postId}/cover/e2e-cover.jpg`,
        mimeType: 'image/jpeg',
        fileName: 'cover.jpg',
        sizeBytes: 1024,
        width: 1200,
        height: 630,
        sortOrder: 0,
        altText: { en: 'Cover', mk: 'Cover', sq: 'Cover' },
      },
    });
    await prisma.newsPost.update({
      where: { id: postId },
      data: { coverMediaId: media.id },
    });

    const publishRes = await request(app.getHttpServer())
      .post(`/v1/admin/news/posts/${postId}/publish`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(201);

    expect(publishRes.body.status).toBe('published');
    expect(publishRes.body.publishedAt).toBeTruthy();
    const publishedAt = publishRes.body.publishedAt as string;

    const publicBefore = await request(app.getHttpServer())
      .get(`/v1/news/posts/${slug}`)
      .query({ locale: 'en' })
      .expect(200);
    expect(publicBefore.body.title).toBe('Lifecycle');

    const updatedAt = publishRes.body.updatedAt as string;
    const patchRes = await request(app.getHttpServer())
      .patch(`/v1/admin/news/posts/${postId}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({
        expectedUpdatedAt: updatedAt,
        translations: translations('Lifecycle updated'),
      })
      .expect(200);

    expect(patchRes.body.translations.en.title).toBe('Lifecycle updated');
    expect(patchRes.body.status).toBe('published');

    const updatePublishRes = await request(app.getHttpServer())
      .post(`/v1/admin/news/posts/${postId}/publish`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(201);

    expect(updatePublishRes.body.status).toBe('published');
    expect(updatePublishRes.body.publishedAt).toBe(publishedAt);
    expect(updatePublishRes.body.translations.en.title).toBe('Lifecycle updated');

    const publicAfter = await request(app.getHttpServer())
      .get(`/v1/news/posts/${slug}`)
      .query({ locale: 'en' })
      .expect(200);
    expect(publicAfter.body.title).toBe('Lifecycle updated');

    await request(app.getHttpServer())
      .post(`/v1/admin/news/posts/${postId}/unpublish`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(201);

    await request(app.getHttpServer())
      .get(`/v1/news/posts/${slug}`)
      .query({ locale: 'en' })
      .expect(404);
  });

  it('rejects publish and update on archived posts', async () => {
    const admin = await createE2eAdminAccessToken(prisma, {
      emailPrefix: 'e2e_news_lifecycle_admin',
    });
    const slug = `${slugPrefix}archived-${Date.now()}`;

    const createRes = await request(app.getHttpServer())
      .post('/v1/admin/news/posts')
      .set('Authorization', `Bearer ${admin.token}`)
      .set('X-Idempotency-Key', `e2e-news-lifecycle-archived-${Date.now()}`)
      .send({
        slug,
        category: 'release',
        translations: translations('Archived'),
      })
      .expect(201);

    const postId = createRes.body.id as string;

    await request(app.getHttpServer())
      .post(`/v1/admin/news/posts/${postId}/archive`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(201);

    await request(app.getHttpServer())
      .post(`/v1/admin/news/posts/${postId}/publish`)
      .set('Authorization', `Bearer ${admin.token}`)
      .expect(400);

    await request(app.getHttpServer())
      .patch(`/v1/admin/news/posts/${postId}`)
      .set('Authorization', `Bearer ${admin.token}`)
      .send({ featured: true })
      .expect(400);
  });
});
