import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Prisma } from '../../prisma-client';
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
  catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const response = context.getResponse();

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const payload = exception.getResponse();
      const normalized = this.normalizeHttpPayload(status, payload);

      response.status(status).json(normalized);
      return;
    }

    const prismaMapped = this.tryMapPrismaError(exception);
    if (prismaMapped) {
      response.status(prismaMapped.status).json(prismaMapped.body);
      return;
    }

    console.error('Unhandled exception in request pipeline:', exception);

    const fallback: ErrorResponse = {
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
    };

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json(fallback);
  }

  private tryMapPrismaError(exception: unknown): { status: number; body: ErrorResponse } | null {
    const code =
      exception && typeof exception === 'object' && 'code' in exception
        ? (exception as { code: string }).code
        : null;
    if (code && (code === 'P1008' || code === 'P1001' || code === 'P1017')) {
      return this.mapPrismaErrorByCode(code);
    }
    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      return this.mapPrismaErrorByCode(exception.code);
    }
    return null;
  }

  private mapPrismaErrorByCode(code: string): { status: number; body: ErrorResponse } | null {
    switch (code) {
      case 'P1008':
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
      default:
        return 'HTTP_ERROR';
    }
  }
}
