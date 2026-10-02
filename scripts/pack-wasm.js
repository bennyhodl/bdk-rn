#!/usr/bin/env node

/**
 * Pack the web build alone as @bennyblader/bdk-wasm.
 *
 * bdk-rn's own package is React Native only. This fork also builds bdk-ffi for
 * wasm32 (`just build-wasm`, then `pnpm prepare` compiles src/web into lib/).
 * This stages lib/module/web and its types as a package of their own in
 * dist-wasm/ and packs it beside package.json. Temporary: it goes away when
 * bdk-rn ships a web build.
 */

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const pkg = require('../package.json');
const out = path.join(root, 'dist-wasm');

// The module and its declarations share one tree: index.js beside
// index.d.ts, generated/bdk.js beside generated/bdk.d.ts.
const sources = ['lib/module/web', 'lib/typescript/src/web'];
const wasm = 'generated/bdkffi.wasm';
if (!fs.existsSync(path.join(root, sources[0], wasm))) {
  throw new Error(`${sources[0]}/${wasm} is missing: run \`just build-wasm\``);
}

fs.rmSync(out, { recursive: true, force: true });
for (const source of sources) {
  fs.cpSync(path.join(root, source), out, {
    recursive: true,
    // Source maps point back into src/, which the package does not carry.
    filter: (file) => !file.endsWith('.map'),
  });
}

// The generated bindings import these at runtime.
const dependencies = Object.fromEntries(
  ['@ubjs/core', '@ubjs/wasm'].map((name) => [
    name,
    pkg.dependencies[name] ?? pkg.devDependencies[name],
  ])
);

const manifest = {
  name: '@bennyblader/bdk-wasm',
  version: pkg.version,
  description: 'bdk-rn built for the browser and Node (wasm)',
  license: pkg.license,
  author: pkg.author,
  repository: { type: 'git', url: 'https://github.com/bennyhodl/bdk-rn' },
  type: 'module',
  main: './index.js',
  types: './index.d.ts',
  exports: {
    '.': { types: './index.d.ts', default: './index.js' },
    './bdkffi.wasm': `./${wasm}`,
    './package.json': './package.json',
  },
  dependencies,
  publishConfig: { access: 'public' },
};
fs.writeFileSync(
  path.join(out, 'package.json'),
  JSON.stringify(manifest, null, 2) + '\n'
);
for (const license of [
  'LICENSE.txt',
  'LICENSE-APACHE.txt',
  'LICENSE-MIT.txt',
]) {
  fs.copyFileSync(path.join(root, license), path.join(out, license));
}

execFileSync('npm', ['pack', out], { cwd: root, stdio: 'inherit' });
