import { inflateRawSync } from 'node:zlib';
import { createZip } from './certificate-photo-export.util';

describe('createZip', () => {
  it('creates a valid archive with UTF-8 filenames and readable content', () => {
    const archive = createZip([
      { name: '001_Rahul_Jain.jpg', data: Buffer.from('photo-data') },
      { name: 'manifest.csv', data: Buffer.from('\ufeffSerial,Name\n1,Rahul Jain\n') },
    ]);

    expect(archive.readUInt32LE(0)).toBe(0x04034b50);
    expect(archive.readUInt32LE(archive.length - 22)).toBe(0x06054b50);

    const nameLength = archive.readUInt16LE(26);
    const extraLength = archive.readUInt16LE(28);
    const compressedSize = archive.readUInt32LE(18);
    const name = archive.subarray(30, 30 + nameLength).toString('utf8');
    const compressed = archive.subarray(30 + nameLength + extraLength, 30 + nameLength + extraLength + compressedSize);

    expect(name).toBe('001_Rahul_Jain.jpg');
    expect(inflateRawSync(compressed).toString('utf8')).toBe('photo-data');
    expect(archive.includes(Buffer.from('manifest.csv'))).toBe(true);
  });
});
