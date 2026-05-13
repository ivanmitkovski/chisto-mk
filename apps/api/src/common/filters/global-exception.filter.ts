import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { ThrottlerException } from '@nestjs/throttler';
import * as Sentry from '@sentry/node';
import { MulterError } from 'multer';
import { Prisma } from '../../prisma-client';
import { ObservabilityStore } from '../../observability/observability.store';
import { ErrorResponse } from '../errors/error-response.type';

type HttpExceptionPayload = {
  code?: unknown;
  message?: unknown;
  details?: unknown;
  retryable?: boolean;
  retryAfterSeconds?: number;
};

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private static readonly log = new Logger(GlobalExceptionFilter.name);

  private static stamp<T extends object>(body: T): T & { timestamp: string } {
    return { ...body, timestamp: new Date().toISOString() };
  }

  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const response = context.getResponse();
    const request = context.getRequest<{ method?: string; url?: string; requestId?: string }>();

    if (exception instanceof ThrottlerException) {
      response.status(HttpStatus.TOO_MANY_REQUESTS).json(
        GlobalExceptionFilter.stamp({
          code: 'TOO_MANY_REQUESTS',
          message: 'Too many requests. Please wait and try again.',
          retryable: true,
          retryAfterSeconds: 60,
        }),
      );
      return;
    }

    if (exception instanceof MulterError) {
      if (exception.code === 'LIMIT_FILE_SIZE' || exception.code === 'LIMIT_FILE_COUNT') {
        const limits = GlobalExceptionFilter.resolveUploadLimitsForPath(request?.url);
        response.status(HttpStatus.PAYLOAD_TOO_LARGE).json(
          GlobalExceptionFilter.stamp({
            code: 'PAYLOAD_TOO_LARGE',
            message: 'One or more files exceed the allowed size or count.',
            details: limits,
            retryable: false,
          }),
        );
        return;
      }
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const payload = exception.getResponse();
      const normalized = this.normalizeHttpPayload(status, payload);

      response.status(status).json(GlobalExceptionFilter.stamp(normalized));
      return;
    }

    const prismaMapped = this.tryMapPrismaError(exception);
    if (prismaMapped) {
      response.status(prismaMapped.status).json(GlobalExceptionFilter.stamp(prismaMapped.body));
      return;
    }

    // Structured JSON log line (Nest Logger); no raw client bodies.
    const errPayload =
      exception instanceof Error
        ? { name: exception.name, message: exception.message }
        : { message: String(exception) };
    GlobalExceptionFilter.log.error(
      JSON.stringify({
        context: 'GlobalExceptionFilter',
        requestId: request?.requestId ?? null,
        method: request?.method ?? null,
        route: request?.url?.split('?')[0] ?? null,
        message: 'Unhandled exception in request pipeline',
        error: errPayload,
      }),
    );

    Sentry.withScope((scope) => {
      scope.setTag('requestId', request?.requestId ?? 'unknown');
      scope.setExtra('method', request?.method);
      scope.setExtra('route', request?.url?.split('?')[0]);
      if (exception instanceof Error) {
        Sentry.captureException(exception);
      } else {
        Sentry.captureMessage(String(exception), 'error');
      }
    });

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json(
      GlobalExceptionFilter.stamp({
        code: 'INTERNAL_ERROR',
        message: 'Internal server error',
      }),
    );
  }

  private tryMapPrismaError(exception: unknown): { status: number; body: ErrorResponse } | null {
    const code =
      exception && typeof exception === 'object' && 'code' in exception
        ? (exception as { code: string }).code
        : null;
    if (code && (code === 'P1008' || code === 'P1001' || code === 'P1017')) {
      GlobalExceptionFilter.capturePrisma5xxToSentry(code, exception);
      return this.mapPrismaErrorByCode(code);
    }
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      const p2002 = this.tryMapReportSubmitIdempotencyP2002(exception);
      if (p2002) {
        return p2002;
      }
      return this.mapPrismaErrorByCode(exception.code);
    }
    return null;
  }

  private static capturePrisma5xxToSentry(code: string, exception: unknown): void {
    Sentry.withScope((scope) => {
      scope.setTag('prismaErrorCode', code);
      scope.setLevel('error');
      if (exception instanceof Error) {
        Sentry.captureException(exception);
      } else {
        Sentry.captureMessage(`Prisma infrastructure error: ${code}`, 'error');
      }
    });
  }

  private tryMapReportSubmitIdempotencyP2002(
    exception: Prisma.PrismaClientKnownRequestError,
  ): { status: number; body: ErrorResponse } | null {
    if (exception.code !== 'P2002') {
      return null;
    }
    const meta = exception.meta as { target?: string[]; modelName?: string } | undefined;
    if (meta?.modelName === 'ReportSubmitIdempotency') {
      return {
        status: HttpStatus.CONFLICT,
        body: {
          code: 'DUPLICATE_SUBMIT_INFLIGHT',
          message:
            'Another submission with this idempotency key is being processed. Please retry shortly.',
          retryable: true,
          retryAfterSeconds: 5,
        },
      };
    }
    const target = meta?.target;
    if (!target || target.length < 2) {
      return null;
    }
    const hasUserId = target.includes('userId');
    const hasKey = target.includes('key');
    if (!hasUserId || !hasKey) {
      return null;
    }
    return {
      status: HttpStatus.CONFLICT,
      body: {
        code: 'DUPLICATE_SUBMIT_INFLIGHT',
        message: 'Another submission with this idempotency key is being processed. Please retry shortly.',
        retryable: true,
        retryAfterSeconds: 5,
      },
    };
  }

  private mapPrismaErrorByCode(code: string): { status: number; body: ErrorResponse } | null {
    switch (code) {
      case 'P1008':
        ObservabilityStore.recordPrismaP1008Response();
        return {
          status: HttpStatus.SERVICE_UNAVAILABLE,
          body: {
            code: 'DATABASE_TIMEOUT',
            message: 'Database connection timed out. Please try again.',
            retryable: true,
            retryAfterSeconds: 3,
          },
        };
      case 'P1001':
        return {
          status: HttpStatus.SERVICE_UNAVAILABLE,
          body: {
            code: 'DATABASE_UNAVAILABLE',
            message: 'Cannot reach the database. Please try again later.',
            retryable: true,
            retryAfterSeconds: 5,
          },
        };
      case 'P1017':
        return {
          status: HttpStatus.SERVICE_UNAVAILABLE,
          body: {
            code: 'DATABASE_DISCONNECTED',
            message: 'Database connection was closed. Please try again.',
            retryable: true,
            retryAfterSeconds: 3,
          },
        };
      case 'P2025':
        return {
          status: HttpStatus.NOT_FOUND,
          body: {
            code: 'DATABASE_RECORD_NOT_FOUND',
            message: 'The requested record was not found or is no longer available.',
            retryable: false,
          },
        };
      case 'P2003':
        return {
          status: HttpStatus.BAD_REQUEST,
          body: {
            code: 'REFERENCE_CONSTRAINT',
            message: 'The change conflicts with related data.',
            retryable: false,
          },
        };
      default:
        return null;
    }
  }

  private normalizeHttpPayload(status: number, payload: string | object): ErrorResponse {
    if (typeof payload === 'string') {
      return {
        code: this.codeForStatus(status),
        message: payload,
      };
    }

    const candidate = payload as HttpExceptionPayload;
    const hasExplicitCode = typeof candidate.code === 'string';
    const hasExplicitMessage = typeof candidate.message === 'string';

    if (hasExplicitCode && hasExplicitMessage) {
      const error: ErrorResponse = {
        code: candidate.code as string,
        message: candidate.message as string,
      };
      if (typeof candidate.details !== 'undefined') {
        error.details = candidate.details;
      }
      if (typeof candidate.retryable === 'boolean') {
        error.retryable = candidate.retryable;
      }
      if (typeof candidate.retryAfterSeconds === 'number') {
        error.retryAfterSeconds = candidate.retryAfterSeconds;
      }
      return error;
    }

    if (Array.isArray(candidate.message)) {
      return {
        code: this.codeForStatus(status),
        message: 'Request validation failed',
        details: candidate.message,
      };
    }

    return {
      code: this.codeForStatus(status),
      message:
        typeof candidate.message === 'string'
          ? candidate.message
          : 'Request failed',
    };
  }

  private static resolveUploadLimitsForPath(
    url?: string,
  ): { maxBytes: number; maxFiles: number } {
    const path = (url ?? '').split('?')[0].toLowerCase();
    if (path.includes('/event-chat/')) {
      return { maxBytes: 25 * 1024 * 1024, maxFiles: 5 };
    }
    if (path.includes('/avatar')) {
      return { maxBytes: 8 * 1024 * 1024, maxFiles: 1 };
    }
    return { maxBytes: 10 * 1024 * 1024, maxFiles: 5 };
  }

  private codeForStatus(status: number): string {
    switch (status) {
      case HttpStatus.BAD_REQUEST:
        return 'BAD_REQUEST';
      case HttpStatus.UNAUTHORIZED:
        return 'UNAUTHORIZED';
      case HttpStatus.FORBIDDEN:
        return 'FORBIDDEN';
      case HttpStatus.NOT_FOUND:
        return 'NOT_FOUND';
      case HttpStatus.CONFLICT:
        return 'CONFLICT';
      case HttpStatus.TOO_MANY_REQUESTS:
        return 'TOO_MANY_REQUESTS';
      default:
        return 'HTTP_ERROR';
    }
  }
}
