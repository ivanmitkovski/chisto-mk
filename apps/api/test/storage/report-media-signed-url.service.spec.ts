/// <reference types="jest" />

import { presignedUrlExpiresAtMs } from '../../src/storage/services/report-media-signed-url.service';

describe('presignedUrlExpiresAtMs', () => {
  it('parses X-Amz-Date and X-Amz-Expires', () => {
    const url =
      'https://bucket.s3.eu-central-1.amazonaws.com/key.jpg?X-Amz-Date=20260521T141032Z&X-Amz-Expires=300';
    expect(presignedUrlExpiresAtMs(url)).toBe(Date.UTC(2026, 4, 21, 14, 15, 32));
  });

  it('returns null for invalid URLs', () => {
    expect(presignedUrlExpiresAtMs('not-a-url')).toBeNull();
    expect(presignedUrlExpiresAtMs('https://x.com/no-sig')).toBeNull();
  });
});
