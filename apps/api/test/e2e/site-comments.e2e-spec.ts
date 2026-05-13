/// <reference types="jest" />

import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';

describe('Site comments (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const ctx = await createE2eApplication();
    app = ctx.app;
  });

  afterAll(async () => {
    await app.close();
  });

  it('rejects unauthenticated comment creation', async () => {
    const res = await request(app.getHttpServer())
      .post('/sites/c123456789012345678901234/comments')
      .send({ body: 'Hello', parentId: null })
      .expect(401);
    expect(res.body.code).toBeDefined();
  });
});
