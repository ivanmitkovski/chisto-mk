import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsIn, IsString, MaxLength, MinLength } from 'class-validator';
import { Role } from '../../prisma-client';
import { SanitizePlainText } from '../../common/sanitize/sanitize-transform.decorator';

const INVITE_ROLES = [Role.SUPPORT, Role.ADMIN, Role.SUPER_ADMIN] as const;

export class CreateAdminInviteDto {
  @ApiProperty({ example: 'moderator@chisto.mk' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'Ana' })
  @IsString()
  @MinLength(2)
  @MaxLength(60)
  @SanitizePlainText()
  firstName!: string;

  @ApiProperty({ example: 'Petrova' })
  @IsString()
  @MinLength(2)
  @MaxLength(60)
  @SanitizePlainText()
  lastName!: string;

  @ApiProperty({ enum: INVITE_ROLES, example: Role.SUPPORT })
  @IsIn(INVITE_ROLES)
  role!: (typeof INVITE_ROLES)[number];
}
