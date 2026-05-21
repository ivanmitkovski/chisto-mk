import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class NotificationActorDto {
  @ApiProperty({ description: 'User id of the actor who triggered the notification' })
  id!: string;

  @ApiProperty({ description: 'Display name (first + last)' })
  displayName!: string;

  @ApiPropertyOptional({
    nullable: true,
    description: 'Signed URL for profile avatar when available',
  })
  avatarUrl!: string | null;
}
