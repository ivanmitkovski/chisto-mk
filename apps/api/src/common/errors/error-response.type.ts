export type ErrorResponse = {
  code: string;
  message: string;
  details?: unknown;
  retryable?: boolean;
  retryAfterSeconds?: number;
};
