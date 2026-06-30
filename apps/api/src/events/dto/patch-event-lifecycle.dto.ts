import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsString } from 'class-validator';

export class PatchEventLifecycleDto {
  @ApiProperty({
    enum: ['upcoming', 'inProgress', 'completed', 'cancelled'],
    description: 'Target lifecycle status (organizer-only, valid transitions enforced)',
  })
  @IsString()
  @IsIn(['upcoming', 'inProgress', 'completed', 'cancelled'])
  status!: string;
}
