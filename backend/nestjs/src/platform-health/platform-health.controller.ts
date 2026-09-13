import { BadRequestException, Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { SuperAdminGuard } from '../auth/super-admin.guard';
import { PlatformHealthService } from './platform-health.service';

type ClientHealthEventBody = {
  clientId?: string;
  sessionId?: string;
  type?: 'APP_ERROR' | 'APP_CRASH';
  message?: string;
  stack?: string;
};

@Controller('platform-health')
export class PlatformHealthController {
  constructor(private readonly health: PlatformHealthService) {}

  @Get()
  async publicHealth() {
    const database = await this.health.checkDatabase();
    return {
      status: database === 'ok' ? 'ok' : 'error',
      service: 'avijit-sahyog-api',
      database,
    };
  }

  @Post('client-events')
  async recordClientEvent(@Body() body: ClientHealthEventBody) {
    if (!body.type || !['APP_ERROR', 'APP_CRASH'].includes(body.type)) {
      throw new BadRequestException('Unsupported client health event.');
    }
    if (!body.clientId || !/^[a-f0-9-]{16,64}$/i.test(body.clientId)) {
      throw new BadRequestException('Invalid client identifier.');
    }
    if (!body.sessionId || !/^[a-f0-9-]{16,64}$/i.test(body.sessionId)) {
      throw new BadRequestException('Invalid session identifier.');
    }

    await this.health.recordEvent({
      type: body.type,
      message: body.message,
      metadata: body.stack ? { stack: body.stack.slice(0, 4000) } : undefined,
    });
    return { status: 'recorded' };
  }

  @Get('summary')
  @UseGuards(SuperAdminGuard)
  getSummary() {
    return this.health.getSummary();
  }
}
