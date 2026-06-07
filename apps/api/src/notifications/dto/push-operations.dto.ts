import { ApiProperty } from '@nestjs/swagger';

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
