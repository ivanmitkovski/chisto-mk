/// <reference types="jest" />

import { OperationsDiagnosticsBundleService } from '../../src/admin-control/services/operations-diagnostics-bundle.service';

describe('OperationsDiagnosticsBundleService', () => {
  const operationsStatus = {
    getSystemInfo: jest.fn().mockReturnValue({ fcmEnabled: true, fcmReady: true }),
    getReadiness: jest.fn().mockResolvedValue({ status: 'ok', checks: [] }),
    getWorkers: jest.fn().mockReturnValue({ workers: [] }),
    getMetricsSnapshot: jest.fn().mockReturnValue({ capturedAt: '2026-01-01T00:00:00.000Z' }),
  };

  const pushDiagnostics = {
    getDiagnostics: jest.fn().mockResolvedValue({ fcmEnabled: true, fcmReady: true }),
  };

  const pushHealth = {
    getHealthSnapshot: jest.fn().mockResolvedValue({ status: 'ok', alerts: [] }),
  };

  const emailHealth = {
    getHealthSnapshot: jest.fn().mockResolvedValue({ status: 'ok', alerts: [] }),
  };

  const prisma = {
    auditLog: {
      count: jest.fn().mockResolvedValue(2),
    },
  };

  const service = new OperationsDiagnosticsBundleService(
    operationsStatus as never,
    pushDiagnostics as never,
    pushHealth as never,
    emailHealth as never,
    prisma as never,
  );

  it('aggregates diagnostics bundle sections', async () => {
    const bundle = await service.getBundle();
    expect(bundle.systemInfo.fcmEnabled).toBe(true);
    expect(bundle.pushDiagnostics.fcmReady).toBe(true);
    expect(bundle.pushHealth.status).toBe('ok');
    expect(bundle.emailHealth.status).toBe('ok');
    expect(bundle.feedDiagnostics.recentIntegrityDemotions).toBe(2);
    expect(bundle.metrics.capturedAt).toBeTruthy();
    expect(bundle.capturedAt).toBeTruthy();
  });
});
