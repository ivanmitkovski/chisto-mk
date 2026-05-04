import { BadRequestException, Logger as NestLogger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { Logger as PinoNestLogger } from 'nestjs-pino';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import compression from 'compression';
import express from 'express';
import { RedisIoAdapter } from './common/adapters/redis-io.adapter';
import { RedisIoAdapterLifecycle } from './common/adapters/redis-io-adapter.lifecycle';
import { EventChatClusterConfig } from './event-chat/event-chat-cluster.config';
import { AppModule } from './app.module';
import { validateEnv } from './config/env';
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';
import { RequestLoggingInterceptor } from './common/interceptors/request-logging.interceptor';

async function bootstrap() {
  validateEnv();
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(PinoNestLogger));

  const bootstrapLog = new NestLogger('Bootstrap');

  const expressApp = app.getHttpAdapter().getInstance() as express.Application;
  // Required so req.ip is derived from trusted proxy headers (ALB / ingress).
  expressApp.set('trust proxy', true);
  expressApp.use(express.urlencoded({ extended: true }));

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
      console.error(
        'REDIS_URL is set but Socket.IO Redis adapter failed; falling back to single-node WebSockets. Error:',
        err,
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

  app.enableCors({
    origin: allowedOrigins,
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: false,
  });

  // SECURITY: forbidNonWhitelisted rejects mass-assignment of unknown DTO properties at the edge.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
      exceptionFactory: (validationErrors) =>
        new BadRequestException({
          code: 'VALIDATION_ERROR',
          message: 'Request validation failed',
          details: validationErrors.map((error) => ({
            field: error.property,
            errors: error.constraints ? Object.values(error.constraints) : [],
          })),
        }),
    }),
  );
  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalInterceptors(new RequestLoggingInterceptor());

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
