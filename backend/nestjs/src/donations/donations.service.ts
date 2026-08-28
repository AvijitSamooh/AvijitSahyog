import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateDonationDto } from './dto/create-donation.dto';

@Injectable()
export class DonationsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(input: CreateDonationDto) {
    const amount = this.decimal(input.amount, 'Donation amount');
    const currency = input.currency ?? 'INR';

    if (currency !== 'INR') {
      throw new BadRequestException('Only INR is currently supported');
    }

    if (amount.lte(0)) {
      throw new BadRequestException('Donation amount must be greater than zero');
    }

    if (!input.allocations?.length) {
      throw new BadRequestException('At least one donation allocation is required');
    }

    const allocations = input.allocations.map((allocation) => ({
      causeId: allocation.causeId,
      organisationId: allocation.organisationId,
      amount: this.decimal(allocation.amount, 'Allocation amount'),
    }));

    if (allocations.some((allocation) => allocation.amount.lte(0))) {
      throw new BadRequestException('Allocation amounts must be greater than zero');
    }

    const allocationTotal = allocations.reduce(
      (total, allocation) => total.plus(allocation.amount),
      new Prisma.Decimal(0),
    );

    if (!allocationTotal.equals(amount)) {
      throw new BadRequestException(
        'Donation amount must equal the sum of its allocations',
      );
    }

    const organisationCausePairs = allocations.map((allocation) => ({
      causeId: allocation.causeId,
      organisationId: allocation.organisationId,
    }));

    const validRelationships = await this.prisma.organisationCause.findMany({
      where: {
        isActive: true,
        OR: organisationCausePairs,
        cause: { isActive: true },
        organisation: { isActive: true },
      },
      select: {
        causeId: true,
        organisationId: true,
      },
    });

    const validRelationshipKeys = new Set(
      validRelationships.map(
        (relationship) => `${relationship.causeId}:${relationship.organisationId}`,
      ),
    );

    const invalidAllocation = allocations.find(
      (allocation) =>
        !validRelationshipKeys.has(
          `${allocation.causeId}:${allocation.organisationId}`,
        ),
    );

    if (invalidAllocation) {
      throw new BadRequestException(
        'Each allocation must reference an active cause-organisation relationship',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const donation = await tx.donation.create({
        data: {
          amount,
          currency,
          allocations: {
            create: allocations,
          },
        },
        include: {
          allocations: true,
        },
      });

      return donation;
    });
  }

  async findOne(id: string) {
    const donation = await this.prisma.donation.findUnique({
      where: { id },
      include: {
        allocations: {
          include: {
            cause: true,
            organisation: true,
          },
        },
      },
    });

    if (!donation) {
      throw new NotFoundException(`Donation '${id}' not found`);
    }

    return donation;
  }

  private decimal(value: string, fieldName: string) {
    try {
      return new Prisma.Decimal(value);
    } catch {
      throw new BadRequestException(`${fieldName} must be a valid decimal amount`);
    }
  }
}
