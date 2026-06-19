import { ApiProperty } from '@nestjs/swagger';

export class PushOutboxTotalsDto {
  @ApiProperty()
  deliveredTotal!: number;

  @ApiProperty()
  failedPermanentlyTotal!: number;

  @ApiProperty()
  pendingTotal!: number;
}

export class PushStatsDto {
  @ApiProperty()
  sendsTotal!: number;

  @ApiProperty()
  sendsSuccess!: number;

  @ApiProperty()
  sendsFailure!: number;

  @ApiProperty()
  sendsRevoked!: number;

  @ApiProperty({ type: 'object', additionalProperties: true })
  sendsByType!: Record<string, { success: number; failure: number; revoked: number }>;

  @ApiProperty()
  tokenRevocations!: number;

  @ApiProperty()
  queueRetries!: number;

  @ApiProperty()
  inboxReads!: number;

  @ApiProperty()
  queueDepth!: number;

  @ApiProperty()
  activeLeases!: number;

  @ApiProperty()
  deadLetterCount!: number;

  @ApiProperty({ type: PushOutboxTotalsDto })
  outbox!: PushOutboxTotalsDto;
}

export class DeliveryReportSendsDto {
  @ApiProperty()
  total!: number;

  @ApiProperty()
  success!: number;

  @ApiProperty()
  failure!: number;

  @ApiProperty()
  revoked!: number;

  @ApiProperty({ type: 'object', additionalProperties: true })
  byType!: Record<string, { success: number; failure: number; revoked: number }>;
}

export class DeliveryReportInboxDto {
  @ApiProperty()
  notificationsSent!: number;

  @ApiProperty()
  notificationsOpened!: number;

  @ApiProperty()
  openRate!: number;
}

export class DeliveryReportQueueDto {
  @ApiProperty()
  depth!: number;

  @ApiProperty()
  activeLeases!: number;

  @ApiProperty()
  deadLetterCount!: number;

  @ApiProperty()
  retries!: number;
}

export class DeliveryReportDto {
  @ApiProperty({ type: DeliveryReportSendsDto })
  sends!: DeliveryReportSendsDto;

  @ApiProperty({ type: DeliveryReportInboxDto })
  inbox!: DeliveryReportInboxDto;

  @ApiProperty({ type: DeliveryReportQueueDto })
  queue!: DeliveryReportQueueDto;

  @ApiProperty({ type: PushOutboxTotalsDto })
  outbox!: PushOutboxTotalsDto;
}

export class DeadLetterRowDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  userNotificationId!: string;

  @ApiProperty()
  deviceTokenSuffix!: string;

  @ApiProperty()
  attempts!: number;

  @ApiProperty({ nullable: true })
  lastErrorCode!: string | null;

  @ApiProperty({ nullable: true })
  lastErrorMessage!: string | null;

  @ApiProperty({ nullable: true })
  lastAttemptAt!: string | null;

  @ApiProperty()
  createdAt!: string;
}

export class PaginationMetaDto {
  @ApiProperty()
  page!: number;

  @ApiProperty()
  limit!: number;

  @ApiProperty()
  total!: number;
}

export class DeadLetterPageDto {
  @ApiProperty({ type: [DeadLetterRowDto] })
  data!: DeadLetterRowDto[];

  @ApiProperty({ type: PaginationMetaDto })
  meta!: PaginationMetaDto;
}

export class DeadLetterRequeueResultDto {
  @ApiProperty()
  requeued!: number;
}

export class DeadLetterRequeueOneResultDto {
  @ApiProperty()
  requeued!: boolean;
}

export class DeadLetterPurgeResultDto {
  @ApiProperty()
  purged!: number;
}

export class PushDiagnosticsTopErrorCodeDto {
  @ApiProperty()
  code!: string;

  @ApiProperty()
  count!: number;
}

export class PushDiagnosticsDto {
  @ApiProperty()
  fcmEnabled!: boolean;

  @ApiProperty()
  fcmReady!: boolean;

  @ApiProperty({ nullable: true })
  projectId!: string | null;

  @ApiProperty({ enum: ['valid', 'missing', 'invalid_json', 'invalid_structure'] })
  credentialStatus!: string;

  @ApiProperty({ nullable: true })
  credentialParseError!: string | null;

  @ApiProperty()
  deadLetterTotal!: number;

  @ApiProperty({ type: [PushDiagnosticsTopErrorCodeDto] })
  topErrorCodes!: PushDiagnosticsTopErrorCodeDto[];

  @ApiProperty({ type: [PushDiagnosticsTopErrorCodeDto] })
  errorsLast1h!: PushDiagnosticsTopErrorCodeDto[];

  @ApiProperty({ type: [PushDiagnosticsTopErrorCodeDto] })
  errorsLast24h!: PushDiagnosticsTopErrorCodeDto[];

  @ApiProperty()
  queueDepth!: number;

  @ApiProperty()
  activeLeases!: number;

  @ApiProperty()
  pendingCount!: number;

  @ApiProperty()
  registeredDeviceTokens!: number;

  @ApiProperty({ type: 'object', additionalProperties: true })
  workerStatus!: {
    expected: boolean;
    running: boolean;
    stale: boolean;
    lastError?: string;
  };

  @ApiProperty({ nullable: true })
  remediation!: string | null;
}

export class TestPushFunnelDto {
  @ApiProperty()
  inboxCreated!: boolean;

  @ApiProperty()
  pushEnabled!: boolean;

  @ApiProperty()
  fcmReady!: boolean;

  @ApiProperty()
  activeTokenCount!: number;

  @ApiProperty()
  outboxEnqueued!: number;

  @ApiProperty({ nullable: true })
  notificationId!: string | null;
}

export class TestPushResultDto {
  @ApiProperty()
  success!: boolean;

  @ApiProperty({ type: TestPushFunnelDto })
  funnel!: TestPushFunnelDto;

  @ApiProperty({ nullable: true })
  remediation!: string | null;
}

export class PushHealthDto {
  @ApiProperty({ enum: ['ok', 'degraded', 'disabled'] })
  status!: 'ok' | 'degraded' | 'disabled';

  @ApiProperty()
  fcmEnabled!: boolean;

  @ApiProperty()
  fcmReady!: boolean;

  @ApiProperty({ nullable: true })
  projectId!: string | null;

  @ApiProperty({ enum: ['valid', 'missing', 'invalid_json', 'invalid_structure'] })
  credentialStatus!: string;

  @ApiProperty({ nullable: true })
  credentialParseError!: string | null;

  @ApiProperty({ type: 'object', additionalProperties: true })
  worker!: {
    expected: boolean;
    running: boolean;
    stale: boolean;
    lastError?: string;
  };

  @ApiProperty({ type: 'object', additionalProperties: true })
  outbox!: {
    pending: number;
    leased: number;
    deadLetter: number;
    oldestPendingAgeSec: number | null;
  };

  @ApiProperty({ type: 'object', additionalProperties: true })
  circuitBreaker!: { state: 'closed' | 'open' | 'half_open' };

  @ApiProperty({ type: 'object', additionalProperties: true })
  pgListener!: { enabled: boolean; connected: boolean };

  @ApiProperty({ type: 'object', additionalProperties: true })
  dispatchSkips!: {
    fcmNotReady: number;
    noTokens: number;
    writerNull: number;
  };

  @ApiProperty({ type: [String] })
  alerts!: string[];
}

export class EmailHealthDto {
  @ApiProperty({ enum: ['ok', 'degraded', 'disabled'] })
  status!: 'ok' | 'degraded' | 'disabled';

  @ApiProperty()
  emailEnabled!: boolean;

  @ApiProperty({ type: 'object', additionalProperties: true })
  worker!: {
    expected: boolean;
    running: boolean;
    stale: boolean;
    lastError?: string;
  };

  @ApiProperty({ type: 'object', additionalProperties: true })
  outbox!: {
    pending: number;
    deadLetter: number;
  };

  @ApiProperty({ type: [String] })
  alerts!: string[];
}

export class EmailDeadLetterRequeueResultDto {
  @ApiProperty()
  requeued!: number;
}

export class EmailDeadLetterRequeueOneResultDto {
  @ApiProperty()
  requeued!: boolean;
}

export class EmailDeadLetterPurgeResultDto {
  @ApiProperty()
  purged!: number;
}
