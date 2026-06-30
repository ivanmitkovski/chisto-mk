import { BadRequestException, INestApplication, ValidationPipe } from '@nestjs/common';
import express, { json, type Request } from 'express';
import { GlobalExceptionFilter } from '../common/filters/global-exception.filter';
import { RequestLoggingInterceptor } from '../common/interceptors/request-logging.interceptor';

/**
 * Global HTTP edge configuration shared by production `main.ts` and e2e bootstrap
 * so validation, errors, and request logging behave the same in tests.
 *
 * Cookie-based admin CSRF: not wired here — admin clients use JWT Authorization;
 * if introducing cookie sessions, add a double-submit token or SameSite+Origin checks on mutating routes.
 */
export function configureHttpApplication(app: INestApplication): void {
  const expressApp = app.getHttpAdapter().getInstance() as express.Application;
  expressApp.set('trust proxy', true);
  expressApp.use(express.json({ limit: '1mb' }));
  expressApp.use(express.urlencoded({ extended: true, limit: '1mb' }));

  const captureRawBody = json({
    verify: (req: Request & { rawBody?: Buffer }, _res, buf) => {
      req.rawBody = buf;
    },
  });
  for (const prefix of ['/webhooks/postmark', '/v1/webhooks/postmark']) {
    app.use(prefix, captureRawBody);
  }

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
            constraints: error.constraints ?? {},
          })),
        }),
    }),
  );
  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalInterceptors(new RequestLoggingInterceptor());
}
