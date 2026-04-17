import { ApiProperty } from '@nestjs/swagger';

export class JoinersCumulativeEntryDto {
  @ApiProperty({ description: 'ISO-8601 instant when the participant joined' })
  at!: string;

  @ApiProperty({ description: 'Running total of participants joined up to and including this point' })
  cumulativeJoiners!: number;
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

  @ApiProperty({ description: 'Attendance rate as a percentage (0–100), from check-in rows vs joiners' })
  attendanceRate!: number;

  @ApiProperty({
    type: [JoinersCumulativeEntryDto],
    description: 'One point per join, ordered by time, with running cumulative count',
  })
  joinersCumulative!: JoinersCumulativeEntryDto[];

  @ApiProperty({
    type: [CheckInsByHourEntryDto],
    description: 'Exactly 24 entries (hours 0–23 UTC), zeros where no check-ins',
  })
  checkInsByHour!: CheckInsByHourEntryDto[];
}
