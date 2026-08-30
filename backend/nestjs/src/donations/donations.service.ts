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

    const cause = await this.prisma.cause.findFirst({
      where: { id: input.causeId, isActive: true },
      select: { id: true },
    });
    if (!cause) {
      throw new BadRequestException('Donation must reference an active cause');
    }

    return this.prisma.donation.create({
      data: {
        amount,
        currency,
        allocations: {
          create: [{ causeId: input.causeId, amount }],
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
      return new Prisma.Decimal(value);
    } catch {
      throw new BadRequestException(`${fieldName} must be a valid decimal amount`);
    }
  }
}
