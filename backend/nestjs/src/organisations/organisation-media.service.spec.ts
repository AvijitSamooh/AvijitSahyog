import { ConflictException, NotFoundException } from '@nestjs/common';
import { OrganisationsService } from './organisations.service';

describe('OrganisationsService media management', () => {
  const tx = {
    organisationMedia: { updateMany: jest.fn(), create: jest.fn(), update: jest.fn() },
  };
  const prisma = {
    organisation: { findUnique: jest.fn() },
    media: { findUnique: jest.fn() },
    organisationMedia: { findMany: jest.fn(), findUnique: jest.fn(), delete: jest.fn() },
    $transaction: jest.fn((callback: any) => callback(tx)),
  } as any;
  const service = new OrganisationsService(prisma);

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.organisation.findUnique.mockResolvedValue({ id: 'org-1' });
  });

  it('attaches media and clears an existing primary image for the same purpose', async () => {
    prisma.media.findUnique.mockResolvedValue({ id: 'media-1' });
    prisma.organisationMedia.findUnique.mockResolvedValue(null);
    tx.organisationMedia.create.mockResolvedValue({ id: 'relation-1' });

    await service.attachMedia('org-1', { mediaId: 'media-1', purpose: 'GALLERY', isPrimary: true });

    expect(tx.organisationMedia.updateMany).toHaveBeenCalledWith({
      where: { organisationId: 'org-1', purpose: 'GALLERY', isPrimary: true },
      data: { isPrimary: false },
    });
    expect(tx.organisationMedia.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ organisationId: 'org-1', mediaId: 'media-1', isPrimary: true }),
    }));
  });

  it('rejects duplicate media attachment', async () => {
    prisma.media.findUnique.mockResolvedValue({ id: 'media-1' });
    prisma.organisationMedia.findUnique.mockResolvedValue({ id: 'relation-1' });

    await expect(service.attachMedia('org-1', { mediaId: 'media-1' })).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects an unknown media record', async () => {
    prisma.media.findUnique.mockResolvedValue(null);
    await expect(service.attachMedia('org-1', { mediaId: 'missing' })).rejects.toBeInstanceOf(NotFoundException);
  });

  it('removes only the association and not the underlying media record', async () => {
    prisma.organisationMedia.findUnique.mockResolvedValue({ id: 'relation-1' });
    prisma.organisationMedia.delete.mockResolvedValue({ id: 'relation-1' });

    await service.removeMedia('org-1', 'media-1');

    expect(prisma.organisationMedia.delete).toHaveBeenCalled();
    expect(prisma.media.delete).toBeUndefined();
  });
});
