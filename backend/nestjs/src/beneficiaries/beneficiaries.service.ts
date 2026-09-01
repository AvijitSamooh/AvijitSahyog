import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { CreateBeneficiaryDto } from './dto/create-beneficiary.dto';
import type { UpdateBeneficiaryDto } from './dto/update-beneficiary.dto';

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

  async findAllForAdmin() {
    return this.prisma.beneficiary.findMany({
      orderBy: [{ supportedYear: 'desc' }, { displayOrder: 'asc' }],
      include: { cause: { select: { id: true, slug: true } }, organisation: { select: { id: true, slug: true } } },
    });
  }

  async findOneForAdmin(id: string) {
    const beneficiary = await this.prisma.beneficiary.findUnique({
      where: { id },
      include: { cause: { select: { id: true, slug: true } }, organisation: { select: { id: true, slug: true } } },
    });
    if (!beneficiary) throw new NotFoundException(`Beneficiary '${id}' not found`);
    return beneficiary;
  }

  async create(dto: CreateBeneficiaryDto) {
    this.validate(dto);
    await this.validateRelationships(dto.causeId, dto.organisationId);
    return this.prisma.beneficiary.create({
      data: {
        name: dto.name.trim(),
        photoUrl: dto.photoUrl,
        story: dto.story,
        supportedYear: dto.supportedYear,
        contributionAmount: dto.contributionAmount,
        causeId: dto.causeId,
        organisationId: dto.organisationId,
        displayOrder: dto.displayOrder ?? 0,
      },
      include: { cause: { select: { id: true, slug: true } }, organisation: { select: { id: true, slug: true } } },
    });
  }

  async update(id: string, dto: UpdateBeneficiaryDto) {
    await this.findOneForAdmin(id);
    this.validate(dto, true);
    if (dto.causeId !== undefined || dto.organisationId !== undefined) {
      const existing = await this.findOneForAdmin(id);
      await this.validateRelationships(
        dto.causeId ?? existing.causeId,
        dto.organisationId === undefined
            ? existing.organisationId
            : dto.organisationId,
      );
    }
    return this.prisma.beneficiary.update({
      where: { id },
      data: {
        ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
        ...(dto.photoUrl !== undefined ? { photoUrl: dto.photoUrl } : {}),
        ...(dto.story !== undefined ? { story: dto.story } : {}),
        ...(dto.supportedYear !== undefined ? { supportedYear: dto.supportedYear } : {}),
        ...(dto.contributionAmount !== undefined ? { contributionAmount: dto.contributionAmount } : {}),
        ...(dto.causeId !== undefined ? { causeId: dto.causeId } : {}),
        ...(dto.organisationId !== undefined ? { organisationId: dto.organisationId } : {}),
        ...(dto.displayOrder !== undefined ? { displayOrder: dto.displayOrder } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
      include: { cause: { select: { id: true, slug: true } }, organisation: { select: { id: true, slug: true } } },
    });
  }

  async setActive(id: string, isActive: boolean) {
    await this.findOneForAdmin(id);
    return this.prisma.beneficiary.update({ where: { id }, data: { isActive } });
  }

  private validate(dto: CreateBeneficiaryDto | UpdateBeneficiaryDto, partial = false) {
    if (!partial && !dto.name?.trim()) throw new BadRequestException('Beneficiary name is required.');
    if (dto.name !== undefined && !dto.name.trim()) throw new BadRequestException('Beneficiary name is required.');
    if (!partial && (!Number.isInteger(dto.supportedYear) || (dto.supportedYear ?? 0) < 1900)) {
      throw new BadRequestException('A valid supported year is required.');
    }
    if (dto.supportedYear !== undefined && (!Number.isInteger(dto.supportedYear) || dto.supportedYear < 1900)) {
      throw new BadRequestException('Supported year must be valid.');
    }
    if (!partial && (!((dto.contributionAmount ?? 0) > 0))) throw new BadRequestException('Contribution amount must be greater than zero.');
    if (dto.contributionAmount !== undefined && !(dto.contributionAmount > 0)) throw new BadRequestException('Contribution amount must be greater than zero.');
    if (!partial && !dto.causeId) throw new BadRequestException('Cause is required.');
  }

  private async validateRelationships(causeId?: string, organisationId?: string | null) {
    if (causeId) {
      const cause = await this.prisma.cause.findUnique({ where: { id: causeId }, select: { id: true } });
      if (!cause) throw new BadRequestException('Selected cause does not exist.');
    }
    if (organisationId) {
      const organisation = await this.prisma.organisation.findUnique({ where: { id: organisationId }, select: { id: true } });
      if (!organisation) throw new BadRequestException('Selected organisation does not exist.');
    }
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
