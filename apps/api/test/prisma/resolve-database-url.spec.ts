/// <reference types="jest" />

import { resolveDatabaseUrl } from '../../src/prisma/resolve-database-url';

describe('resolveDatabaseUrl', () => {
  it('disables ssl for local postgres hosts', () => {
    const url = resolveDatabaseUrl('postgresql://u:p@localhost:5432/chisto');
    expect(url).toContain('sslmode=disable');
    expect(url).toContain('connect_timeout=30');
  });

  it('uses no-verify ssl for remote hosts in production', () => {
    const url = resolveDatabaseUrl(
      'postgresql://u:p@chisto-prod.cfs2eqk4qbnk.eu-central-1.rds.amazonaws.com:5432/chisto_prod?sslmode=require',
    );
    expect(url).toContain('sslmode=no-verify');
    expect(url).not.toContain('sslmode=require');
    expect(url).toContain('connect_timeout=30');
  });

  it('uses no-verify ssl for remote hosts in development', () => {
    const url = resolveDatabaseUrl(
      'postgresql://u:p@db.example.com:5432/chisto?sslmode=require',
    );
    expect(url).toContain('sslmode=no-verify');
  });
});
