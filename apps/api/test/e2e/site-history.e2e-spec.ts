/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { PrismaService } from '../../src/prisma/prisma.service';
import { createE2eApplication } from './helpers/bootstrap-app';
import { registerCitizen } from './helpers/auth-helper';

describe('Site history (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = app.get(PrismaService);
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns history entries for a site after report submit', async () => {
    const citizen = await registerCitizen(app, 'site_history');
    const agent = request(app.getHttpServer());

    const submit = await agent
      .post('/reports')
      .set('Authorization', `Bearer ${citizen.accessToken}`)
      .send({
        latitude: 41.9981,
        longitude: 21.4254,
        title: 'E2E history site',
        description: 'History timeline test',
        mediaUrls: [],
      });
    expect([200, 201]).toContain(submit.status);
    const siteId = submit.body.siteId as string;
    expect(siteId).toBeDefined();

    const history = await agent
      .get(`/sites/${siteId}/history`)
      .set('Authorization', `Bearer ${citizen.accessToken}`)
      .expect(200);

    expect(Array.isArray(history.body.items)).toBe(true);
    expect(history.body.items.length).toBeGreaterThanOrEqual(2);
    const kinds = history.body.items.map((e: { kind: string }) => e.kind);
    expect(kinds).toContain('SITE_CREATED');
    expect(kinds).toContain('REPORT_SUBMITTED');

    const count = await prisma.siteHistoryEntry.count({ where: { siteId } });
    expect(count).toBeGreaterThanOrEqual(2);
  });
});
