import { createZip } from './certificate-photo-export.util';

describe('createZip', () => {
  it('creates a readable ZIP with UTF-8 filenames', async () => {
    const archive = createZip([
      { name: '001_Rahul_Jain.jpg', data: Buffer.from('photo-data') },
      { name: 'manifest.csv', data: Buffer.from('\ufeffSerial,Name\n1,Rahul Jain\n') },
    ]);

    expect(archive.subarray(0, 4).readUInt32LE(0)).toBe(0x04034b50);
    expect(archive.readUInt32LE(archive.length - 22)).toBe(0x06054b50);

    const { execFileSync } = await import('node:child_process');
    const { mkdtempSync, writeFileSync, readFileSync, rmSync } = await import('node:fs');
    const { tmpdir } = await import('node:os');
    const { join } = await import('node:path');
    const dir = mkdtempSync(join(tmpdir(), 'avijit-zip-'));
    const zipPath = join(dir, 'export.zip');
    writeFileSync(zipPath, archive);
    try {
      const listing = execFileSync('unzip', ['-Z1', zipPath], { encoding: 'utf8' });
      expect(listing).toContain('001_Rahul_Jain.jpg');
      expect(listing).toContain('manifest.csv');
      const output = execFileSync('unzip', ['-p', zipPath, 'manifest.csv'], { encoding: 'utf8' });
      expect(output).toContain('Rahul Jain');
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
