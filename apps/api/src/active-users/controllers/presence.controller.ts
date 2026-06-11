import { Body, Controller, Headers, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiNoContentResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ApiStandardHttpErrorResponses } from '../../common/openapi/standard-http-error-responses.decorator';
import { PresenceHeartbeatDto, PresenceOfflineDto } from '../dto/presence.dto';
import { ActiveUsersPresenceService } from '../services/active-users-presence.service';
import { UserActivityService } from '../services/user-activity.service';

@ApiTags('presence')
@ApiStandardHttpErrorResponses()
@Controller('presence')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PresenceController {
  constructor(
    private readonly presence: ActiveUsersPresenceService,
    private readonly activity: UserActivityService,
  ) {}

  // safe-to-retry: repeated Post is acceptable
  @Post('heartbeat')
  @ApiOperation({ summary: 'Client presence heartbeat (~45s while foreground)' })
  @ApiNoContentResponse()
  async heartbeat(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: PresenceHeartbeatDto,
    @Headers('x-device-id') deviceIdHeader?: string,
  ): Promise<void> {
    const deviceId = deviceIdHeader?.trim();
    if (!deviceId) return;
    await this.presence.heartbeat(user, {
      ...dto,
      deviceId,
    });
  }

  // safe-to-retry: repeated Post is acceptable
  @Post('offline')
  @ApiOperation({ summary: 'Best-effort offline beacon on background/detach' })
  @ApiNoContentResponse()
  async offline(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: PresenceOfflineDto,
    @Headers('x-device-id') deviceIdHeader?: string,
  ): Promise<void> {
    const deviceId = dto.deviceId?.trim() || deviceIdHeader?.trim();
    if (!deviceId) return;
    await this.presence.offline(user, deviceId);
  }

  // safe-to-retry: repeated Post is acceptable
  @Post('app-opened')
  @ApiOperation({ summary: 'Record app opened (once per cold start)' })
  @ApiNoContentResponse()
  async appOpened(
    @CurrentUser() user: AuthenticatedUser,
    @Headers('x-device-id') deviceIdHeader?: string,
  ): Promise<void> {
    await this.activity.recordClientEvent(user, {
      type: 'APP_OPENED',
      ...(deviceIdHeader?.trim() ? { deviceId: deviceIdHeader.trim() } : {}),
    });
  }
}
