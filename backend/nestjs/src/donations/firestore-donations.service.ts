import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { Timestamp } from 'firebase-admin/firestore';
import { FirebaseService } from '../firebase/firebase.service';
import { CreateDonationDto } from './dto/create-donation.dto';

@Injectable()
export class FirestoreDonationsService {
  constructor(private readonly firebase: FirebaseService) {}

  async create(input: CreateDonationDto) {
    const amount = this.cents(input.amount, 'Donation amount');
    const currency = input.currency ?? 'INR';
    if (currency !== 'INR') throw new BadRequestException('Only INR is currently supported');
    if (amount <= 0n) throw new BadRequestException('Donation amount must be greater than zero');
    if (!Array.isArray(input.allocations) || input.allocations.length === 0) {
      throw new BadRequestException('Donation must be allocated to at least one cause');
    }

    const allocations = input.allocations.map((allocation) => ({
      id: randomUUID(),
      causeId: allocation.causeId,
      amount: this.cents(allocation.amount, 'Allocation amount'),
      createdAt: Timestamp.now(),
    }));

    if (allocations.some((allocation) => allocation.amount <= 0n)) {
      throw new BadRequestException('Allocation amounts must be greater than zero');
    }

    const uniqueCauseIds = new Set(allocations.map((allocation) => allocation.causeId));
    if (uniqueCauseIds.size !== allocations.length) {
      throw new BadRequestException('A cause can only appear once in a donation allocation');
    }

    const allocationTotal = allocations.reduce((sum, allocation) => sum + allocation.amount, 0n);
    if (allocationTotal !== amount) {
      throw new BadRequestException('Allocation total must equal the donation amount');
    }

    const refs = [...uniqueCauseIds].map((id) => this.firebase.db.collection('causes').doc(id));
    const donationId = randomUUID();
    const now = Timestamp.now();

    return this.firebase.db.runTransaction(async (transaction) => {
      const causes = await transaction.getAll(...refs);
      if (
        causes.length !== refs.length ||
        causes.some((snapshot) => !snapshot.exists || snapshot.data()?.isActive !== true)
      ) {
        throw new BadRequestException('Donation allocations must reference active causes');
      }

      const document = {
        id: donationId,
        amount: this.formatCents(amount),
        currency,
        status: 'PENDING',
        allocations: allocations.map((allocation) => ({
          id: allocation.id,
          causeId: allocation.causeId,
          organisationId: null,
          amount: this.formatCents(allocation.amount),
          createdAt: allocation.createdAt,
        })),
        createdAt: now,
        updatedAt: now,
      };

      transaction.set(this.firebase.db.collection('donations').doc(donationId), document);
      return {
        id: donationId,
        amount: document.amount,
        currency,
        status: document.status,
        createdAt: now.toDate(),
        updatedAt: now.toDate(),
        allocations: document.allocations.map((allocation) => ({
          ...allocation,
          createdAt: allocation.createdAt.toDate(),
        })),
      };
    });
  }

  async findOne(id: string) {
    const snapshot = await this.firebase.db.collection('donations').doc(id).get();
    if (!snapshot.exists) throw new NotFoundException(`Donation '${id}' not found`);

    const donation = snapshot.data()!;
    const allocations = Array.isArray(donation.allocations) ? donation.allocations : [];
    const ids = [...new Set(allocations.map((allocation: any) => allocation.causeId).filter(Boolean))];
    const causeSnapshots = await Promise.all(
      ids.map((causeId) => this.firebase.db.collection('causes').doc(String(causeId)).get()),
    );
    const causeById = new Map(
      causeSnapshots.filter((item) => item.exists).map((item) => [item.id, item.data()]),
    );

    return {
      ...donation,
      createdAt: this.toDate(donation.createdAt),
      updatedAt: this.toDate(donation.updatedAt),
      allocations: allocations.map((allocation: any) => ({
        ...allocation,
        createdAt: this.toDate(allocation.createdAt),
        amount: String(allocation.amount),
        cause: causeById.has(allocation.causeId)
          ? { id: allocation.causeId, slug: causeById.get(allocation.causeId)?.slug }
          : null,
        organisation: null,
      })),
    };
  }

  private cents(value: string, fieldName: string): bigint {
    const normalized = String(value).trim();
    if (!/^\d+(?:\.\d{1,2})?$/.test(normalized)) {
      throw new BadRequestException(`${fieldName} must be a valid decimal amount`);
    }
    const [whole, fraction = ''] = normalized.split('.');
    return BigInt(whole) * 100n + BigInt((fraction + '00').slice(0, 2));
  }

  private formatCents(value: bigint) {
    return `${value / 100n}.${(value % 100n).toString().padStart(2, '0')}`;
  }

  private toDate(value: unknown) {
    if (value instanceof Timestamp) return value.toDate();
    if (value instanceof Date) return value;
    return new Date(String(value));
  }
}
