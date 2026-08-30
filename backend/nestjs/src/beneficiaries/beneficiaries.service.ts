import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type Query = { causeId?: string; year?: number; search?: string; sort?: string };

@Injectable()
export class BeneficiariesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: Query) {
    const orderBy = this.orderBy(query.sort);
    const beneficiaries = await this.prisma.beneficiary.findMany({
      where: {
        isActive: true,
        ...(query.causeId ? { causeId: query.causeId } : {}),
        ...(query.year ? { supportedYear: query.year } : {}),
        ...(query.search ? { name: { contains: query.search, mode: 'insensitive' } } : {}),
      },
      orderBy,
      include: { cause: true, organisation: true },
    });
    return beneficiaries.map((item) => this.toResponse(item));
  }

  async findOne(id: string) {
    const beneficiary = await this.prisma.beneficiary.findFirst({
      where: { id, isActive: true },
      include: { cause: true, organisation: true },
    });
    if (!beneficiary) throw new NotFoundException(`Beneficiary '${id}' not found`);
    return this.toResponse(beneficiary);
  }

  private orderBy(sort?: string) {
    switch (sort) {
      case 'name_asc': return { name: 'asc' as const };
      case 'amount_desc': return { contributionAmount: 'desc' as const };
      case 'amount_asc': return { contributionAmount: 'asc' as const };
      case 'year_asc': return { supportedYear: 'asc' as const };
      default: return [{ supportedYear: 'desc' as const }, { displayOrder: 'asc' as const }];
    }
  }

  private toResponse(item: any) {
    return {
      id: item.id,
      name: item.name,
      photoUrl: item.photoUrl,
      story: item.story,
      supportedYear: item.supportedYear,
      contributionAmount: item.contributionAmount,
      cause: { id: item.cause.id, slug: item.cause.slug },
      organisation: item.organisation ? { id: item.organisation.id, slug: item.organisation.slug } : null,
    };
  }
}
