import { INestApplication } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { AppModule } from '../../../src/app.module';
import { configureHttpApplication } from '../../../src/bootstrap/configure-http-app';
import { validateEnv } from '../../../src/config/env';
import { PrismaService } from '../../../src/prisma/prisma.service';
import { RedisIoAdapter } from '../../../src/common/adapters/redis-io.adapter';
import { RedisIoAdapterLifecycle } from '../../../src/common/adapters/redis-io-adapter.lifecycle';
import { EventChatClusterConfig } from '../../../src/event-chat/constants/event-chat-cluster.config';

export async function createE2eApplication(): Promise<{
  app: INestApplication;
  prisma: PrismaService;
}> {
  validateEnv();
  const app = await NestFactory.create(AppModule, { logger: false, bufferLogs: true });
  app.setGlobalPrefix('v1', {
    exclude: [
      'health',
      'health/(.*)',
      'metrics',
      'api/docs',
      'api/docs-json',
      'api/docs/(.*)',
    ],
  });
  configureHttpApplication(app);
  await app.init();

  const redisUrl = process.env.REDIS_URL?.trim();
  if (redisUrl) {
    try {
      const redisIoAdapter = new RedisIoAdapter(app);
      await redisIoAdapter.connectToRedis(redisUrl);
      app.useWebSocketAdapter(redisIoAdapter);
      app.get(EventChatClusterConfig).setSocketIoClustered(true);
      app.get(RedisIoAdapterLifecycle).register(redisIoAdapter);
    } catch {
      app.useWebSocketAdapter(new IoAdapter(app));
    }
  }

  const prisma = app.get(PrismaService);
  return { app, prisma };
}
