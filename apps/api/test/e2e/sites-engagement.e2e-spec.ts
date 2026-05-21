/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { apiPath } from './helpers/api-path';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('Sites engagement (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await app.close();
  });

  it('upvotes and saves a site', async () => {
    const u = await registerCitizen(app, 'site_engage');
    const site = await prisma.site.create({
      data: { latitude: 41.99, longitude: 21.43, description: 'e2e engagement site' },
    });
    const agent = request(app.getHttpServer()).set('Authorization', `Bearer ${u.accessToken}`);

    await agent
      .post(apiPath(`/sites/${site.id}/upvote`))
      .set('X-Idempotency-Key', `upvote-${site.id}-${Date.now()}`)
      .expect(200);

    await agent
      .post(apiPath(`/sites/${site.id}/save`))
      .set('X-Idempotency-Key', `save-${site.id}-${Date.now()}`)
      .expect(200);
  });
});
