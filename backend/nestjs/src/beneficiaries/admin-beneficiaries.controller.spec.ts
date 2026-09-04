import { AdminBeneficiariesController } from './admin-beneficiaries.controller';

describe('AdminBeneficiariesController media endpoints', () => {
  const service = {
    listMedia: jest.fn(),
    attachMedia: jest.fn(),
    updateMedia: jest.fn(),
    removeMedia: jest.fn(),
  };
  const controller = new AdminBeneficiariesController(service as never);

  beforeEach(() => jest.clearAllMocks());

  it('delegates listing media', async () => {
    service.listMedia.mockResolvedValue([]);
    await controller.listMedia('beneficiary-1');
    expect(service.listMedia).toHaveBeenCalledWith('beneficiary-1');
  });

  it('delegates attaching media', async () => {
    const dto = { mediaId: 'media-1', purpose: 'PROFILE' as const };
    service.attachMedia.mockResolvedValue({ id: 'relation-1' });
    await expect(controller.attachMedia('beneficiary-1', dto)).resolves.toEqual({ id: 'relation-1' });
    expect(service.attachMedia).toHaveBeenCalledWith('beneficiary-1', dto);
  });

  it('delegates updating and removing media', async () => {
    const dto = { displayOrder: 2 };
    await controller.updateMedia('beneficiary-1', 'media-1', dto);
    await controller.removeMedia('beneficiary-1', 'media-1');
    expect(service.updateMedia).toHaveBeenCalledWith('beneficiary-1', 'media-1', dto);
    expect(service.removeMedia).toHaveBeenCalledWith('beneficiary-1', 'media-1');
  });
});
