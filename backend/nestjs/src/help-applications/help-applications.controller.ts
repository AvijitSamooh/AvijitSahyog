import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Req, StreamableFile, UseGuards } from '@nestjs/common';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { Request } from 'express';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { AuthenticatedRequest } from '../auth/auth.types';
import { CreateHelpApplicationDto, HelpApplicationTypeDto } from './dto/create-help-application.dto';
import { StartApplicationWindowDto } from './dto/application-window.dto';
import { ResubmitHelpApplicationDto } from './dto/resubmit-help-application.dto';
import { UpdateHelpApplicationDto } from './dto/update-help-application.dto';
import { ReviewHelpApplicationDto } from './dto/review-help-application.dto';
import { VoteHelpApplicationDto } from './dto/vote-help-application.dto';
import { CreateApplicationRuleDto, PublicApplicationRulesQueryDto, UpdateApplicationRuleDto } from './dto/application-rule.dto';
import { ApplicationRulesService } from './application-rules.service';
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

  @Patch('mine/:id')
  updateMine(@Req() req: Request & AuthenticatedRequest, @Param('id') id: string, @Body() dto: UpdateHelpApplicationDto) {
    return this.service.updateMine(req.user, id, dto);
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

  @Get('summary')
  summary(@Query('type') type?: string) {
    return this.service.adminSummary(type);
  }

  @Get('photo-manifest')
  photoManifest(@Query('type') type?: string, @Query('status') status?: string) {
    return this.service.photoManifest(type, status);
  }

  @Post('certificate-photo-export')
  async certificatePhotoExport(@Query('type') type?: string, @Query('status') status?: string) {
    const exportType = type || 'PRATIBHA_SAMMAN';
    const exportStatus = status || 'CONSIDERED_FOR_SAMMAN';
    const summary = await this.service.certificatePhotoExportSummary(exportType, exportStatus);
    const expiresAt = Date.now() + 15 * 60 * 1000;
    const payload = Buffer.from(JSON.stringify({ type: exportType, status: exportStatus, expiresAt }), 'utf8').toString('base64url');
    const signature = exportSignature(payload);
    return {
      ...summary,
      expiresAt: new Date(expiresAt).toISOString(),
      downloadPath: `/exports/certificate-photos?token=${payload}.${signature}`,
      filename: `AvijitSahyog_Certificate_Photos_${new Date().getFullYear()}.zip`,
    };
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


@Controller('application-rules')
export class ApplicationRulesController {
  constructor(private readonly service: ApplicationRulesService) {}

  @Get(':type')
  list(@Param('type') type: HelpApplicationTypeDto, @Query() query: PublicApplicationRulesQueryDto) {
    return this.service.list(type, query.language);
  }
}

@Controller('admin/application-rules')
@UseGuards(AdminGuard)
export class AdminApplicationRulesController {
  constructor(private readonly service: ApplicationRulesService) {}

  @Get(':type')
  list(@Param('type') type: HelpApplicationTypeDto) { return this.service.listAdmin(type); }

  @Post()
  create(@Body() dto: CreateApplicationRuleDto) { return this.service.create(dto); }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateApplicationRuleDto) { return this.service.update(id, dto); }

  @Delete(':id')
  remove(@Param('id') id: string) { return this.service.remove(id); }
}

@Controller('exports')
export class CertificatePhotoExportController {
  constructor(private readonly service: HelpApplicationsService) {}

  @Get('certificate-photos')
  async download(@Query('token') token?: string): Promise<StreamableFile> {
    const payload = verifyExportToken(token);
    const zip = await this.service.buildCertificatePhotoExport(payload.type, payload.status);
    const filename = `AvijitSahyog_Certificate_Photos_${new Date().getFullYear()}.zip`;
    return new StreamableFile(zip, {
      type: 'application/zip',
      disposition: `attachment; filename="${filename}"`,
    });
  }
}

function exportSecret(): string {
  const secret = process.env.EXPORT_TOKEN_SECRET || process.env.R2_SECRET_ACCESS_KEY;
  if (!secret) throw new Error('EXPORT_TOKEN_SECRET or R2_SECRET_ACCESS_KEY must be configured.');
  return secret;
}

function exportSignature(payload: string): string {
  return createHmac('sha256', exportSecret()).update(payload).digest('base64url');
}

function verifyExportToken(token?: string): { type: string; status: string } {
  if (!token) throw new Error('Export token is required.');
  const separator = token.lastIndexOf('.');
  if (separator <= 0) throw new Error('Invalid export token.');
  const payload = token.slice(0, separator);
  const signature = token.slice(separator + 1);
  const expected = exportSignature(payload);
  if (signature.length !== expected.length || !timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    throw new Error('Invalid export token.');
  }
  const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as { type?: string; status?: string; expiresAt?: number };
  if (!decoded.type || !decoded.status || !decoded.expiresAt || decoded.expiresAt < Date.now()) {
    throw new Error('Export token has expired or is invalid.');
  }
  return { type: decoded.type, status: decoded.status };
}
