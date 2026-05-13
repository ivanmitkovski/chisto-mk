import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ImageContentValidator } from './image-content-validator';
import { MediaAssetService } from './media-asset.service';
import { ReportMediaSignedUrlService } from './report-media-signed-url.service';
import { S3StorageClient } from './s3-storage.client';

/** Global so S3 client + signed URL cache are singletons across feature modules. */
@Global()
@Module({
  imports: [ConfigModule],
  providers: [S3StorageClient, ImageContentValidator, MediaAssetService, ReportMediaSignedUrlService],
  exports: [S3StorageClient, ImageContentValidator, MediaAssetService, ReportMediaSignedUrlService],
})
export class StorageModule {}
