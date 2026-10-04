import { NotFoundException } from '@nestjs/common';
import { FirestoreOrganisationsService } from './firestore-organisations.service';

describe('FirestoreOrganisationsService', () => {
  const get = jest.fn();
  const collection = jest.fn();
  const firebase = {
    db: {
      collection,
      getAll: jest.fn(),
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
    collection.mockImplementation((name: string) => ({
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get,
      doc: jest.fn((id: string) => ({ id })),
    }));
    firebase.db.getAll.mockResolvedValue([]);
  });

  it('reads active organisations from Firestore and preserves cause order', async () => {
    const org = {
      id: 'org-1',
      slug: 'help',
      isActive: true,
      displayOrder: 2,
      translations: { en: { name: 'Help', description: 'Support' } },
      causeIds: ['cause-2', 'cause-1'],
      media: [],
    };
    get.mockResolvedValueOnce({ docs: [{ data: () => org }] });
    firebase.db.getAll.mockResolvedValueOnce([
      { id: 'cause-2', exists: true, data: () => ({ id: 'cause-2', slug: 'b', isActive: true, displayOrder: 2, translations: { en: { name: 'B' } } }) },
      { id: 'cause-1', exists: true, data: () => ({ id: 'cause-1', slug: 'a', isActive: true, displayOrder: 1, translations: { en: { name: 'A' } } }) },
    ]);

    await expect(new FirestoreOrganisationsService(firebase as never).findAll('en')).resolves.toEqual([expect.objectContaining({
      id: 'org-1',
      name: 'Help',
      causes: [
        expect.objectContaining({ id: 'cause-1', name: 'A' }),
        expect.objectContaining({ id: 'cause-2', name: 'B' }),
      ],
    })]);
  });

  it('throws when the requested organisation does not exist', async () => {
    get.mockResolvedValue({ empty: true, docs: [] });
    await expect(new FirestoreOrganisationsService(firebase as never).findOne('missing', 'en')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('falls back to English translations', async () => {
    const org = {
      id: 'org-1',
      slug: 'help',
      isActive: true,
      displayOrder: 1,
      translations: { en: { name: 'Help' } },
      causeIds: [],
      media: [],
    };
    get.mockResolvedValue({ docs: [{ data: () => org }] });
    await expect(new FirestoreOrganisationsService(firebase as never).findOne('help', 'hi')).resolves.toEqual(
      expect.objectContaining({ name: 'Help' }),
    );
  });
  it('covers remaining organisation media helpers', async () => { const s:any=new FirestoreOrganisationsService({db:{getAll:jest.fn().mockResolvedValue([])}} as any); process.env.R2_PUBLIC_BASE_URL='https://cdn/'; expect(s.mediaUrl({storageKey:'x'})).toBe('https://cdn/x'); expect(s.translation(undefined,'en')).toEqual({name:null,description:null}); expect(s.primaryMediaUrl([],'LOGO')).toBeNull(); expect(s.galleryMedia([],'GALLERY')).toEqual([]); await expect(s.getByIds('media',[])).resolves.toEqual([]); });

});
