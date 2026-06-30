import { describe, expect, it } from 'vitest';
import { describeClientRejection } from './normalize-client-rejection';

describe('normalize-client-rejection', () => {
  it('describes Error instances', () => {
    expect(describeClientRejection(new Error('boom'))).toBe('boom');
  });

  it('describes string rejections', () => {
    expect(describeClientRejection('network down')).toBe('network down');
  });
});
