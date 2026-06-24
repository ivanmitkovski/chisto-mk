import { describe, expect, it } from 'vitest';
import { ApiError } from '@/lib/api/api';
import { newsApiErrorKey, newsApiErrorMessage } from './news-api-messages';

describe('news-api-messages', () => {
  it('maps known API codes', () => {
    const err = new ApiError(400, 'NEWS_SLUG_TAKEN', 'taken');
    expect(newsApiErrorKey(err)).toBe('apiErrors.slugTaken');
  });

  it('falls back for unknown errors', () => {
    expect(newsApiErrorMessage(new Error('boom'), () => 'mapped', 'fallback')).toBe('boom');
    expect(newsApiErrorMessage({}, () => 'mapped', 'fallback')).toBe('fallback');
  });
});
