import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PatchCheckInOpenResponseDto {
  @ApiProperty({ enum: [true] })
  ok!: true;
}

export class RotateSessionResponseDto {
  @ApiProperty({ enum: [true] })
  ok!: true;
}

export class CheckInQrResponseDto {
  @ApiProperty({ description: 'Opaque signed payload to encode in the QR bitmap' })
  qrPayload!: string;

  @ApiProperty({ description: 'Active check-in session id (must match token claim s)' })
  sessionId!: string;

  @ApiProperty({ description: 'QR expiry instant (ISO 8601)' })
  expiresAt!: string;

  @ApiProperty({ description: 'Token iat in milliseconds since epoch' })
  issuedAtMs!: number;
}

export class CheckInAttendeeRowDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  dedupeKey!: string;

  @ApiPropertyOptional({ nullable: true, description: 'User id when not a guest row' })
  userId!: string | null;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  checkedInAt!: string;

  @ApiPropertyOptional({
    nullable: true,
    description: 'Short-lived signed URL for profile photo when present',
  })
  avatarUrl!: string | null;
}

export class ListCheckInAttendeesResponseDto {
  @ApiProperty({ type: [CheckInAttendeeRowDto] })
  data!: CheckInAttendeeRowDto[];
}

export class ManualCheckInResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  checkedInAt!: string;

  @ApiProperty({ description: 'Credits awarded for this check-in (0 if duplicate)' })
  pointsAwarded!: number;
}

export class RemoveCheckInAttendeeResponseDto {
  @ApiProperty({ enum: [true] })
  ok!: true;
}

export class RedeemCheckInResponseDto {
  @ApiProperty({
    enum: ['pending_confirmation', 'already_checked_in'],
    description: 'Volunteer must wait for organizer when pending_confirmation',
  })
  status!: 'pending_confirmation' | 'already_checked_in';

  @ApiPropertyOptional({ description: 'Present when status is pending_confirmation' })
  pendingId?: string;

  @ApiPropertyOptional({ description: 'ISO expiry for the pending request' })
  expiresAt?: string;

  @ApiPropertyOptional({ description: 'When already checked in' })
  checkedInAt?: string;

  @ApiPropertyOptional({ description: 'Points from this redeem call (typically 0)' })
  pointsAwarded?: number;
}

export class ResolveCheckInApproveResponseDto {
  @ApiProperty()
  checkedInAt!: string;

  @ApiProperty()
  pointsAwarded!: number;

  @ApiProperty()
  userId!: string;

  @ApiProperty()
  displayName!: string;
}

export class ResolveCheckInRejectResponseDto {
  @ApiProperty({ enum: [true] })
  ok!: true;
}

export class PendingStatusResponseDto {
  @ApiProperty({ enum: ['pending', 'expired'] })
  status!: 'pending' | 'expired';

  @ApiPropertyOptional({ description: 'ISO expiry when status is pending' })
  expiresAt?: string;
}
