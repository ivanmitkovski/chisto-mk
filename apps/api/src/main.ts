import './observability/otel-sdk.start';
import { Logger as NestLogger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { Logger as PinoNestLogger } from 'nestjs-pino';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import * as Sentry from '@sentry/node';
import compression from 'compression';
import express from 'express';
import helmet from 'helmet';
import { RedisIoAdapter } from './common/adapters/redis-io.adapter';
import { RedisIoAdapterLifecycle } from './common/adapters/redis-io-adapter.lifecycle';
import { EventChatClusterConfig } from './event-chat/event-chat-cluster.config';
import { AppModule } from './app.module';
import { validateEnv } from './config/env';
import { ObservabilityStore } from './observability/observability.store';
import { configureHttpApplication } from './bootstrap/configure-http-app';
import { runWithInboundTraceparent } from './common/logging/http-request-trace';

async function bootstrap() {
  validateEnv();
  if (process.env.NODE_ENV !== 'test') {
    ObservabilityStore.startPushGatewayLoop();
  }
  const sentryDsn = process.env.SENTRY_DSN?.trim();
  if (sentryDsn) {
    Sentry.init({
      dsn: sentryDsn,
      environment: process.env.NODE_ENV ?? 'development',
      release: process.env.SENTRY_RELEASE?.trim() || process.env.npm_package_version,
      tracesSampleRate: Number(process.env.SENTRY_TRACES_SAMPLE_RATE ?? 0.05),
    });
  }
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(PinoNestLogger));

  const bootstrapLog = new NestLogger('Bootstrap');

  const expressApp = app.getHttpAdapter().getInstance() as express.Application;
  // Required so req.ip is derived from trusted proxy headers (ALB / ingress).
  expressApp.set('trust proxy', true);
  expressApp.use((req, _res, next) => {
    const raw = req.headers.traceparent ?? req.headers.Traceparent;
    const traceparent =
      typeof raw === 'string' && raw.trim().length > 0 ? raw.trim() : undefined;
    runWithInboundTraceparent(traceparent, () => next());
  });
  expressApp.use(
    helmet({
      contentSecurityPolicy: {
        useDefaults: true,
        directives: {
          defaultSrc: ["'none'"],
          frameAncestors: ["'none'"],
        },
      },
      crossOriginEmbedderPolicy: false,
    }),
  );
  expressApp.use(express.json({ limit: '1mb' }));
  expressApp.use(express.urlencoded({ extended: true, limit: '1mb' }));

  const redisUrl = process.env.REDIS_URL?.trim();
  if (redisUrl) {
    try {
      const redisIoAdapter = new RedisIoAdapter(app);
      await redisIoAdapter.connectToRedis(redisUrl);
      app.useWebSocketAdapter(redisIoAdapter);
      app.get(EventChatClusterConfig).setSocketIoClustered(true);
      app.get(RedisIoAdapterLifecycle).register(redisIoAdapter);
      bootstrapLog.log('Socket.IO Redis adapter enabled (multi-replica WebSocket fan-out)');
    } catch (err) {
      bootstrapLog.error(
        'REDIS_URL is set but Socket.IO Redis adapter failed; falling back to single-node WebSockets.',
        err instanceof Error ? err.stack : String(err),
      );
      app.useWebSocketAdapter(new IoAdapter(app));
    }
  } else {
    app.useWebSocketAdapter(new IoAdapter(app));
  }
  // Never compress Engine.IO / Socket.IO — breaks polling payloads and causes endless reconnects.
  app.use(
    compression({
      threshold: 1024,
      filter: (req, res) => {
        const path =
          'originalUrl' in req && typeof req.originalUrl === 'string'
            ? req.originalUrl.split('?')[0] ?? ''
            : (req.url ?? '').split('?')[0] ?? '';
        if (path.includes('/socket.io')) {
          return false;
        }
        return compression.filter(req, res);
      },
    }),
  );
  app.enableShutdownHooks();

  const allowedOriginsEnv = process.env.CORS_ORIGINS;
  const allowedOrigins = allowedOriginsEnv
    ? allowedOriginsEnv.split(',').map((origin) => origin.trim()).filter(Boolean)
    : ['http://localhost:3000', 'http://localhost:3001'];

  const allowCredentials = process.env.CORS_ALLOW_CREDENTIALS?.trim() === 'true';

  app.enableCors({
    origin: allowedOrigins,
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'Accept-Language',
      'X-Request-Id',
      'X-Idempotency-Key',
      'X-Client-Version',
      'Sentry-Trace',
      'Baggage',
    ],
    credentials: allowCredentials,
  });

  configureHttpApplication(app);

  const nodeEnv = process.env.NODE_ENV ?? 'development';
  if (nodeEnv !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('Chisto.mk API')
      .setDescription('Civic environmental platform — pollution reporting, site lifecycle, cleanup events')
      .setVersion('0.1.0')
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');

  bootstrapLog.log(`HTTP bound on 0.0.0.0:${port} (all interfaces)`);
  bootstrapLog.log(`Local URLs: http://127.0.0.1:${port} · http://localhost:${port}`);
  if (process.env.NODE_ENV !== 'production') {
    bootstrapLog.log(`OpenAPI: http://localhost:${port}/api/docs`);
  }
}

bootstrap().catch((err) => {
  console.error('Failed to start:', err);
  process.exit(1);
});
