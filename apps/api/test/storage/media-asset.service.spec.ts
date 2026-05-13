/// <reference types="jest" />

import { ServiceUnavailableException } from '@nestjs/common';
import { MediaAssetService } from '../../src/storage/media-asset.service';
import type { S3StorageClient } from '../../src/storage/s3-storage.client';

describe('MediaAssetService', () => {
  it('rejects presigned PUT when S3 is disabled', async () => {
    const s3 = {
      enabled: false,
      bucket: null,
      getClientOrNull: () => null,
    } as unknown as S3StorageClient;
    const svc = new MediaAssetService(s3);
    await expect(
      svc.createPresignedPutUrl({ key: 'reports/x.jpg', contentType: 'image/jpeg' }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
