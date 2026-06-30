export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export type TelemetryEvent = {
  level: LogLevel;
  message: string;
  timestamp: string;
  requestId?: string;
  context?: Record<string, unknown>;
  source?: 'admin-server' | 'admin-client' | 'admin-bff';
};
