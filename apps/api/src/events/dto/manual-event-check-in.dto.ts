import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsString, Matches } from 'class-validator';
import { PRISMA_CUID_REGEX } from '../../common/validators/is-cuid.validator';

export class ManualEventCheckInDto {
  @ApiProperty({
    description:
      'User id of a volunteer who joined the event (EventParticipant row must exist)',
    example: 'clxxxxxxxxxxxxxxxxxxxxxxxx',
  })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Matches(PRISMA_CUID_REGEX, { message: 'userId must be a valid cuid' })
  userId!: string;
}
