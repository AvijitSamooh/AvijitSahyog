import { BadRequestException } from '@nestjs/common';
import { PlatformDowntimeService } from './platform-downtime.service';

describe('PlatformDowntimeService', () => {
  const get = jest.fn();
  const set = jest.fn();
  const firebase = {
    db: {
      collection: jest.fn(() => ({
        doc: jest.fn(() => ({ get, set })),
      })),
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('returns safe defaults when no setting exists', async () => {
    get.mockResolvedValue({ exists: false });
    await expect(new PlatformDowntimeService(firebase as never).get()).resolves.toEqual({
      enabled: false,
      startTime: '21:00',
      endTime: '08:00',
      message: null,
      updatedAt: null,
    });
  });

  it('persists and returns the configured downtime', async () => {
    get
      .mockResolvedValueOnce({ exists: false })
      .mockResolvedValueOnce({
        exists: true,
        data: () => ({
          enabled: true,
          startTime: '22:15',
          endTime: '06:30',
          message: 'Nightly maintenance',
          updatedAt: { toDate: () => new Date('2026-10-04T16:00:00Z') },
        }),
      });
    set.mockResolvedValue(undefined);

    const service = new PlatformDowntimeService(firebase as never);
    await expect(service.update({
      enabled: true,
      startTime: '22:15',
      endTime: '06:30',
      message: 'Nightly maintenance',
    })).resolves.toMatchObject({
      enabled: true,
      startTime: '22:15',
      endTime: '06:30',
      message: 'Nightly maintenance',
    });
    expect(set).toHaveBeenCalledWith(expect.objectContaining({ enabled: true }), { merge: true });
  });

  it('rejects invalid clock values', async () => {
    get.mockResolvedValue({ exists: false });
    await expect(new PlatformDowntimeService(firebase as never).update({
      startTime: '25:90',
    })).rejects.toBeInstanceOf(BadRequestException);
  });
});
