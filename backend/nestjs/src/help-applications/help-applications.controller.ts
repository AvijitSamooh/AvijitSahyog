import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { AuthenticatedRequest } from '../auth/auth.types';
import { CreateHelpApplicationDto, HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { StartApplicationWindowDto } from './dto/application-window.dto';
import { ResubmitHelpApplicationDto } from './dto/resubmit-help-application.dto';
import { ReviewHelpApplicationDto } from './dto/review-help-application.dto';
import { VoteHelpApplicationDto } from './dto/vote-help-application.dto';
import { ApplicationWindowsService } from './application-windows.service';
import { HelpApplicationsService } from './help-applications.service';

@Controller('application-windows')
export class ApplicationWindowsController {
  constructor(private readonly service: ApplicationWindowsService) {}

  @Get()
  list() {
    return this.service.list();
  }
}

@Controller('admin/application-windows')
@UseGuards(AdminGuard)
export class AdminApplicationWindowsController {
  constructor(private readonly service: ApplicationWindowsService) {}

  @Post(':type/start')
  start(
    @Req() req: Request & AuthenticatedRequest,
    @Param('type') type: HelpApplicationTypeDto,
    @Body() dto: StartApplicationWindowDto,
  ) {
    return this.service.start(req.user, type, dto);
  }

  @Post(':type/close')
  close(
    @Req() req: Request & AuthenticatedRequest,
    @Param('type') type: HelpApplicationTypeDto,
  ) {
    return this.service.close(req.user, type);
  }
}

@Controller('applications')
@UseGuards(FirebaseAuthGuard)
export class HelpApplicationsController {
  constructor(private readonly service: HelpApplicationsService) {}

  @Post()
  create(@Req() req: Request & AuthenticatedRequest, @Body() dto: CreateHelpApplicationDto) {
    return this.service.create(req.user, dto);
  }

  @Get('mine')
  listMine(@Req() req: Request & AuthenticatedRequest) {
    return this.service.listMine(req.user);
  }

  @Get('mine/:id')
  findMine(@Req() req: Request & AuthenticatedRequest, @Param('id') id: string) {
    return this.service.findMine(req.user, id);
  }

  @Delete('mine/:id')
  deleteMine(@Req() req: Request & AuthenticatedRequest, @Param('id') id: string) {
    return this.service.deleteMine(req.user, id);
  }

  @Patch('mine/:id/resubmit')
  resubmit(@Req() req: Request & AuthenticatedRequest, @Param('id') id: string, @Body() dto: ResubmitHelpApplicationDto) {
    return this.service.resubmit(req.user, id, dto);
  }
}

@Controller('admin/applications')
@UseGuards(AdminGuard)
export class AdminHelpApplicationsController {
  constructor(private readonly service: HelpApplicationsService) {}

  @Get()
  list(@Query('type') type?: string, @Query('status') status?: string) {
    return this.service.listForAdmin(type, status);
  }

  @Post(':id/vote')
  vote(@Req() req: Request & AuthenticatedRequest, @Param('id') id: string, @Body() dto: VoteHelpApplicationDto) {
    return this.service.vote(req.user, id, dto);
  }

  @Patch(':id/review')
  review(@Param('id') id: string, @Body() dto: ReviewHelpApplicationDto) {
    return this.service.review(id, dto);
  }
}
