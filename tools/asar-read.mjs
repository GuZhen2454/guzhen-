#!/usr/bin/env node
// Minimal Electron ASAR reader: list entries or extract one file to stdout.
// Usage:
//   node asar-read.mjs <archive.asar> ls [prefix]
//   node asar-read.mjs <archive.asar> cat <entryPath>
import { readFileSync } from 'node:fs';

const [archive, action, arg] = process.argv.slice(2);
if (!archive || !action) {
  console.error('usage: asar-read.mjs <archive> ls [prefix] | cat <entryPath>');
  process.exit(2);
}

const buf = readFileSync(archive);
// Pickled header: [u32 = 4][u32 headerSize][u32 version?] then JSON String payload.
const headerSize = buf.readUInt32LE(4);
const headerJsonSize = buf.readUInt32LE(12);
const header = JSON.parse(buf.subarray(16, 16 + headerJsonSize).toString('utf8'));
const dataOffset = 8 + headerSize;

function walk(node, prefix, out) {
  for (const [name, value] of Object.entries(node.files ?? {})) {
    const path = prefix ? `${prefix}/${name}` : name;
    if (value.files) walk(value, path, out);
    else out.push({ path, size: value.size ?? 0, offset: value.offset, unpacked: !!value.unpacked });
  }
  return out;
}

const entries = walk(header, '', []);

if (action === 'ls') {
  const needle = arg ?? '';
  for (const e of entries.filter(e => e.path.includes(needle))) {
    console.log(`${String(e.size).padStart(9)}  ${e.path}${e.unpacked ? '  [unpacked]' : ''}`);
  }
} else if (action === 'cat') {
  const hit = entries.find(e => e.path === arg);
  if (!hit) { console.error(`not found: ${arg}`); process.exit(1); }
  const start = dataOffset + Number(hit.offset);
  process.stdout.write(buf.subarray(start, start + hit.size).toString('utf8'));
} else {
  console.error(`unknown action: ${action}`);
  process.exit(2);
}
