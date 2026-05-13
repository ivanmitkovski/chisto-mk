import { BadRequestException, INestApplication, ValidationPipe } from '@nestjs/common';
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
}
