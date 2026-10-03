import { UnauthorizedException } from '@nestjs/common';
import {
  AdminHelpApplicationsController,
  CertificatePhotoExportController,
} from './help-applications.controller';

describe('Certificate photo export controllers', () => {
  const service = {
    certificatePhotoExportSummary: jest.fn(),
    buildCertificatePhotoExport: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.EXPORT_TOKEN_SECRET = 'test-export-secret';
  });

  afterAll(() => {
    delete process.env.EXPORT_TOKEN_SECRET;
  });

  it('creates an expiring download URL from the requested selection', async () => {
    service.certificatePhotoExportSummary.mockResolvedValue({
      total: 2,
      available: 2,
      missing: [],
      type: 'PRATIBHA_SAMMAN',
      status: 'CONSIDERED_FOR_SAMMAN',
    });

    const controller = new AdminHelpApplicationsController(service as any);
    const result = await controller.certificatePhotoExport();

    expect(result.downloadPath).toMatch(/^\/exports\/certificate-photos\?token=.+\..+$/);
    expect(result.expiresAt).toBeDefined();
    expect(result.filename).toContain('AvijitSahyog_Certificate_Photos_');
  });

  it('accepts the generated token and streams the export', async () => {
    service.certificatePhotoExportSummary.mockResolvedValue({
      total: 1,
      available: 1,
      missing: [],
      type: 'PRATIBHA_SAMMAN',
      status: 'CONSIDERED_FOR_SAMMAN',
    });
    service.buildCertificatePhotoExport.mockResolvedValue(Buffer.from('zip-data'));

    const adminController = new AdminHelpApplicationsController(service as any);
    const created = await adminController.certificatePhotoExport();
    const token = created.downloadPath.split('token=')[1];

    const publicController = new CertificatePhotoExportController(service as any);
    const file = await publicController.download(token);

    expect(file).toBeDefined();
    expect(service.buildCertificatePhotoExport).toHaveBeenCalledWith(
      'PRATIBHA_SAMMAN',
      'CONSIDERED_FOR_SAMMAN',
    );
  });

  it('rejects a tampered export token', async () => {
    const publicController = new CertificatePhotoExportController(service as any);

    await expect(publicController.download('tampered.token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(service.buildCertificatePhotoExport).not.toHaveBeenCalled();
  });
});
