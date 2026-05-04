import { ApiProperty } from '@nestjs/swagger';

/** Response for POST /reports/upload and POST /reports/:id/media */
export class ReportMediaUrlsResponseDto {
  @ApiProperty({
    type: [String],
    description: 'HTTPS object URLs (or keys when virtual-hosted base is unset) for uploaded images',
  })
  urls!: string[];
}
