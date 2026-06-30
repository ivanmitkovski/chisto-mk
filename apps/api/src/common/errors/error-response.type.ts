export type ErrorResponse = {
  code: string;
  message: string;
  details?: unknown;
  retryable?: boolean;
  retryAfterSeconds?: number;
  /** Set by [GlobalExceptionFilter] on outbound JSON (ISO-8601 UTC). */
  timestamp?: string;
};
