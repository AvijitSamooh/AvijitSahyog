import { CausesService } from './causes.service';

describe('CausesService organisation gallery response', () => {
  it('returns the organisation logo and ordered gallery media as public URLs', async () => {
    const prisma = {
      cause: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'cause-1',
          slug: 'education',
          displayOrder: 1,
          translations: [
            { name: 'Education', description: 'Support education.', language: { code: 'en' } },
          ],
          organisations: [
            {
              organisation: {
                id: 'org-1',
                slug: 'seva-trust',
                logoUrl: null,
                websiteUrl: null,
                phone: null,
                email: null,
                address: null,
                city: 'Pune',
                state: 'Maharashtra',
                country: 'IN',
                latitude: null,
                longitude: null,
                translations: [
                  { name: 'Seva Trust', description: 'Serving the community.', language: { code: 'en' } },
                ],
                media: [
                  {
                    purpose: 'GALLERY',
                    isPrimary: false,
                    displayOrder: 2,
                    media: { id: 'gallery-2', storageKey: 'org/two.webp', mimeType: 'image/webp', width: 200, height: 200 },
                  },
                  {
                    purpose: 'LOGO',
                    isPrimary: true,
                    displayOrder: 0,
                    media: { id: 'logo-1', storageKey: 'org/logo.webp', mimeType: 'image/webp', width: 200, height: 200 },
                  },
                  {
                    purpose: 'GALLERY',
                    isPrimary: false,
                    displayOrder: 1,
                    media: { id: 'gallery-1', storageKey: 'org/one.webp', mimeType: 'image/webp', width: 100, height: 100 },
                  },
                ],
              },
            },
          ],
        }),
      },
    };

    const service = new CausesService(prisma as never);
    const originalBase = process.env.R2_PUBLIC_BASE_URL;
    process.env.R2_PUBLIC_BASE_URL = 'https://images.example.com';

    await expect(service.findOne('education', 'en')).resolves.toEqual(
      expect.objectContaining({
        organisations: [
          expect.objectContaining({
            logoUrl: 'https://images.example.com/org/logo.webp',
            gallery: [
              expect.objectContaining({ id: 'gallery-1', url: 'https://images.example.com/org/one.webp' }),
              expect.objectContaining({ id: 'gallery-2', url: 'https://images.example.com/org/two.webp' }),
            ],
          }),
        ],
      }),
    );

    process.env.R2_PUBLIC_BASE_URL = originalBase;
  });
});
