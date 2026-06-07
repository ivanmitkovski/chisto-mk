/// <reference types="jest" />
import { OperationsStatusService } from '../../src/admin-control/services/operations-status.service';
import { FcmPushService } from '../../src/notifications/services/fcm-push.service';
import { PrismaService } from '../../src/prisma/prisma.service';
import { S3StorageClient } from '../../src/storage/util/s3-storage.client';

describe('OperationsStatusService', () => {
  const fcmPush = { isEnabled: jest.fn().mockReturnValue(true) } as unknown as FcmPushService;
  const prisma = {
    $queryRaw: jest.fn().mockResolvedValue([{ '?column?': 1 }]),
  } as unknown as PrismaService;
  const s3 = {
    enabled: false,
    bucket: null,
    getClientOrNull: jest.fn().mockReturnValue(null),
  } as unknown as S3StorageClient;

  it('returns system info with uptime and fcm flag', () => {
    const service = new OperationsStatusService(fcmPush, prisma, s3);
    const info = service.getSystemInfo();
    expect(info.fcmEnabled).toBe(true);
    expect(info.uptimeSeconds).toBeGreaterThanOrEqual(0);
    expect(info.version).toBeTruthy();
  });

  it('returns metrics snapshot with process memory', () => {
    const service = new OperationsStatusService(fcmPush, prisma, s3);
    const snapshot = service.getMetricsSnapshot();
    expect(snapshot.processMemory.rssMb).toBeGreaterThan(0);
    expect(snapshot.capturedAt).toBeTruthy();
  });
});
