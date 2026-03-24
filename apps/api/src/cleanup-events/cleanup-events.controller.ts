import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ADMIN_PANEL_ROLES, ADMIN_WRITE_ROLES } from '../auth/admin-roles';
import { CleanupEventsService } from './cleanup-events.service';
import { CreateCleanupEventDto } from './dto/create-cleanup-event.dto';
import { PatchCleanupEventDto } from './dto/patch-cleanup-event.dto';
import { ListCleanupEventsQueryDto } from './dto/list-cleanup-events-query.dto';

@ApiTags('admin-cleanup-events')
@Controller('admin/cleanup-events')
export class CleanupEventsController {
  constructor(private readonly cleanupEventsService: CleanupEventsService) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List cleanup events' })
  @ApiOkResponse({ description: 'Cleanup events' })
  list(@Query() query: ListCleanupEventsQueryDto) {
    return this.cleanupEventsService.list(query);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_PANEL_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get cleanup event' })
  @ApiOkResponse({ description: 'Cleanup event' })
  findOne(@Param('id') id: string) {
    return this.cleanupEventsService.findOne(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create cleanup event' })
  @ApiOkResponse({ description: 'Created' })
  create(@Body() dto: CreateCleanupEventDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.cleanupEventsService.create(dto, actor);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(...ADMIN_WRITE_ROLES)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update cleanup event' })
  @ApiOkResponse({ description: 'Updated' })
  patch(
    @Param('id') id: string,
    @Body() dto: PatchCleanupEventDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.cleanupEventsService.patch(id, dto, actor);
  }
}
