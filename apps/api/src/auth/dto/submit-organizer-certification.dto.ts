import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsString,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { OrganizerQuizAnswerItemDto } from './organizer-quiz-answer-item.dto';
import { ORGANIZER_QUIZ_DRAW_SIZE } from '../organizer-quiz-bank';

export class SubmitOrganizerCertificationDto {
  @ApiProperty({
    description: 'Signed quiz session from GET /auth/me/organizer-certification/quiz',
  })
  @IsString()
  @MinLength(20)
  quizSession!: string;

  @ApiProperty({ type: [OrganizerQuizAnswerItemDto] })
  @IsArray()
  @ArrayMinSize(ORGANIZER_QUIZ_DRAW_SIZE)
  @ArrayMaxSize(ORGANIZER_QUIZ_DRAW_SIZE)
  @ValidateNested({ each: true })
  @Type(() => OrganizerQuizAnswerItemDto)
  answers!: OrganizerQuizAnswerItemDto[];
}
