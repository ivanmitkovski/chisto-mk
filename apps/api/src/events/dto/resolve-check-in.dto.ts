import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsString } from 'class-validator';

export class ResolveCheckInDto {
  @ApiProperty({
    description: 'Organizer action on the pending check-in request',
    enum: ['approve', 'reject'],
    example: 'approve',
  })
  @IsString()
  @IsIn(['approve', 'reject'])
  action!: 'approve' | 'reject';
}
