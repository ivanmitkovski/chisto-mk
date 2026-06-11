import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { AdminInviteAcceptService } from '../services/admin-invite-accept.service';
import { AcceptAdminInviteDto } from '../dto/accept-admin-invite.dto';
import { BeginInviteMfaDto } from '../dto/begin-invite-mfa.dto';
import { ValidateAdminInviteQueryDto } from '../dto/validate-admin-invite-query.dto';
import { Idempotent } from '../../common/idempotency/idempotency.decorator';

@ApiTags('admin-invite-accept')
@ApiStandardHttpErrorResponses()
@Controller('admin/invites')
export class AdminInviteAcceptController {
  constructor(private readonly acceptService: AdminInviteAcceptService) {}

  @Get('validate')
  @Throttle({ default: { ttl: 60_000, limit: 20 } })
  @ApiOperation({ summary: 'Validate admin invite token (public)' })
  @ApiOkResponse({ description: 'Invite is valid' })
  validate(@Query() query: ValidateAdminInviteQueryDto) {
    return this.acceptService.validate(query);
  }

  @Idempotent('admin_invite_begin_mfa')
  @Post('begin-mfa')
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @ApiOperation({ summary: 'Begin TOTP enrollment for invite accept (public)' })
  @ApiOkResponse({ description: 'MFA setup URI returned' })
  beginMfa(@Body() dto: BeginInviteMfaDto) {
    return this.acceptService.beginMfa(dto);
  }

  @Idempotent('admin_invite_accept')
  @Post('accept')
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @ApiOperation({ summary: 'Accept admin invite and create account (public)' })
  @ApiOkResponse({ description: 'Account created and session issued' })
  accept(@Body() dto: AcceptAdminInviteDto) {
    return this.acceptService.accept(dto);
  }
}
