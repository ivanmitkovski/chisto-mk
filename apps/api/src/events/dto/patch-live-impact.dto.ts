import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, Max, Min } from 'class-validator';

export class PatchLiveImpactDto {
  @ApiProperty({ minimum: 0, maximum: 9999, description: 'Organizer-reported bags collected (live pulse)' })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(9999)
  reportedBagsCollected!: number;
}
