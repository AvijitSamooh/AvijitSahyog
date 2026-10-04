import { BadRequestException, InternalServerErrorException } from '@nestjs/common';
import sharp from 'sharp';
import { MediaService } from './media.service';

describe('MediaService', () => {
  let service: MediaService;
  let r2: { upload: jest.Mock; delete: jest.Mock; download: jest.Mock };
  let firestore: { upsert: jest.Mock; getById: jest.Mock; delete: jest.Mock };
  let firebase: { db: { collection: jest.Mock } };

  beforeEach(() => {
    r2 = { upload: jest.fn(), delete: jest.fn(), download: jest.fn().mockResolvedValue(Buffer.from('x')) };
    firestore = { upsert: jest.fn(), getById: jest.fn(), delete: jest.fn() };
    const query = {
      count: jest.fn(() => ({ get: jest.fn().mockResolvedValue({ data: () => ({ count: 0 }) }) })),
    };
    firebase = { db: { collection: jest.fn(() => ({ where: jest.fn(() => query), get: jest.fn() })) } };
    service = new MediaService(r2 as never, firestore as never, firebase as never);
  });

  const createFile = (overrides: Partial<Express.Multer.File> = {}): Express.Multer.File =>
    ({
      buffer: Buffer.from('not-used-for-validation'),
      mimetype: 'image/jpeg',
      size: 1024,
      ...overrides,
    }) as Express.Multer.File;

  async function validImage(format: 'jpeg' | 'png' = 'jpeg') {
    const image = sharp({
      create: {
        width: 100,
        height: 100,
        channels: 3,
        background: { r: 255, g: 255, b: 255 },
      },
    });
    return format === 'png' ? image.png().toBuffer() : image.jpeg().toBuffer();
  }

  it('rejects a missing file', async () => {
    await expect(service.uploadImage(undefined as never)).rejects.toBeInstanceOf(BadRequestException);
    expect(r2.upload).not.toHaveBeenCalled();
  });

  it('rejects invalid image bytes regardless of multipart MIME type', async () => {
    await expect(service.uploadImage(createFile({ mimetype: 'application/pdf' }))).rejects.toBeInstanceOf(BadRequestException);
    expect(r2.upload).not.toHaveBeenCalled();
  });

  it('accepts valid image bytes when multipart MIME type is generic', async () => {
    const input = await validImage();
    const persisted = { id: 'media-1', storageKey: 'uploads/media-1.webp' };
    firestore.upsert.mockImplementation(async (value: any) => ({ ...value, ...persisted }));

    await expect(service.uploadImage(createFile({ buffer: input, mimetype: 'application/octet-stream', size: input.length }))).resolves.toMatchObject(persisted);
    expect(r2.upload).toHaveBeenCalledWith(expect.stringMatching(/^uploads\/.+\.webp$/), expect.any(Buffer), 'image/webp');
    expect(firestore.upsert).toHaveBeenCalled();
  });

  it('rejects files larger than 10 MB', async () => {
    await expect(service.uploadImage(createFile({ size: 10 * 1024 * 1024 + 1 }))).rejects.toBeInstanceOf(BadRequestException);
    expect(r2.upload).not.toHaveBeenCalled();
  });

  it('processes a valid image, uploads WebP, and persists optimized metadata', async () => {
    const input = await sharp({
      create: { width: 2400, height: 1200, channels: 3, background: { r: 255, g: 255, b: 255 } },
    }).jpeg().toBuffer();
    firestore.upsert.mockImplementation(async (value: any) => value);

    const result = await service.uploadImage(createFile({ buffer: input, size: input.length }));
    expect(result).toMatchObject({ mimeType: 'image/webp', width: 1600, height: 800 });
    const uploaded = r2.upload.mock.calls[0][1] as Buffer;
    const metadata = await sharp(uploaded).metadata();
    expect(metadata.format).toBe('webp');
    expect(metadata.width).toBe(1600);
    expect(metadata.height).toBe(800);
    expect(firestore.upsert).toHaveBeenCalledWith(expect.objectContaining({
      storageKey: expect.stringMatching(/^uploads\/.+\.webp$/),
      mimeType: 'image/webp',
      width: 1600,
      height: 800,
      fileSize: uploaded.length,
    }));
  });

  it('uses the requested storage folder', async () => {
    const input = await validImage('png');
    firestore.upsert.mockImplementation(async (value: any) => value);
    await service.uploadImage(createFile({ buffer: input, mimetype: 'image/png', size: input.length }), 'organisations');
    expect(r2.upload).toHaveBeenCalledWith(expect.stringMatching(/^organisations\/.+\.webp$/), expect.any(Buffer), 'image/webp');
  });

  it('deletes the R2 object when Firestore persistence fails', async () => {
    const input = await validImage();
    firestore.upsert.mockRejectedValue(new Error('Firestore unavailable'));
    await expect(service.uploadImage(createFile({ buffer: input, size: input.length }))).rejects.toBeInstanceOf(InternalServerErrorException);
    expect(r2.delete).toHaveBeenCalledWith(expect.stringMatching(/^uploads\/.+\.webp$/));
  });

  it('returns an internal error when R2 upload fails', async () => {
    const input = await validImage();
    r2.upload.mockRejectedValue(new Error('R2 unavailable'));
    await expect(service.uploadImage(createFile({ buffer: input, size: input.length }))).rejects.toBeInstanceOf(InternalServerErrorException);
    expect(firestore.upsert).not.toHaveBeenCalled();
  });
  it('covers download and deletion ownership/reference guards', async () => {
    const media:any={id:'m1',uploadedById:'u1',storageKey:'uploads/m1.webp'};
    firestore.getById.mockResolvedValue(media);
    await expect(service.downloadImage('uploads/m1.webp')).resolves.toBeUndefined();
    await expect(service.deleteUserImage('m1','u2')).rejects.toThrow();
    await expect(service.deleteUserImage('m1','u1')).resolves.toEqual({id:'m1',deleted:true});
    expect(r2.delete).toHaveBeenCalledWith('uploads/m1.webp'); expect(firestore.delete).toHaveBeenCalledWith('m1');
    const query = { count: jest.fn(() => ({ get: jest.fn().mockResolvedValue({data:()=>({count:2})}) })) };
    firebase.db.collection.mockReturnValue({where:jest.fn(()=>query)});
    firestore.getById.mockResolvedValue(media);
    await expect(service.deleteUserImage('m1','u1')).rejects.toThrow(BadRequestException);
  });
});
