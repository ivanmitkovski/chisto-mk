import { Controller, Get, Query, UnauthorizedException, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { WeeklyRankingsQueryDto, WeeklyRankingsResponseDto } from './dto/weekly-rankings.dto';
import { RankingsService } from './rankings.service';
import { ApiStandardHttpErrorResponses } from '../common/openapi/standard-http-error-responses.decorator';

@ApiTags('rankings')
@ApiStandardHttpErrorResponses()
@Controller('rankings')
@UseGuards(ThrottlerGuard, JwtAuthGuard)
@ApiBearerAuth()
export class RankingsController {
  constructor(private readonly rankingsService: RankingsService) {}

  @Get('weekly')
  @Throttle({ default: { ttl: 60_000, limit: 40 } })
  @ApiOperation({ summary: 'Weekly points leaderboard (Europe/Skopje Monday–Sunday, report points only)' })
  @ApiOkResponse({ description: 'Weekly leaderboard for citizens', type: WeeklyRankingsResponseDto })
  async getWeekly(
    @CurrentUser() user: AuthenticatedUser | undefined,
    @Query() query: WeeklyRankingsQueryDto,
  ): Promise<WeeklyRankingsResponseDto> {
    if (!user) {
      throw new UnauthorizedException({
        code: 'UNAUTHORIZED',
        message: 'Authentication required',
      });
    }
    return this.rankingsService.getWeeklyLeaderboard(user.userId, query.limit ?? 50);
  }
}
