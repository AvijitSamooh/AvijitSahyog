import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminDashboardService {
  constructor(private readonly prisma: PrismaService) {}

  async getSummary() {
    const [causes, organisations, beneficiaries] = await Promise.all([
      this.count(this.prisma.cause),
      this.count(this.prisma.organisation),
      this.count(this.prisma.beneficiary),
    ]);
    return { causes, organisations, beneficiaries };
  }

  private async count(model: { count(args: { where?: { isActive: boolean } }): Promise<number> }) {
    const [total, active] = await Promise.all([
      model.count({}),
      model.count({ where: { isActive: true } }),
    ]);
    return { total, active, inactive: total - active };
  }
}
