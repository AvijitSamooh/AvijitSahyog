import { BadRequestException, NotFoundException } from '@nestjs/common';
import { HelpApplicationsService } from './help-applications.service';

describe('HelpApplicationsService applicant actions', () => {
  const prisma: any = {
    user: { upsert: jest.fn() },
    helpApplication: {
      findFirst: jest.fn(),
      delete: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  };
  const identity = { uid: 'firebase-1', email: 'user@example.com', displayName: 'User' };

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.user.upsert.mockResolvedValue({ id: 'user-1', role: 'USER' });
  });

  it('does not allow deleting another applicant application', async () => {
    prisma.helpApplication.findFirst.mockResolvedValue(null);
    const service = new HelpApplicationsService(prisma);
    await expect(service.deleteMine(identity, 'other-app')).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.helpApplication.delete).not.toHaveBeenCalled();
  });

  it('does not allow deleting a finalised application', async () => {
    prisma.helpApplication.findFirst.mockResolvedValue({ id: 'app-1', status: 'CONSIDERED_FOR_SAMMAN' });
    const service = new HelpApplicationsService(prisma);
    await expect(service.deleteMine(identity, 'app-1')).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.helpApplication.delete).not.toHaveBeenCalled();
  });

  it('maps both Pratibha Samman review outcomes to their persisted statuses', async () => {
    prisma.helpApplication.findUnique.mockResolvedValue({ id: 'app-1', type: 'PRATIBHA_SAMMAN', requestedAmount: null, media: [] });
    prisma.helpApplication.update.mockResolvedValue({ id: 'app-1', type: 'PRATIBHA_SAMMAN', media: [], votes: [] });
    const service = new HelpApplicationsService(prisma);

    await service.review('app-1', { decision: 'CONSIDER_FOR_SAMMAN' });
    expect(prisma.helpApplication.update).toHaveBeenLastCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status: 'CONSIDERED_FOR_SAMMAN' }),
    }));

    await service.review('app-1', { decision: 'NOT_SELECTED' });
    expect(prisma.helpApplication.update).toHaveBeenLastCalledWith(expect.objectContaining({
      data: expect.objectContaining({ status: 'NOT_SELECTED' }),
    }));
  });
});
