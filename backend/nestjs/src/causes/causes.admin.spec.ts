import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';

import { CausesService } from './causes.service';

describe('CausesService admin operations', () => {
  let service: CausesService;
  let prisma: any;

  beforeEach(() => {
    prisma = {
      cause: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      language: {
        findMany: jest.fn(),
      },
      $transaction: jest.fn(),
    };
    service = new CausesService(prisma);
  });

  it('creates a cause with translations for active languages', async () => {
    prisma.cause.findUnique.mockResolvedValue(null);
    prisma.language.findMany.mockResolvedValue([
      { id: 'lang-en', code: 'en' },
      { id: 'lang-hi', code: 'hi' },
    ]);
    prisma.cause.create.mockResolvedValue({ id: 'cause-1', slug: 'new-cause' });

    await expect(
      service.create({
        slug: 'new-cause',
        displayOrder: 5,
        translations: [
          { languageCode: 'en', name: 'New Cause' },
          { languageCode: 'hi', name: 'नया कारण' },
        ],
      }),
    ).resolves.toEqual({ id: 'cause-1', slug: 'new-cause' });

    expect(prisma.cause.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          slug: 'new-cause',
          displayOrder: 5,
          translations: expect.objectContaining({
            create: expect.arrayContaining([
              expect.objectContaining({ languageId: 'lang-en', name: 'New Cause' }),
              expect.objectContaining({ languageId: 'lang-hi' }),
            ]),
          }),
        }),
      }),
    );
  });

  it('rejects duplicate translation languages', async () => {
    await expect(
      service.create({
        slug: 'new-cause',
        translations: [
          { languageCode: 'en', name: 'One' },
          { languageCode: 'en', name: 'Duplicate' },
        ],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects unavailable translation languages', async () => {
    prisma.cause.findUnique.mockResolvedValue(null);
    prisma.language.findMany.mockResolvedValue([{ id: 'lang-en', code: 'en' }]);

    await expect(
      service.create({
        slug: 'new-cause',
        translations: [
          { languageCode: 'en', name: 'One' },
          { languageCode: 'gu', name: 'Two' },
        ],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects duplicate cause slugs', async () => {
    prisma.cause.findUnique.mockResolvedValue({ id: 'existing' });

    await expect(
      service.create({
        slug: 'existing',
        translations: [{ languageCode: 'en', name: 'Existing' }],
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('throws when an admin operation targets an unknown cause', async () => {
    prisma.cause.findUnique.mockResolvedValue(null);

    await expect(service.setActive('missing', false)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('updates translations and cause state atomically', async () => {
    prisma.cause.findUnique
      .mockResolvedValueOnce({ id: 'cause-1' })
      .mockResolvedValueOnce(null);
    prisma.language.findMany.mockResolvedValue([{ id: 'lang-en', code: 'en' }]);

    const tx = {
      language: {
        findMany: jest.fn().mockResolvedValue([{ id: 'lang-en', code: 'en' }]),
      },
      causeTranslation: {
        upsert: jest.fn().mockResolvedValue({}),
      },
      cause: {
        update: jest.fn().mockResolvedValue({ id: 'cause-1', isActive: false }),
      },
    };
    prisma.$transaction.mockImplementation((callback: any) => callback(tx));

    await expect(
      service.update('cause-1', {
        isActive: false,
        translations: [{ languageCode: 'en', name: 'Updated' }],
      }),
    ).resolves.toEqual({ id: 'cause-1', isActive: false });

    expect(tx.causeTranslation.upsert).toHaveBeenCalled();
    expect(tx.cause.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { isActive: false } }),
    );
  });
});
