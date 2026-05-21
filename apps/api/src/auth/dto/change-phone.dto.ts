import { ApiProperty } from '@nestjs/swagger';
import { IsString, Length, Matches } from 'class-validator';

export class RequestPhoneChangeDto {
  @ApiProperty({ example: '+38970123456' })
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/)
  newPhoneNumber!: string;
}

export class ConfirmPhoneChangeDto {
  @ApiProperty({ example: '+38970123456' })
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/)
  newPhoneNumber!: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @Length(6, 6)
  @Matches(/^\d{6}$/)
  code!: string;
}
