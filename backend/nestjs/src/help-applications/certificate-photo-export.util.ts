import { deflateRawSync } from 'node:zlib';

type ZipEntry = { name: string; data: Buffer };

const CRC_TABLE = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = (c & 1) ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c >>> 0;
  }
  return table;
})();

function crc32(data: Buffer): number {
  let crc = 0xffffffff;
  for (const byte of data) crc = CRC_TABLE[(crc ^ byte) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

function dosDateTime(date = new Date()): { date: number; time: number } {
  const year = Math.max(1980, date.getFullYear());
  return {
    date: ((year - 1980) << 9) | ((date.getMonth() + 1) << 5) | date.getDate(),
    time: (date.getHours() << 11) | (date.getMinutes() << 5) | Math.floor(date.getSeconds() / 2),
  };
}

function u16(value: number) { const b = Buffer.alloc(2); b.writeUInt16LE(value & 0xffff); return b; }
function u32(value: number) { const b = Buffer.alloc(4); b.writeUInt32LE(value >>> 0); return b; }

export function createZip(entries: ZipEntry[]): Buffer {
  const local: Buffer[] = [];
  const central: Buffer[] = [];
  let offset = 0;
  const { date, time } = dosDateTime();

  for (const entry of entries) {
    const name = Buffer.from(entry.name, 'utf8');
    const compressed = deflateRawSync(entry.data, { level: 6 });
    const crc = crc32(entry.data);
    const header = Buffer.concat([
      u32(0x04034b50), u16(20), u16(0x0800), u16(8), u16(time), u16(date),
      u32(crc), u32(compressed.length), u32(entry.data.length), u16(name.length), u16(0), name,
    ]);
    local.push(header, compressed);

    central.push(Buffer.concat([
      u32(0x02014b50), u16(20), u16(20), u16(0x0800), u16(8), u16(time), u16(date),
      u32(crc), u32(compressed.length), u32(entry.data.length), u16(name.length), u16(0),
      u16(0), u16(0), u16(0), u32(0), u32(offset), name,
    ]));
    offset += header.length + compressed.length;
  }

  const centralDirectory = Buffer.concat(central);
  const end = Buffer.concat([
    u32(0x06054b50), u16(0), u16(0), u16(entries.length), u16(entries.length),
    u32(centralDirectory.length), u32(offset), u16(0),
  ]);
  return Buffer.concat([...local, centralDirectory, end]);
}
