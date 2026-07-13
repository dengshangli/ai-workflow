#!/usr/bin/env node
// Usage: node crop.mjs <src.png> <x> <y> <w> <h> <out.png>
// Crops a region from a PNG. Deps: pngjs (npm i pngjs in cwd).

import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(path.join(process.cwd(), 'noop.js'));
let PNG;
try {
  ({ PNG } = require('pngjs'));
} catch {
  console.error('Missing dependency. Install it in the current directory first: npm i pngjs');
  process.exit(1);
}

const [srcPath, xs, ys, ws, hs, out] = process.argv.slice(2);
if (!srcPath || !out) {
  console.error('Usage: node crop.mjs <src.png> <x> <y> <w> <h> <out.png>');
  process.exit(1);
}
const [x, y, w, h] = [xs, ys, ws, hs].map(Number);

const src = PNG.sync.read(fs.readFileSync(srcPath));
const cw = Math.min(w, src.width - x);
const ch = Math.min(h, src.height - y);
const dst = new PNG({ width: cw, height: ch });
PNG.bitblt(src, dst, x, y, cw, ch, 0, 0);
fs.writeFileSync(out, PNG.sync.write(dst));
console.log(`${out}: ${cw}x${ch}`);
