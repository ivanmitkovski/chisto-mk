import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class OrganizerQuizAnswerItemDto {
  @ApiProperty({ example: 'q1_safety', description: 'Question id from the quiz session payload' })
  @IsString()
  @MinLength(4)
  @MaxLength(64)
  @Matches(/^[a-z0-9_]+$/i)
  questionId!: string;

  @ApiProperty({ example: 'q1_b', description: 'Selected option id for that question' })
  @IsString()
  @MinLength(2)
  @MaxLength(80)
  @Matches(/^[a-z0-9_]+$/i)
  selectedOptionId!: string;
}
