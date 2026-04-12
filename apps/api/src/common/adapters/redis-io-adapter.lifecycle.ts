import { Injectable, OnApplicationShutdown } from '@nestjs/common';
import { RedisIoAdapter } from './redis-io.adapter';

@Injectable()
export class RedisIoAdapterLifecycle implements OnApplicationShutdown {
  private adapter: RedisIoAdapter | null = null;

  register(adapter: RedisIoAdapter): void {
    this.adapter = adapter;
  }

  async onApplicationShutdown(): Promise<void> {
    await this.adapter?.closeRedis();
    this.adapter = null;
  }
}
