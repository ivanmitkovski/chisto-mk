/// <reference types="jest" />

import { ConfigService } from '@nestjs/config';
import { EventChatUploadService } from '../../src/event-chat/event-chat-upload.service';
import type { PrismaService } from '../../src/prisma/prisma.service';

describe('EventChatUploadService', () => {
  function buildService(bucket: string | null, region = 'eu-central-1'): EventChatUploadService {
    const config = {
      get: (key: string): string | undefined => {
        if (key === 'S3_BUCKET_NAME') {
          return bucket ?? undefined;
        }
        if (key === 'AWS_REGION') {
          return region;
        }
        return undefined;
      },
    } as unknown as ConfigService;
    const svc = new EventChatUploadService(config, {} as PrismaService);
    svc.onModuleInit();
    return svc;
  }

  it('isTrustedChatPublishedUrl accepts only this bucket chat/ keys', () => {
    const s = buildService('mybucket', 'eu-central-1');
    expect(
      s.isTrustedChatPublishedUrl('https://mybucket.s3.eu-central-1.amazonaws.com/chat/a/b.jpg'),
    ).toBe(true);
    expect(s.isTrustedChatPublishedUrl('https://other.s3.eu-central-1.amazonaws.com/chat/a')).toBe(false);
    expect(
      s.isTrustedChatPublishedUrl('https://mybucket.s3.eu-central-1.amazonaws.com/reports/x'),
    ).toBe(false);
  });

  it('isTrustedChatPublishedUrl is false when S3 is not configured', () => {
    const s = buildService(null);
    expect(s.isTrustedChatPublishedUrl('https://any.s3.eu-central-1.amazonaws.com/chat/x')).toBe(false);
  });
});
