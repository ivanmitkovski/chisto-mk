import { ReportUploadOrphanGcService } from '../../src/reports/report-upload-orphan-gc.service';
import type { PrismaService } from '../../src/prisma/prisma.service';
import type { S3StorageClient } from '../../src/storage/s3-storage.client';
import type { ReportsUploadService } from '../../src/reports/reports-upload.service';

describe('ReportUploadOrphanGcService', () => {
  it('deletes old report media keys not referenced by any report', async () => {
    const old = new Date(Date.now() - 100 * 60 * 60 * 1000);
    const key = 'reports/user-1/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg';
    const canonical = 'https://bucket.s3.eu-central-1.amazonaws.com/' + key;

    const listObjectsByPrefix = jest.fn().mockResolvedValue({
      objects: [{ key, lastModified: old }],
    });
    const s3 = {
      enabled: true,
      getVirtualHostedHttpsBase: () => 'https://bucket.s3.eu-central-1.amazonaws.com/',
      listObjectsByPrefix,
    } as unknown as S3StorageClient;

    const findMany = jest.fn().mockResolvedValue([]);
    const prisma = { report: { findMany } } as unknown as PrismaService;

    const deleteObjectByKey = jest.fn().mockResolvedValue(undefined);
    const reportsUpload = { deleteObjectByKey } as unknown as ReportsUploadService;

    const svc = new ReportUploadOrphanGcService(prisma, s3, reportsUpload);
    await svc.runOnce();

    expect(findMany).toHaveBeenCalledWith({
      where: {
        OR: [{ mediaUrls: { hasSome: [canonical] } }, { mediaUrls: { hasSome: [key] } }],
      },
      select: { mediaUrls: true },
    });
    expect(deleteObjectByKey).toHaveBeenCalledWith(key);
  });

  it('skips delete when a report still references the canonical URL', async () => {
    const old = new Date(Date.now() - 100 * 60 * 60 * 1000);
    const key = 'reports/user-1/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.jpg';
    const canonical = 'https://bucket.s3.eu-central-1.amazonaws.com/' + key;

    const s3 = {
      enabled: true,
      getVirtualHostedHttpsBase: () => 'https://bucket.s3.eu-central-1.amazonaws.com/',
      listObjectsByPrefix: jest.fn().mockResolvedValue({
        objects: [{ key, lastModified: old }],
      }),
    } as unknown as S3StorageClient;

    const findMany = jest.fn().mockResolvedValue([{ mediaUrls: [canonical] }]);
    const prisma = { report: { findMany } } as unknown as PrismaService;

    const deleteObjectByKey = jest.fn();
    const reportsUpload = { deleteObjectByKey } as unknown as ReportsUploadService;

    const svc = new ReportUploadOrphanGcService(prisma, s3, reportsUpload);
    await svc.runOnce();

    expect(deleteObjectByKey).not.toHaveBeenCalled();
  });
});
