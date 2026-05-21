import { Idempotent } from '../common/idempotency/idempotency.decorator';
import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentAuthenticatedUser } from '../auth/current-authenticated-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ModerationService } from './moderation.service';
import { PostUgcReportDto } from './dto/post-ugc-report.dto';
import { PostUserBlockDto } from './dto/post-user-block.dto';

@ApiTags('moderation')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ModerationController {
  constructor(private readonly moderation: ModerationService) {}

  @Idempotent('moderation_moderation_17')
  @Post('moderation/reports')
  @ApiOperation({ summary: 'Report UGC (comment, chat message, user, site, event)' })
  submitReport(
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
    @Body() dto: PostUgcReportDto,
  ) {
    return this.moderation.submitReport(user, dto);
  }

  @Idempotent('moderation_moderation_26')
  @Post('users/me/blocks')
  @ApiOperation({ summary: 'Block a user' })
  blockUser(
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
    @Body() dto: PostUserBlockDto,
  ) {
    return this.moderation.blockUser(user, dto);
  }

  @Get('users/me/blocks')
  @ApiOperation({ summary: 'List blocked users' })
  listBlocks(@CurrentAuthenticatedUser() user: AuthenticatedUser) {
    return this.moderation.listBlocks(user);
  }

  // safe-to-retry: repeated Delete is acceptable
  @Delete('users/me/blocks/:blockedUserId')
  @ApiOperation({ summary: 'Unblock a user' })
  unblock(
    @CurrentAuthenticatedUser() user: AuthenticatedUser,
    @Param('blockedUserId') blockedUserId: string,
  ) {
    return this.moderation.unblock(user, blockedUserId);
  }
}
