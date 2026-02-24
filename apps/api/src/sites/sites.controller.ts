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
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { CreateSiteDto } from './dto/create-site.dto';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import { UpdateSiteStatusDto } from './dto/update-site-status.dto';
import { SitesService } from './sites.service';

@ApiTags('sites')
@Controller('sites')
export class SitesController {
  constructor(private readonly sitesService: SitesService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new pollution site' })
  @ApiCreatedResponse({ description: 'Site created successfully' })
  create(@Body() dto: CreateSiteDto) {
    return this.sitesService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List sites with optional filters' })
  @ApiOkResponse({ description: 'Sites fetched successfully' })
  findAll(@Query() query: ListSitesQueryDto) {
    return this.sitesService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get site details with reports' })
  @ApiOkResponse({ description: 'Site fetched successfully' })
  findOne(@Param('id') id: string) {
    return this.sitesService.findOne(id);
  }

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update canonical site lifecycle status' })
  @ApiOkResponse({ description: 'Site status updated successfully' })
  updateStatus(@Param('id') id: string, @Body() dto: UpdateSiteStatusDto) {
    return this.sitesService.updateStatus(id, dto);
  }
}
