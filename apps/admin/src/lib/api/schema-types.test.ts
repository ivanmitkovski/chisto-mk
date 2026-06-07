import { describe, expect, it } from 'vitest';
import type { Schema } from './schema-types';

describe('schema-types', () => {
  it('resolves AdminOverviewResponseDto from generated schema', () => {
    type Overview = Schema<'AdminOverviewResponseDto'>;
    const sample: Pick<Overview, 'usersCount'> = { usersCount: 1 };
    expect(sample.usersCount).toBe(1);
  });
});
