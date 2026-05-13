/// <reference types="jest" />
import { BadRequestException, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ReportsUploadService } from '../../src/reports/reports-upload.service';
import { ImageContentValidator } from '../../src/storage/image-content-validator';
import { ReportMediaSignedUrlService } from '../../src/storage/report-media-signed-url.service';
import { S3StorageClient } from '../../src/storage/s3-storage.client';

describe('ReportsUploadService.assertReportMediaUrlsFromOurBucket', () => {
  function makeService(bucket: string | null) {
    const config = {
      get: (k: string) => {
        if (k === 'S3_BUCKET_NAME') return bucket;
        if (k === 'AWS_REGION') return 'eu-central-1';
        return undefined;
      },
    } as unknown as ConfigService;
    const s3 = new S3StorageClient(config);
    s3.onModuleInit();
    const validator = {} as ImageContentValidator;
    const signed = {} as ReportMediaSignedUrlService;
    const avatar = {} as never;
    return new ReportsUploadService(s3, validator, signed, avatar);
  }

  it('allows URLs under configured virtual-hosted base', () => {
    const svc = makeService('my-bucket');
    svc.assertReportMediaUrlsFromOurBucket([
      'https://my-bucket.s3.eu-central-1.amazonaws.com/reports/u1/a.jpg',
    ]);
  });

  it('rejects foreign hosts', () => {
    const svc = makeService('my-bucket');
    expect(() =>
      svc.assertReportMediaUrlsFromOurBucket(['https://evil.example.com/x.jpg']),
    ).toThrow(BadRequestException);
  });

  it('throws when S3 disabled but URLs provided', () => {
    const svc = makeService(null);
    expect(() => svc.assertReportMediaUrlsFromOurBucket(['https://x.com/a'])).toThrow(
      ServiceUnavailableException,
    );
  });
});
