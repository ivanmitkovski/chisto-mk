import { INestApplicationContext } from '@nestjs/common';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';
import { ServerOptions } from 'socket.io';

type RedisQuitClient = { quit(): Promise<unknown> };

/**
 * Socket.IO over Redis so `server.to(room).emit` reaches clients on every API replica
 * (ECS tasks / K8s pods). Without this, WebSockets only hit sockets on the same process
 * that handled the HTTP mutation.
 */
export class RedisIoAdapter extends IoAdapter {
  private adapterConstructor: ReturnType<typeof createAdapter> | null = null;
  private pubClient: RedisQuitClient | null = null;
  private subClient: RedisQuitClient | null = null;

  constructor(app: INestApplicationContext) {
    super(app);
  }

  async connectToRedis(redisUrl: string): Promise<void> {
    const trimmed = redisUrl.trim();
    const useTls =
      trimmed.startsWith('rediss://') ||
      process.env.REDIS_TLS === '1' ||
      process.env.REDIS_TLS?.toLowerCase() === 'true';
    const rejectUnauthorized = process.env.REDIS_TLS_REJECT_UNAUTHORIZED !== '0';
    const pubClient = createClient({
      url: trimmed,
      ...(useTls
        ? {
            socket: {
              tls: true,
              rejectUnauthorized,
            },
          }
        : {}),
    });
    const subClient = pubClient.duplicate();
    this.pubClient = pubClient as RedisQuitClient;
    this.subClient = subClient as RedisQuitClient;
    await Promise.all([pubClient.connect(), subClient.connect()]);
    this.adapterConstructor = createAdapter(pubClient, subClient);
  }

  createIOServer(port: number, options?: ServerOptions) {
    const server = super.createIOServer(port, options);
    if (this.adapterConstructor) {
      server.adapter(this.adapterConstructor);
    }
    return server;
  }

  async closeRedis(): Promise<void> {
    await Promise.all([
      this.pubClient?.quit().catch(() => undefined),
      this.subClient?.quit().catch(() => undefined),
    ]);
    this.pubClient = null;
    this.subClient = null;
    this.adapterConstructor = null;
  }
}
