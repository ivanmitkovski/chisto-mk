/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { deleteUsersByEmailPrefix } from './helpers/db-cleanup';
import { registerCitizen } from './helpers/auth-helper';
import { PrismaService } from '../../src/prisma/prisma.service';

describe('Reports submit (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
    prisma = ctx.prisma;
  });

  afterAll(async () => {
    await deleteUsersByEmailPrefix(prisma, 'e2e_report_');
    await app.close();
  });

  it('creates a report with location when authenticated', async () => {
    const u = await registerCitizen(app, 'report');
    const res = await request(app.getHttpServer())
      .post('/reports')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .send({
        latitude: 41.9981,
        longitude: 21.4254,
        title: `E2E report ${Date.now()}`,
        category: 'OTHER',
      });
    expect([200, 201]).toContain(res.status);
    expect(res.body.reportId).toBeDefined();
  });

  it('replays same report when Idempotency-Key is reused', async () => {
    const u = await registerCitizen(app, 'report_idem');
    const idemKey = `e2e_idem_${Date.now()}_${'x'.repeat(20)}`;
    const server = app.getHttpServer();
    const body = {
      latitude: 42.001,
      longitude: 21.43,
      title: `E2E idem ${Date.now()}`,
      category: 'OTHER' as const,
    };
    const first = await request(server)
      .post('/reports')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .set('idempotency-key', idemKey)
      .send(body);
    expect([200, 201]).toContain(first.status);
    const reportId = first.body.reportId as string;
    expect(reportId).toBeDefined();

    const second = await request(server)
      .post('/reports')
      .set('Authorization', `Bearer ${u.accessToken}`)
      .set('idempotency-key', idemKey)
      .send({ ...body, title: 'different title should not create new report' });
    expect([200, 201]).toContain(second.status);
    expect(second.body.reportId).toBe(reportId);
  });
});
