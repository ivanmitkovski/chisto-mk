/**
 * CI sets REDIS_URL for E2E/service-container parity. Unit tests must not open real
 * ioredis clients from process.env — use mocks or set REDIS_URL in the test's beforeEach.
 */
beforeEach(() => {
  delete process.env.REDIS_URL;
});
