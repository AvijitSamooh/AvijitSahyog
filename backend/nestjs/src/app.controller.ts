import { Controller, Get } from '@nestjs/common';

import { PrismaService } from './prisma/prisma.service';

@Controller('health')
export class AppController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async getHealth() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;

      return {
        status: 'ok',
        service: 'avijit-sahyog-api',
        database: 'ok',
      };
    } catch {
      return {
        status: 'error',
        service: 'avijit-sahyog-api',
        database: 'error',
      };
    }
  }
}