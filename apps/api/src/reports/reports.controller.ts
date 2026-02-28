import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { Roles } from '../auth/roles.decorator';
import {
  AdminReportDetailDto,
  AdminReportListResponseDto,
} from './dto/admin-report.dto';
import {
  AdminDuplicateReportGroupDto,
  AdminDuplicateReportGroupsResponseDto,
  MergeDuplicateReportsDto,
  MergeDuplicateReportsResponseDto,
} from './dto/admin-duplicate-report.dto';
import { RolesGuard } from '../auth/roles.guard';
import { CreateReportDto } from './dto/create-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { ReportsService } from './reports.service';
import { UserReportListItemDto } from './dto/user-report.dto';

@ApiTags('reports')
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post()
  @ApiOperation({ summary: 'Create a report for a site' })
  @ApiCreatedResponse({ description: 'Report created successfully' })
  create(@Body() dto: CreateReportDto) {
    return this.reportsService.create(dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List reports created by the authenticated user' })
  @ApiOkResponse({
    description: 'Reports for the current user fetched successfully',
    type: UserReportListItemDto,
    isArray: true,
  })
  findForCurrentUser(@CurrentUser() user: AuthenticatedUser): Promise<UserReportListItemDto[]> {
    return this.reportsService.findForCurrentUser(user);
  }

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List reports for admin moderation queue' })
  @ApiOkResponse({ description: 'Reports fetched successfully', type: AdminReportListResponseDto })
  findAllForModeration(@Query() query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    return this.reportsService.findAllForModeration(query);
  }

  @Get('duplicates')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List duplicate report groups for moderation' })
  @ApiOkResponse({
    description: 'Duplicate report groups fetched successfully',
    type: AdminDuplicateReportGroupsResponseDto,
  })
  findDuplicateGroups(@Query() query: ListReportsQueryDto): Promise<AdminDuplicateReportGroupsResponseDto> {
    return this.reportsService.findDuplicateGroups(query);
  }

  @Get(':id/duplicates')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get duplicate group details for a report' })
  @ApiOkResponse({
    description: 'Duplicate report group fetched successfully',
    type: AdminDuplicateReportGroupDto,
  })
  findDuplicateGroupByReport(@Param('id') id: string): Promise<AdminDuplicateReportGroupDto> {
    return this.reportsService.findDuplicateGroupByReport(id);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get detailed report view for moderation' })
  @ApiOkResponse({ description: 'Report fetched successfully', type: AdminReportDetailDto })
  findOneForModeration(@Param('id') id: string): Promise<AdminReportDetailDto> {
    return this.reportsService.findOneForModeration(id);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update report moderation status' })
  @ApiOkResponse({ description: 'Report status updated successfully' })
  updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateReportStatusDto,
    @CurrentUser() moderator: AuthenticatedUser,
  ) {
    return this.reportsService.updateStatus(id, dto, moderator);
  }

  @Post(':id/merge')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Approve and merge child duplicate reports into a primary report' })
  @ApiOkResponse({
    description: 'Duplicate reports merged successfully',
    type: MergeDuplicateReportsResponseDto,
  })
  mergeDuplicates(
    @Param('id') id: string,
    @Body() dto: MergeDuplicateReportsDto,
    @CurrentUser() moderator: AuthenticatedUser,
  ): Promise<MergeDuplicateReportsResponseDto> {
    return this.reportsService.mergeDuplicateReports(id, dto, moderator);
  }
}
