import { IsBoolean, IsEmail, IsIn, IsObject, IsOptional, IsString } from 'class-validator';

/** Subset of Postmark webhook event payloads we handle for suppression. */
export class PostmarkWebhookDto {
  @IsString()
  @IsIn([
    'HardBounce',
    'SpamComplaint',
    'ManualSuppression',
    'SubscriptionChange',
    'Bounce',
  ])
  RecordType!: string;

  @IsEmail()
  Email!: string;

  @IsOptional()
  @IsBoolean()
  SuppressSending?: boolean;

  @IsOptional()
  @IsString()
  Type?: string;

  @IsOptional()
  @IsObject()
  Metadata?: Record<string, unknown>;
}
