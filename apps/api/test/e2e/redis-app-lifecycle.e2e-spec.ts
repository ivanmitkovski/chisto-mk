/// <reference types="jest" />

import request from 'supertest';
import { createE2eApplication } from './helpers/bootstrap-app';
import { uniquePhone } from './helpers/auth-helper';

describe('Redis app lifecycle (e2e)', () => {
  it('second Nest app can use throttled routes after the first app closes', async () => {
    const { app: app1 } = await createE2eApplication();
    await request(app1.getHttpServer()).get('/health/ready').expect((res) => {
      expect([200, 503]).toContain(res.status);
    });
    await request(app1.getHttpServer())
      .post('/v1/auth/register')
      .send({
        firstName: 'E2e',
        lastName: 'Lifecycle1',
        email: `e2e_redis_lifecycle_1_${Date.now()}@test.local`,
        phoneNumber: uniquePhone(),
        password: 'E2eLifecycle99!',
        termsAcceptedAt: new Date().toISOString(),
        termsVersion: '1',
      })
      .expect((res) => {
        expect([200, 201, 400, 409, 429]).toContain(res.status);
      });
    await app1.close();

    const { app: app2 } = await createE2eApplication();
    await request(app2.getHttpServer()).get('/health/ready').expect((res) => {
      expect([200, 503]).toContain(res.status);
    });
    await request(app2.getHttpServer())
      .post('/v1/auth/register')
      .send({
        firstName: 'E2e',
        lastName: 'Lifecycle2',
        email: `e2e_redis_lifecycle_2_${Date.now()}@test.local`,
        phoneNumber: uniquePhone(),
        password: 'E2eLifecycle99!',
        termsAcceptedAt: new Date().toISOString(),
        termsVersion: '1',
      })
      .expect((res) => {
        expect([200, 201, 400, 409, 429]).toContain(res.status);
      });
    await app2.close();
  });
});
