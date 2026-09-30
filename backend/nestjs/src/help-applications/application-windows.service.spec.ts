import { BadRequestException } from '@nestjs/common';
import { ApplicationWindowsService } from './application-windows.service';

describe('ApplicationWindowsService', () => {
  const prisma: any = {
    applicationWindow: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      upsert: jest.fn(),
      update: jest.fn(),
    },
    user: {
      upsert: jest.fn(),
    },
  };
  const identity = { uid: 'firebase-admin', email: 'admin@example.com', displayName: 'Admin' };

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.user.upsert.mockResolvedValue({ id: 'admin-1', role: 'ADMIN' });
  });

  it('reports scheduled, open and closed windows from the server clock', async () => {
    const now = new Date('2026-09-30T10:00:00.000Z');
    jest.useFakeTimers().setSystemTime(now);
    prisma.applicationWindow.findMany.mockResolvedValue([
      { type: 'EDUCATION_ASSISTANCE', startsAt: new Date('2026-10-01T10:00:00.000Z'), closedAt: null },
      { type: 'MEDICAL_HELP', startsAt: new Date('2026-09-30T09:00:00.000Z'), closedAt: null },
      { type: 'PRATIBHA_SAMMAN', startsAt: new Date('2026-09-01T09:00:00.000Z'), closedAt: new Date('2026-09-29T09:00:00.000Z') },
    ]);

    const service = new ApplicationWindowsService(prisma);
    const result = await service.list();

    expect(result.windows).toEqual(expect.arrayContaining([
      expect.objectContaining({ type: 'EDUCATION_ASSISTANCE', status: 'SCHEDULED', canApply: false }),
      expect.objectContaining({ type: 'MEDICAL_HELP', status: 'OPEN', canApply: true }),
      expect.objectContaining({ type: 'PRATIBHA_SAMMAN', status: 'CLOSED', canApply: false }),
    ]));
    jest.useRealTimers();
  });

  it('rejects invalid start timestamps before persistence', async () => {
    const service = new ApplicationWindowsService(prisma);
    await expect(service.start(identity, 'PRATIBHA_SAMMAN', {
      type: 'PRATIBHA_SAMMAN',
      startsAt: 'not-a-date',
    })).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.applicationWindow.upsert).not.toHaveBeenCalled();
  });

  it('starts or reschedules a window and clears a previous close', async () => {
    prisma.applicationWindow.upsert.mockResolvedValue({
      type: 'PRATIBHA_SAMMAN',
      startsAt: new Date('2026-10-01T09:00:00.000Z'),
      closedAt: null,
    });
    const service = new ApplicationWindowsService(prisma);

    await service.start(identity, 'PRATIBHA_SAMMAN', {
      type: 'PRATIBHA_SAMMAN',
      startsAt: '2026-10-01T09:00:00.000Z',
    });

    expect(prisma.applicationWindow.upsert).toHaveBeenCalledWith(expect.objectContaining({
      where: { type: 'PRATIBHA_SAMMAN' },
      update: expect.objectContaining({
        closedAt: null,
        startsAt: new Date('2026-10-01T09:00:00.000Z'),
      }),
    }));
  });

  it('closes an existing window and records the administrator', async () => {
    prisma.applicationWindow.findUnique.mockResolvedValue({
      type: 'PRATIBHA_SAMMAN',
      startsAt: new Date('2026-09-01T09:00:00.000Z'),
      closedAt: null,
    });
    prisma.applicationWindow.update.mockResolvedValue({
      type: 'PRATIBHA_SAMMAN',
      startsAt: new Date('2026-09-01T09:00:00.000Z'),
      closedAt: new Date('2026-09-30T10:00:00.000Z'),
    });

    const service = new ApplicationWindowsService(prisma);
    await service.close(identity, 'PRATIBHA_SAMMAN');

    expect(prisma.applicationWindow.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { type: 'PRATIBHA_SAMMAN' },
      data: expect.objectContaining({ updatedById: 'admin-1' }),
    }));
  });

  it('rejects submissions when no window is configured', async () => {
    prisma.applicationWindow.findUnique.mockResolvedValue(null);
    const service = new ApplicationWindowsService(prisma);

    await expect(service.ensureAccepting('PRATIBHA_SAMMAN')).rejects.toThrow(
      'Applications are not currently being accepted.',
    );
  });
});
