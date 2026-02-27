import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { ErrorResponse } from '../errors/error-response.type';

type HttpExceptionPayload = {
  code?: unknown;
  message?: unknown;
  details?: unknown;
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

    // Log unexpected errors to aid debugging while keeping response generic
    // eslint-disable-next-line no-console
    console.error('Unhandled exception in request pipeline:', exception);

    const fallback: ErrorResponse = {
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
    };

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json(fallback);
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
