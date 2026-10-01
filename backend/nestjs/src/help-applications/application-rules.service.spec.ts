import { BadRequestException } from '@nestjs/common';
import { ApplicationRulesService } from './application-rules.service';

describe('ApplicationRulesService', () => {
  const prisma: any = {
    applicationRule: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };

  beforeEach(() => jest.clearAllMocks());

  it('returns the requested supported language and falls back to English', async () => {
    prisma.applicationRule.findMany.mockResolvedValue([
      {
        id: 'rule-1',
        type: 'PRATIBHA_SAMMAN',
        displayOrder: 1,
        translations: [
          { text: 'Pune only', language: { code: 'en' } },
          { text: 'केवल पुणे', language: { code: 'hi' } },
          { text: 'फक्त पुणे', language: { code: 'mr' } },
          { text: 'ફક્ત પુણે', language: { code: 'gu' } },
        ],
      },
    ]);
    const service = new ApplicationRulesService(prisma);

    await expect(service.list('PRATIBHA_SAMMAN', 'en')).resolves.toEqual([
      { id: 'rule-1', type: 'PRATIBHA_SAMMAN', displayOrder: 1, text: 'Pune only' },
    ]);
    await expect(service.list('PRATIBHA_SAMMAN', 'hi')).resolves.toEqual([
      { id: 'rule-1', type: 'PRATIBHA_SAMMAN', displayOrder: 1, text: 'केवल पुणे' },
    ]);
    await expect(service.list('PRATIBHA_SAMMAN', 'mr')).resolves.toEqual([
      { id: 'rule-1', type: 'PRATIBHA_SAMMAN', displayOrder: 1, text: 'फक्त पुणे' },
    ]);
    await expect(service.list('PRATIBHA_SAMMAN', 'gu')).resolves.toEqual([
      { id: 'rule-1', type: 'PRATIBHA_SAMMAN', displayOrder: 1, text: 'ફક્ત પુણે' },
    ]);
    await expect(service.list('PRATIBHA_SAMMAN', 'ta')).resolves.toEqual([
      { id: 'rule-1', type: 'PRATIBHA_SAMMAN', displayOrder: 1, text: 'Pune only' },
    ]);
  });
  it('rejects an admin rule when any supported language is missing', async () => {
    const service = new ApplicationRulesService(prisma);

    await expect(service.create({
      type: 'PRATIBHA_SAMMAN',
      displayOrder: 1,
      translations: [
        { language: 'en', text: 'Pune only' },
        { language: 'hi', text: 'केवल पुणे' },
        { language: 'mr', text: 'फक्त पुणे' },
      ],
    })).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.applicationRule.create).not.toHaveBeenCalled();
  });

  it('updates all four translations together', async () => {
    prisma.applicationRule.findUnique.mockResolvedValue({ id: 'rule-1' });
    prisma.applicationRule.update.mockResolvedValue({ id: 'rule-1' });
    const service = new ApplicationRulesService(prisma);
    await service.update('rule-1', {
      displayOrder: 2,
      isActive: true,
      translations: [
        { language: 'en', text: 'Pune only' },
        { language: 'hi', text: 'केवल पुणे' },
        { language: 'mr', text: 'फक्त पुणे' },
        { language: 'gu', text: 'ફક્ત પુણે' },
      ],
    });

    expect(prisma.applicationRule.update).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        displayOrder: 2,
        translations: expect.objectContaining({
          deleteMany: {},
          create: expect.arrayContaining([
            { text: 'Pune only', language: { connect: { code: 'en' } } },
          ]),
        }),
      }),
    }));
  });

  it('soft-deactivates a rule instead of deleting historical references', async () => {
    prisma.applicationRule.findUnique.mockResolvedValue({ id: 'rule-1' });
    prisma.applicationRule.update.mockResolvedValue({ id: 'rule-1' });
    const service = new ApplicationRulesService(prisma);

    await expect(service.remove('rule-1')).resolves.toEqual({ id: 'rule-1', deleted: true });
    expect(prisma.applicationRule.update).toHaveBeenCalledWith({
      where: { id: 'rule-1' },
      data: { isActive: false },
    });
  });
  it('caches rule descriptions and invalidates after an admin write', async () => {
    prisma.applicationRule.findMany.mockResolvedValue([
      {
        id: 'rule-1',
        type: 'PRATIBHA_SAMMAN',
        displayOrder: 1,
        translations: [{ text: 'Pune only', language: { code: 'en' } }],
      },
    ]);
    const service = new ApplicationRulesService(prisma);

    await service.list('PRATIBHA_SAMMAN', 'en');
    await service.list('PRATIBHA_SAMMAN', 'en');
    expect(prisma.applicationRule.findMany).toHaveBeenCalledTimes(1);

    prisma.applicationRule.findUnique.mockResolvedValue({ id: 'rule-1' });
    prisma.applicationRule.update.mockResolvedValue({ id: 'rule-1' });
    await service.remove('rule-1');

    await service.list('PRATIBHA_SAMMAN', 'en');
    expect(prisma.applicationRule.findMany).toHaveBeenCalledTimes(2);
  });
});
