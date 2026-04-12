import { ApiProperty } from '@nestjs/swagger';

export class JoinersOverTimeEntryDto {
  @ApiProperty({ description: 'ISO 8601 date' })
  date!: string;

  @ApiProperty()
  count!: number;
}

export class CheckInsByHourEntryDto {
  @ApiProperty({ minimum: 0, maximum: 23 })
  hour!: number;

  @ApiProperty()
  count!: number;
}

export class EventAnalyticsResponseDto {
  @ApiProperty()
  totalJoiners!: number;

  @ApiProperty()
  checkedInCount!: number;

  @ApiProperty({ description: 'Attendance rate as a percentage (0–100)' })
  attendanceRate!: number;

  @ApiProperty({ type: [JoinersOverTimeEntryDto] })
  joinersOverTime!: JoinersOverTimeEntryDto[];

  @ApiProperty({ type: [CheckInsByHourEntryDto] })
  checkInsByHour!: CheckInsByHourEntryDto[];
}
