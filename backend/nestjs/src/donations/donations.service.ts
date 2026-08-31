import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Decimal } from '@prisma/client/runtime/library';
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
    if (!Array.isArray(input.allocations) || input.allocations.length === 0) {
      throw new BadRequestException('Donation must be allocated to at least one cause');
    }

    const allocationAmounts = input.allocations.map((allocation) =>
      this.decimal(allocation.amount, 'Allocation amount'),
    );
    if (allocationAmounts.some((allocationAmount) => allocationAmount.lte(0))) {
      throw new BadRequestException('Allocation amounts must be greater than zero');
    }

    const uniqueCauseIds = new Set(input.allocations.map((allocation) => allocation.causeId));
    if (uniqueCauseIds.size !== input.allocations.length) {
      throw new BadRequestException('A cause can only appear once in a donation allocation');
    }

    const allocationTotal = allocationAmounts.reduce(
      (total, allocationAmount) => total.plus(allocationAmount),
      new Decimal(0),
    );
    if (!allocationTotal.equals(amount)) {
      throw new BadRequestException('Allocation total must equal the donation amount');
    }

    const activeCauseCount = await this.prisma.cause.count({
      where: { id: { in: [...uniqueCauseIds] }, isActive: true },
    });
    if (activeCauseCount !== uniqueCauseIds.size) {
      throw new BadRequestException('Donation allocations must reference active causes');
    }

    return this.prisma.donation.create({
      data: {
        amount,
        currency,
        allocations: {
          create: input.allocations.map((allocation, index) => ({
            causeId: allocation.causeId,
            amount: allocationAmounts[index],
          })),
        },
      },
      include: { allocations: true },
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
      return new Decimal(value);
    } catch {
      throw new BadRequestException(`${fieldName} must be a valid decimal amount`);
    }
  }
}
