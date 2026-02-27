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
import { RolesGuard } from '../auth/roles.guard';
import { CreateReportDto } from './dto/create-report.dto';
import { ListReportsQueryDto } from './dto/list-reports-query.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { ReportsService } from './reports.service';

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

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List reports for admin moderation queue' })
  @ApiOkResponse({ description: 'Reports fetched successfully', type: AdminReportListResponseDto })
  findAllForModeration(@Query() query: ListReportsQueryDto): Promise<AdminReportListResponseDto> {
    return this.reportsService.findAllForModeration(query);
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
}
