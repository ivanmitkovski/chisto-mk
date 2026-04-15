import { ApiProperty } from '@nestjs/swagger';

export class EventParticipantRowDto {
  @ApiProperty({ description: 'Participant user id' })
  userId!: string;

  @ApiProperty({ description: 'Public display name' })
  displayName!: string;

  @ApiProperty({
    nullable: true,
    description: 'Signed HTTPS URL for profile photo when the user has an avatar',
  })
  avatarUrl!: string | null;

  @ApiProperty({ description: 'When the user joined the event (ISO-8601)' })
  joinedAt!: string;
}

export class ListEventParticipantsMetaDto {
  @ApiProperty()
  hasMore!: boolean;

  @ApiProperty({ nullable: true, description: 'Pass as cursor for the next page' })
  nextCursor!: string | null;
}

export class ListEventParticipantsResponseDto {
  @ApiProperty({ type: [EventParticipantRowDto] })
  data!: EventParticipantRowDto[];

  @ApiProperty({ type: ListEventParticipantsMetaDto })
  meta!: ListEventParticipantsMetaDto;
}
