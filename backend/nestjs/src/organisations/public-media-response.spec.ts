import { OrganisationsService } from './organisations.service';

describe('OrganisationsService public media response', () => {
  it('prefers attached logo media and returns ordered gallery URLs', () => {
    process.env.R2_PUBLIC_BASE_URL = 'https://images.example.com/';
    const service = new OrganisationsService({} as any);
    const response = (service as any).baseResponse({
      id: '1', slug: 'org', logoUrl: 'legacy', websiteUrl: null, phone: null, mobileNumber: '+919876543210', email: null,
      address: null, city: null, state: null, country: 'IN', latitude: null, longitude: null,
      displayOrder: 0, translations: [], media: [
        { purpose: 'LOGO', isPrimary: true, displayOrder: 0, media: { id: 'logo', storageKey: 'logos/a.webp', mimeType: 'image/webp', width: 100, height: 100 } },
        { purpose: 'GALLERY', isPrimary: false, displayOrder: 2, media: { id: 'g2', storageKey: 'gallery/2.webp', mimeType: 'image/webp', width: 100, height: 100 } },
        { purpose: 'GALLERY', isPrimary: false, displayOrder: 1, media: { id: 'g1', storageKey: 'gallery/1.webp', mimeType: 'image/webp', width: 100, height: 100 } },
      ],
    }, 'en');
    expect(response.logoUrl).toBe('https://images.example.com/logos/a.webp');
    expect(response.mobileNumber).toBe('+919876543210');
    expect(response.gallery.map((x: any) => x.id)).toEqual(['g1', 'g2']);
  });
});
