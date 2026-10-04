import { NotFoundException } from '@nestjs/common';
import { FirestoreCausesService } from './firestore-causes.service';

describe('FirestoreCausesService', () => {
  function makeDb(data: Record<string, any[]>) {
    const documents = new Map<string, any>(
      Object.entries(data).flatMap(([_, values]) => values.map((value) => [value.id, value])),
    );

    return {
      getAll: jest.fn((...refs: any[]) =>
        Promise.resolve(refs.map((ref) => ({
          id: ref.id,
          exists: documents.has(ref.id),
          data: () => documents.get(ref.id),
        }))),
      ),
      collection: jest.fn((name: string) => ({
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        doc: jest.fn((id: string) => ({ id })),
        get: jest.fn().mockResolvedValue({
          empty: !(data[name]?.length),
          docs: (data[name] ?? []).map((value) => ({
            id: value.id,
            data: () => value,
          })),
        }),
      })),
    };
  }

  it('reads active root causes and children from Firestore', async () => {
    const db = makeDb({
      causes: [
        {
          id: 'root',
          slug: 'education',
          parentId: null,
          isActive: true,
          displayOrder: 1,
          childIds: ['child'],
          translations: { en: { name: 'Education', description: 'Help' } },
        },
        {
          id: 'child',
          slug: 'school',
          parentId: 'root',
          isActive: true,
          displayOrder: 1,
          translations: { en: { name: 'School', description: 'School help' } },
        },
      ],
    });

    const service = new FirestoreCausesService({ db } as never);
    const result = await service.findAll('en');
    expect(result).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: 'root',
          name: 'Education',
          children: [expect.objectContaining({ id: 'child', name: 'School' })],
        }),
      ]),
    );
  });

  it('falls back to English and rejects unknown causes', async () => {
    const db = makeDb({
      causes: [
        {
          id: 'cause-1',
          slug: 'medical',
          parentId: null,
          isActive: true,
          displayOrder: 1,
          childIds: [],
          translations: { en: { name: 'Medical' } },
        },
      ],
    });

    const service = new FirestoreCausesService({ db } as never);
    await expect(service.findAll('hi')).resolves.toEqual([
      expect.objectContaining({ name: 'Medical' }),
    ]);

    db.collection.mockImplementation((name: string) => ({
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: jest.fn().mockResolvedValue({ empty: name === 'causes', docs: [] }),
    }));

    await expect(service.findOne('missing', 'en')).rejects.toBeInstanceOf(NotFoundException);
  });
});
