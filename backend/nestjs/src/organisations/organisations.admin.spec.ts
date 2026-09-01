import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';

import { OrganisationsService } from './organisations.service';

describe('OrganisationsService admin operations', () => {
  let service: OrganisationsService;
  let prisma: any;

  beforeEach(() => {
    prisma = {
      organisation: {
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      language: { findMany: jest.fn() },
      cause: { findMany: jest.fn() },
      $transaction: jest.fn(),
    };
    service = new OrganisationsService(prisma);
  });

  it('creates an organisation with validated translations', async () => {
    prisma.organisation.findUnique.mockResolvedValue(null);
    prisma.language.findMany.mockResolvedValue([
      { id: 'en-id', code: 'en' },
      { id: 'hi-id', code: 'hi' },
    ]);
    prisma.organisation.create.mockResolvedValue({
      id: 'org-1',
      slug: 'help-foundation',
    });

    await expect(
      service.create({
        slug: 'help-foundation',
        email: 'contact@example.org',
        translations: [
          { languageCode: 'en', name: 'Help Foundation' },
          { languageCode: 'hi', name: 'सहायता फाउंडेशन' },
        ],
      }),
    ).resolves.toEqual({ id: 'org-1', slug: 'help-foundation' });
  });

  it('rejects duplicate translation languages', async () => {
    await expect(
      service.create({
        slug: 'duplicate-language',
        translations: [
          { languageCode: 'en', name: 'One' },
          { languageCode: 'en', name: 'Two' },
        ],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects unavailable languages', async () => {
    prisma.organisation.findUnique.mockResolvedValue(null);
    prisma.language.findMany.mockResolvedValue([{ id: 'en-id', code: 'en' }]);

    await expect(
      service.create({
        slug: 'invalid-language',
        translations: [
          { languageCode: 'en', name: 'One' },
          { languageCode: 'gu', name: 'Two' },
        ],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects duplicate organisation slugs', async () => {
    prisma.organisation.findUnique.mockResolvedValue({ id: 'existing' });

    await expect(
      service.create({
        slug: 'existing',
        translations: [{ languageCode: 'en', name: 'Existing' }],
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('rejects status updates for an unknown organisation', async () => {
    prisma.organisation.findUnique.mockResolvedValue(null);

    await expect(service.setActive('missing', false)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('updates translations and metadata atomically', async () => {
    prisma.organisation.findUnique
      .mockResolvedValueOnce({ id: 'org-1' })
      .mockResolvedValueOnce(null);
    prisma.language.findMany.mockResolvedValue([{ id: 'en-id', code: 'en' }]);

    const tx = {
      language: {
        findMany: jest.fn().mockResolvedValue([{ id: 'en-id', code: 'en' }]),
      },
      organisationTranslation: { upsert: jest.fn().mockResolvedValue({}) },
      organisation: {
        update: jest.fn().mockResolvedValue({ id: 'org-1', city: 'Pune' }),
      },
    };
    prisma.$transaction.mockImplementation((callback: any) => callback(tx));

    await expect(
      service.update('org-1', {
        city: 'Pune',
        translations: [{ languageCode: 'en', name: 'Updated Organisation' }],
      }),
    ).resolves.toEqual({ id: 'org-1', city: 'Pune' });

    expect(tx.organisationTranslation.upsert).toHaveBeenCalledTimes(1);
    expect(tx.organisation.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ city: 'Pune' }) }),
    );
  });
  it('replaces organisation cause assignments atomically', async () => {
    prisma.organisation.findUnique.mockResolvedValue({ id: 'org-1' });
    prisma.cause.findMany.mockResolvedValue([{ id: 'cause-1' }, { id: 'cause-2' }]);
    const tx = {
      organisationCause: {
        deleteMany: jest.fn(),
        createMany: jest.fn(),
      },
      organisation: { findUnique: jest.fn().mockResolvedValue({ id: 'org-1' }) },
    };
    prisma.$transaction.mockImplementation((callback: any) => callback(tx));

    await service.updateCauses('org-1', ['cause-1', 'cause-2']);

    expect(tx.organisationCause.deleteMany).toHaveBeenCalledWith({
      where: { organisationId: 'org-1' },
    });
    expect(tx.organisationCause.createMany).toHaveBeenCalledWith({
      data: [
        { organisationId: 'org-1', causeId: 'cause-1', displayOrder: 0 },
        { organisationId: 'org-1', causeId: 'cause-2', displayOrder: 1 },
      ],
    });
  });

  it('rejects duplicate cause assignments', async () => {
    prisma.organisation.findUnique.mockResolvedValue({ id: 'org-1' });

    await expect(
      service.updateCauses('org-1', ['cause-1', 'cause-1']),
    ).rejects.toBeInstanceOf(BadRequestException);
  });


});
