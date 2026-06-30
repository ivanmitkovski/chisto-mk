import { ApiProperty } from '@nestjs/swagger';

export class TermsConsentDto {
  @ApiProperty({ nullable: true, description: 'ISO-8601 when terms were last accepted' })
  termsAcceptedAt!: string | null;

  @ApiProperty({ nullable: true, description: 'Version of terms last accepted' })
  termsVersion!: string | null;

  @ApiProperty({
    description:
      'True when the user must accept current terms (missing or outdated acceptance)',
  })
  requiresTermsAcceptance!: boolean;
}
