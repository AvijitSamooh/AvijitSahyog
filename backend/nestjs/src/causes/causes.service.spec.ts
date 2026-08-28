import { NotFoundException } from '@nestjs/common';
import { CausesService } from './causes.service';

describe('CausesService', () => {
  let service: CausesService;
  let prisma: {
    cause: { findMany: jest.Mock; findFirst: jest.Mock };
  };

  beforeEach(() => {
    prisma = {
      cause: {
        findMany: jest.fn(),
        findFirst: jest.fn(),
      },
    };

    service = new CausesService(prisma as never);
  });

  it('returns active causes ordered by display order', async () => {
    prisma.cause.findMany.mockResolvedValue([
      {
        id: 'cause-1',
        slug: 'jeev-daya',
        displayOrder: 1,
        translations: [
          {
            name: 'Jeev Daya',
            description: 'Animal welfare',
            language: { code: 'en' },
          },
        ],
      },
    ]);

    await expect(service.findAll('en')).resolves.toEqual([
      {
        id: 'cause-1',
        slug: 'jeev-daya',
        displayOrder: 1,
        name: 'Jeev Daya',
        description: 'Animal welfare',
      },
    ]);

    expect(prisma.cause.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { isActive: true },
        orderBy: { displayOrder: 'asc' },
      }),
    );
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

  it('returns a cause with active organisations and their translations', async () => {
    prisma.cause.findFirst.mockResolvedValue({
      id: 'cause-1',
      slug: 'jeev-daya',
      displayOrder: 1,
      translations: [
        {
          name: 'जीव दया',
          description: 'हिंदी विवरण',
          language: { code: 'hi' },
        },
      ],
      organisations: [
        {
          organisation: {
            id: 'org-1',
            slug: 'org-one',
            logoUrl: null,
            websiteUrl: null,
            phone: '1234567890',
            email: 'one@example.com',
            address: 'Pune',
            city: 'Pune',
            state: 'Maharashtra',
            country: 'India',
            latitude: null,
            longitude: null,
            translations: [
              {
                name: 'संस्था एक',
                description: 'हिंदी विवरण',
                language: { code: 'hi' },
              },
            ],
          },
        },
      ],
    });

    await expect(service.findOne('jeev-daya', 'hi')).resolves.toEqual(
      expect.objectContaining({
        id: 'cause-1',
        slug: 'jeev-daya',
        name: 'जीव दया',
        organisations: [
          expect.objectContaining({
            id: 'org-1',
            name: 'संस्था एक',
            city: 'Pune',
          }),
        ],
      }),
    );

    expect(prisma.cause.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { slug: 'jeev-daya', isActive: true },
      }),
    );
  });

  it('throws not found for an inactive or unknown cause', async () => {
    prisma.cause.findFirst.mockResolvedValue(null);

    await expect(service.findOne('does-not-exist')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
