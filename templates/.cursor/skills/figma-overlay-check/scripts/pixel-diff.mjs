#!/usr/bin/env node
// Usage: node pixel-diff.mjs <design.png> <page.png> [diff.png] [--threshold=0.1]
// Compares two PNGs (auto-cropped to common area) and reports mismatch percentage.
// Deps: npm i pixelmatch pngjs (in the directory you run this from)

import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

// Resolve deps from the caller's cwd so users can `npm i pixelmatch pngjs` anywhere.
const require = createRequire(path.join(process.cwd(), 'noop.js'));
let pixelmatch, PNG;
try {
  pixelmatch = require('pixelmatch');
  pixelmatch = pixelmatch.default ?? pixelmatch;
  ({ PNG } = require('pngjs'));
} catch {
  console.error('Missing dependencies. Install them in the current directory first: npm i pixelmatch pngjs');
  process.exit(1);
}

const args = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const thresholdArg = process.argv.find((a) => a.startsWith('--threshold='));
const threshold = thresholdArg ? parseFloat(thresholdArg.split('=')[1]) : 0.1;

const [designPath, pagePath, diffPath = 'diff.png'] = args;
if (!designPath || !pagePath) {
  console.error('Usage: node pixel-diff.mjs <design.png> <page.png> [diff.png] [--threshold=0.1]');
  process.exit(1);
}

const a = PNG.sync.read(fs.readFileSync(designPath));
const b = PNG.sync.read(fs.readFileSync(pagePath));

const width = Math.min(a.width, b.width);
const height = Math.min(a.height, b.height);

function crop(src) {
  if (src.width === width && src.height === height) return src;
  const out = new PNG({ width, height });
  PNG.bitblt(src, out, 0, 0, width, height, 0, 0);
  return out;
}

const imgA = crop(a);
const imgB = crop(b);
const diff = new PNG({ width, height });

const mismatched = pixelmatch(imgA.data, imgB.data, diff.data, width, height, {
  threshold,
  includeAA: false,
});

fs.writeFileSync(diffPath, PNG.sync.write(diff));

const total = width * height;
const pct = ((mismatched / total) * 100).toFixed(2);
if (a.width !== b.width || a.height !== b.height) {
  console.log(`Note: image sizes differ (${a.width}x${a.height} vs ${b.width}x${b.height}); compared the common ${width}x${height} area`);
}
console.log(`mismatch: ${pct}% (${mismatched} / ${total} px)`);
console.log(`diff highlight image written to: ${diffPath}`);
process.exit(mismatched / total > 0.02 ? 2 : 0);
