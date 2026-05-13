import type { Logger } from '@nestjs/common';
import { Client } from 'pg';
import { resolveDatabaseUrl } from '../../prisma/resolve-database-url';
import { isPgOutboxListenEnabled } from './outbox-pg-notify';

export type StartPgOutboxListenerArgs = {
  /** Must be a fixed identifier from `outbox-pg-notify.ts` (never user input). */
  channel: string;
  logger: Pick<Logger, 'log' | 'warn'>;
  onNotify: () => void;
};

/**
 * Dedicated `pg` client for LISTEN (Prisma pool must not hold long-lived listeners).
 * Returns null when disabled or connection fails (callers keep polling).
 */
export async function startPgOutboxListener(
  args: StartPgOutboxListenerArgs,
): Promise<Client | null> {
  if (!isPgOutboxListenEnabled()) {
    return null;
  }
  if (!/^[a-z][a-z0-9_]*$/.test(args.channel)) {
    args.logger.warn(`PG outbox LISTEN rejected invalid channel: ${args.channel}`);
    return null;
  }
  const url = process.env.DATABASE_URL?.trim();
  if (!url) {
    args.logger.warn('PG outbox LISTEN skipped: DATABASE_URL empty');
    return null;
  }

  const client = new Client({ connectionString: resolveDatabaseUrl(url) });
  try {
    await client.connect();
    await client.query(`LISTEN ${args.channel}`);
    client.on('notification', () => {
      args.onNotify();
    });
    client.on('error', (err: Error) => {
      args.logger.warn(`PG LISTEN client error on ${args.channel}: ${err.message}`);
    });
    args.logger.log(`LISTEN ${args.channel}`);
    return client;
  } catch (err) {
    args.logger.warn(`PG LISTEN failed for ${args.channel}; falling back to poll only`, err);
    try {
      await client.end();
    } catch {
      /* ignore */
    }
    return null;
  }
}

export async function endPgOutboxListener(client: Client | null | undefined): Promise<void> {
  if (client == null) return;
  try {
    client.removeAllListeners('notification');
    client.removeAllListeners('error');
    await client.end();
  } catch {
    /* ignore */
  }
}
