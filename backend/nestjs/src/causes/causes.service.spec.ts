import { NotFoundException } from '@nestjs/common';
import { CausesService } from './causes.service';

describe('CausesService', () => {
  let service: CausesService;
  let prisma: {
    language: { findMany: jest.Mock };
    cause: { findMany: jest.Mock; findFirst: jest.Mock; findUnique: jest.Mock; create: jest.Mock };
  };
  let firestoreCauses: { findAll: jest.Mock; findOne: jest.Mock };

  beforeEach(() => {
    prisma = {
      language: { findMany: jest.fn() },
      cause: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
      },
    };
    firestoreCauses = {
      findAll: jest.fn(),
      findOne: jest.fn(),
    };

    service = new CausesService(prisma as never, firestoreCauses as never);
  });

  it('returns active causes ordered by display order', async () => {
    firestoreCauses.findAll.mockResolvedValue([
      {
        id: 'cause-1',
        slug: 'jeev-daya',
        parentId: null,
        displayOrder: 1,
        name: 'Jeev Daya',
        description: 'Animal welfare',
        children: [],
      },
    ]);

    await expect(service.findAll('en')).resolves.toEqual([
      expect.objectContaining({ id: 'cause-1', name: 'Jeev Daya' }),
    ]);
    expect(firestoreCauses.findAll).toHaveBeenCalledWith('en');
    expect(prisma.cause.findMany).not.toHaveBeenCalled();
  });

  it('prefers the requested language and falls back to English', async () => {
    prisma.cause.findMany.mockResolvedValue([
      {
        id: 'cause-1',
        slug: 'jeev-daya',
        displayOrder: 1,
        translations: [
          {
            name: 'जीव दया',
            description: 'हिंदी विवरण',
            language: { code: 'hi' },
          },
          {
            name: 'Jeev Daya',
            description: 'English description',
            language: { code: 'en' },
          },
        ],
      },
    ]);

    await expect(service.findAll('hi')).resolves.toEqual([
      expect.objectContaining({
        name: 'जीव दया',
        description: 'हिंदी विवरण',
      }),
    ]);

    prisma.cause.findMany.mockResolvedValue([
      {
        id: 'cause-1',
        slug: 'jeev-daya',
        displayOrder: 1,
        translations: [
          {
            name: 'Jeev Daya',
            description: 'English description',
            language: { code: 'en' },
          },
        ],
      },
    ]);

    await expect(service.findAll('mr')).resolves.toEqual([
      expect.objectContaining({
        name: 'Jeev Daya',
        description: 'English description',
      }),
    ]);
  });

  it('returns a cause from Firestore with translated organisation data', async () => {
    firestoreCauses.findOne.mockResolvedValue({
      id: 'cause-1',
      slug: 'jeev-daya',
      parentId: null,
      displayOrder: 1,
      name: 'जीव दया',
      description: 'हिंदी विवरण',
      children: [],
      organisations: [
        {
          id: 'org-1',
          slug: 'org-one',
          name: 'संस्था एक',
          description: 'हिंदी विवरण',
          city: 'Pune',
          latitude: 18.5204,
          longitude: 73.8567,
          logoUrl: null,
          gallery: [],
        },
      ],
    });

    await expect(service.findOne('jeev-daya', 'hi')).resolves.toEqual(
      expect.objectContaining({
        id: 'cause-1',
        name: 'जीव दया',
        organisations: [expect.objectContaining({ id: 'org-1', name: 'संस्था एक' })],
      }),
    );
    expect(firestoreCauses.findOne).toHaveBeenCalledWith('jeev-daya', 'hi');
    expect(prisma.cause.findFirst).not.toHaveBeenCalled();
  });

  it('throws not found for an inactive or unknown cause', async () => {
    firestoreCauses.findOne.mockRejectedValue(new NotFoundException(`Cause 'does-not-exist' not found`));

    await expect(service.findOne('does-not-exist')).rejects.toBeInstanceOf(NotFoundException);
  });
  it('caches cause lists and avoids repeated database reads', async () => {
    prisma.cause.findMany.mockResolvedValue([
      {
        id: 'cause-1',
        slug: 'jeev-daya',
        displayOrder: 1,
        translations: [{ name: 'Jeev Daya', description: 'Animal welfare', language: { code: 'en' } }],
      },
    ]);

    const first = await service.findAll('en');
    const second = await service.findAll('en');

    expect(second).toEqual(first);
    expect(prisma.cause.findMany).toHaveBeenCalledTimes(1);
  });

  it('invalidates the cache after a cause write', async () => {
    prisma.cause.findMany.mockResolvedValue([
      {
        id: 'cause-1',
        slug: 'jeev-daya',
        displayOrder: 1,
        translations: [{ name: 'Jeev Daya', description: 'Old', language: { code: 'en' } }],
      },
    ]);
    await service.findAll('en');

    prisma.cause.findUnique.mockResolvedValue(null);
    prisma.language.findMany.mockResolvedValue([{ id: 'lang-en', code: 'en' }]);
    prisma.cause.create.mockResolvedValue({ id: 'cause-2', translations: [] });
    await service.create({
      slug: 'new-cause',
      displayOrder: 2,
      translations: [{ languageCode: 'en', name: 'New Cause', description: 'New' }],
    } as any);

    prisma.cause.findMany.mockResolvedValue([
      {
        id: 'cause-3',
        slug: 'updated',
        displayOrder: 1,
        translations: [{ name: 'Updated', description: 'Updated', language: { code: 'en' } }],
      },
    ]);

    await service.findAll('en');
    expect(prisma.cause.findMany).toHaveBeenCalledTimes(2);
  });

});
