import { AdminOrganisationsController } from './admin-organisations.controller';

describe('AdminOrganisationsController media, create and deletion endpoints', () => {
  const service = {
    listMedia: jest.fn(),
    attachMedia: jest.fn(),
    updateMedia: jest.fn(),
    removeMedia: jest.fn(),
    findOneForAdmin: jest.fn(),
    create: jest.fn(),
    removeOrDeactivate: jest.fn(),
  };
  const controller = new AdminOrganisationsController(service as never);

  beforeEach(() => jest.clearAllMocks());

  it('delegates listing media', async () => {
    service.listMedia.mockResolvedValue([]);
    await controller.listMedia('org-1');
    expect(service.listMedia).toHaveBeenCalledWith('org-1');
  });

  it('delegates attaching media', async () => {
    const dto = { mediaId: 'media-1', purpose: 'GALLERY' as const };
    service.attachMedia.mockResolvedValue({ id: 'relation-1' });
    await expect(controller.attachMedia('org-1', dto)).resolves.toEqual({ id: 'relation-1' });
    expect(service.attachMedia).toHaveBeenCalledWith('org-1', dto);
  });

  it('delegates updating and removing media', async () => {
    const dto = { isPrimary: true };
    await controller.updateMedia('org-1', 'media-1', dto);
    await controller.removeMedia('org-1', 'media-1');
    expect(service.updateMedia).toHaveBeenCalledWith('org-1', 'media-1', dto);
    expect(service.removeMedia).toHaveBeenCalledWith('org-1', 'media-1');
  });

  it('delegates organisation creation to the service', async () => {
    const dto = {
      email: 'contact@example.org',
      translations: [{ languageCode: 'en', name: 'Help Organisation' }],
    };
    service.create.mockResolvedValue({ id: 'org-1', slug: 'help-organisation' });

    await expect(controller.create(dto)).resolves.toEqual({
      id: 'org-1',
      slug: 'help-organisation',
    });
    expect(service.create).toHaveBeenCalledWith(dto);
  });

  it('delegates removal to the organisation service', async () => {
    service.removeOrDeactivate.mockResolvedValue({
      id: 'org-1',
      deleted: false,
      deactivated: true,
    });

    await expect(
      controller.remove('org-1', { user: { uid: 'firebase-1' } } as never),
    ).resolves.toEqual({
      id: 'org-1',
      deleted: false,
      deactivated: true,
    });

    expect(service.removeOrDeactivate).toHaveBeenCalledWith(
      'org-1',
      'firebase-1',
    );
  });

});
