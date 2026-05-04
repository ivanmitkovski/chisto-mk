import { Global, Module } from '@nestjs/common';
import { ImageContentValidator } from './image-content-validator';
import { ReportMediaSignedUrlService } from './report-media-signed-url.service';
import { S3StorageClient } from './s3-storage.client';

/** Global so S3 client + signed URL cache are singletons across feature modules. */
@Global()
@Module({
  providers: [S3StorageClient, ImageContentValidator, ReportMediaSignedUrlService],
  exports: [S3StorageClient, ImageContentValidator, ReportMediaSignedUrlService],
})
export class StorageModule {}
