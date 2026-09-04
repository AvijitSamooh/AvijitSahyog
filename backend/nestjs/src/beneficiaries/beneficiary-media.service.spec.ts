import { NotFoundException } from '@nestjs/common';
import { BeneficiariesService } from './beneficiaries.service';

describe('BeneficiariesService media management', () => {
  const tx = {
    beneficiaryMedia: { updateMany: jest.fn(), create: jest.fn(), update: jest.fn() },
  };
  const prisma = {
    beneficiary: { findUnique: jest.fn() },
    media: { findUnique: jest.fn() },
    beneficiaryMedia: { findMany: jest.fn(), findUnique: jest.fn(), delete: jest.fn() },
    $transaction: jest.fn((callback: any) => callback(tx)),
  } as any;
  const service = new BeneficiariesService(prisma);

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.beneficiary.findUnique.mockResolvedValue({ id: 'beneficiary-1' });
  });

  it('attaches a profile image and clears the previous primary profile image', async () => {
    prisma.media.findUnique.mockResolvedValue({ id: 'media-1' });
    prisma.beneficiaryMedia.findUnique.mockResolvedValue(null);
    tx.beneficiaryMedia.create.mockResolvedValue({ id: 'relation-1' });

    await service.attachMedia('beneficiary-1', { mediaId: 'media-1', purpose: 'PROFILE', isPrimary: true });

    expect(tx.beneficiaryMedia.updateMany).toHaveBeenCalledWith({
      where: { beneficiaryId: 'beneficiary-1', purpose: 'PROFILE', isPrimary: true },
      data: { isPrimary: false },
    });
  });

  it('rejects media that is not attached during update', async () => {
    prisma.beneficiaryMedia.findUnique.mockResolvedValue(null);
    await expect(service.updateMedia('beneficiary-1', 'media-1', { isPrimary: true })).rejects.toBeInstanceOf(NotFoundException);
  });

  it('removes only the association', async () => {
    prisma.beneficiaryMedia.findUnique.mockResolvedValue({ id: 'relation-1' });
    await service.removeMedia('beneficiary-1', 'media-1');
    expect(prisma.beneficiaryMedia.delete).toHaveBeenCalled();
  });
});
