import { BeneficiariesService } from './beneficiaries.service';

describe('BeneficiariesService public media response', () => {
  it('returns profile image and ordered gallery with public URLs', () => {
    process.env.R2_PUBLIC_BASE_URL = 'https://images.example.com';
    const service = new BeneficiariesService({} as any);
    const response = (service as any).toResponse({
      id: '1', name: 'A', photoUrl: 'legacy', story: null, supportedYear: 2026,
      contributionAmount: 100, cause: { id: 'c', slug: 'c' }, organisation: null,
      media: [
        { purpose: 'PROFILE', isPrimary: true, displayOrder: 0, media: { id: 'p', storageKey: 'p.webp', mimeType: 'image/webp', width: 1, height: 1 } },
        { purpose: 'GALLERY', displayOrder: 1, media: { id: 'g', storageKey: 'g.webp', mimeType: 'image/webp', width: 1, height: 1 } },
      ],
    });
    expect(response.photoUrl).toBe('https://images.example.com/p.webp');
    expect(response.profileImage.id).toBe('p');
    expect(response.gallery).toHaveLength(1);
  });
});
